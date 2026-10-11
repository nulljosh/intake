const ALLOWED_ORIGIN = 'https://intake.jaybulb.com';

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return result === 0;
}

async function sha256Hex(str) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(str));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function authenticate(request, env) {
  const token = env.DOSE_SYNC_TOKEN;
  if (!token) return { ok: false, tokenHash: null };
  const auth = request.headers.get('authorization') || '';
  if (!auth.startsWith('Bearer ')) return { ok: false, tokenHash: null };
  const provided = auth.slice(7);
  if (!timingSafeEqual(provided, token)) return { ok: false, tokenHash: null };
  const tokenHash = (await sha256Hex(token)).slice(0, 16);
  return { ok: true, tokenHash };
}

function validateBody(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return false;
  if (body.log !== undefined && !Array.isArray(body.log)) return false;
  if (body.substances !== undefined && !Array.isArray(body.substances)) return false;
  if (body.biometrics !== undefined && !Array.isArray(body.biometrics)) return false;
  if (body.medications !== undefined && !Array.isArray(body.medications)) return false;
  if (body.profile !== undefined && (typeof body.profile !== 'object' || Array.isArray(body.profile))) return false;
  return true;
}

const RATE_WINDOW_MS = 60_000;
const RATE_LIMIT = 10;
// ponytail: in-memory rate limit resets per-isolate (Workers don't share the Vercel single-process
// guarantee); fine for its purpose (abuse throttling, not exact quota), upgrade to KV-backed counter
// if that ever matters.
const rateLimitStore = new Map();

function checkRateLimit(tokenHash) {
  const now = Date.now();
  const entry = rateLimitStore.get(tokenHash);
  if (!entry || now - entry.start > RATE_WINDOW_MS) {
    rateLimitStore.set(tokenHash, { start: now, count: 1 });
    return true;
  }
  if (entry.count >= RATE_LIMIT) return false;
  entry.count++;
  return true;
}

function json(status, body, extraHeaders) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json',
      'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
      'Access-Control-Allow-Methods': 'GET, PUT, OPTIONS',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      Vary: 'Origin',
      ...extraHeaders,
    },
  });
}

export async function onRequest(context) {
  const { request, env } = context;

  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
        'Access-Control-Allow-Methods': 'GET, PUT, OPTIONS',
        'Access-Control-Allow-Headers': 'Authorization, Content-Type',
        Vary: 'Origin',
      },
    });
  }

  const { ok, tokenHash } = await authenticate(request, env);
  if (!ok) return json(401, { error: 'unauthorized' });

  if (!checkRateLimit(tokenHash)) {
    return json(429, { error: 'rate limit exceeded' });
  }

  const DATA_KEY = `dose:${tokenHash}`;

  if (request.method === 'GET') {
    const raw = await env.DOSE_KV.get(DATA_KEY);
    const data = raw ? JSON.parse(raw) : { log: [], substances: [], biometrics: [], profile: {}, medications: [] };
    return json(200, data);
  }

  if (request.method === 'PUT') {
    let body;
    try {
      body = await request.json();
    } catch {
      return json(400, { error: 'invalid body' });
    }
    if (!validateBody(body)) return json(400, { error: 'invalid body' });

    const serialized = JSON.stringify(body);
    if (serialized.length > 1_000_000) return json(413, { error: 'payload too large' });

    const payload = {
      log: body.log || [],
      substances: body.substances || [],
      biometrics: body.biometrics || [],
      profile: body.profile || {},
      medications: body.medications || [],
      updatedAt: new Date().toISOString(),
    };

    await env.DOSE_KV.put(DATA_KEY, JSON.stringify(payload));
    return json(200, { ok: true, updatedAt: payload.updatedAt });
  }

  return json(405, { error: 'method not allowed' });
}
