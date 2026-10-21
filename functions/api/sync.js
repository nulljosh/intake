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

// Who is calling: a signed-in user of either sign-in service, linked by confirmed email so the web app (jaybulb-api)
// and the native apps (Supabase) read and write the same log. The old shared DOSE_SYNC_TOKEN still works for data
// already stored under it. An unconfirmed email never matches, so nobody can claim someone else's address.
const JAYBULB_API = 'https://api.jaybulb.com';
const SUPABASE_URL = 'https://tjsxsqlxjmanwvmywwvw.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqc3hzcWx4am1hbnd2bXl3d3Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0OTc0MDEsImV4cCI6MjA4NjA3MzQwMX0.LphLfho3wdQC20MhtcnBpzQUNuBoTOobrugQbNGxc68'; // public anon key, same as the iOS app ships

async function confirmedEmail(url, headers) {
  try {
    const r = await fetch(url, { headers });
    if (!r.ok) return null;
    const u = await r.json();
    return u?.email && u.email_confirmed_at ? u.email.trim().toLowerCase() : null;
  } catch {
    return null;
  }
}

export async function authenticate(request, env, verify = confirmedEmail) {
  const auth = request.headers.get('authorization') || '';
  if (!auth.startsWith('Bearer ')) return { ok: false, key: null };
  const provided = auth.slice(7);
  if (env.DOSE_SYNC_TOKEN && timingSafeEqual(provided, env.DOSE_SYNC_TOKEN)) {
    return { ok: true, key: `dose:${(await sha256Hex(env.DOSE_SYNC_TOKEN)).slice(0, 16)}` };
  }
  const email = (await verify(`${JAYBULB_API}/auth/user`, { Authorization: auth }))
    || (await verify(`${SUPABASE_URL}/auth/v1/user`, { Authorization: auth, apikey: SUPABASE_ANON_KEY }));
  if (!email) return { ok: false, key: null };
  return { ok: true, key: `user:${(await sha256Hex(email)).slice(0, 32)}` };
}

// Two devices push their own copy; keep every entry either one has (by id), newest copy wins for the rest.
export function merge(stored, body) {
  const union = (a = [], b = []) => {
    const out = new Map();
    for (const e of [...a, ...b]) out.set(e?.id ?? JSON.stringify(e), e);
    return [...out.values()];
  };
  return {
    log: union(stored.log, body.log),
    substances: union(stored.substances, body.substances),
    biometrics: union(stored.biometrics, body.biometrics),
    profile: { ...(stored.profile || {}), ...(body.profile || {}) },
    medications: body.medications !== undefined ? body.medications : stored.medications || [],
  };
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

function checkRateLimit(key) { // per account
  const now = Date.now();
  const entry = rateLimitStore.get(key);
  if (!entry || now - entry.start > RATE_WINDOW_MS) {
    rateLimitStore.set(key, { start: now, count: 1 });
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

  const { ok, key: DATA_KEY } = await authenticate(request, env);
  if (!ok) return json(401, { error: 'unauthorized' });

  if (!checkRateLimit(DATA_KEY)) {
    return json(429, { error: 'rate limit exceeded' });
  }

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

    const raw = await env.DOSE_KV.get(DATA_KEY);
    const payload = { ...merge(raw ? JSON.parse(raw) : {}, body), updatedAt: new Date().toISOString() };

    await env.DOSE_KV.put(DATA_KEY, JSON.stringify(payload));
    return json(200, { ok: true, updatedAt: payload.updatedAt });
  }

  return json(405, { error: 'method not allowed' });
}
