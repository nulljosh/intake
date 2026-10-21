import Stripe from 'stripe';

let stripe;
function getStripe(env) {
  if (!stripe) {
    stripe = new Stripe(env.STRIPE_SECRET_KEY, {
      httpClient: Stripe.createFetchHttpClient(),
    });
  }
  return stripe;
}

const ALLOWED_ORIGIN = 'https://machaon.jaybulb.com';

// Identity comes from the caller's spark-api access token, never from a body/query field.
// A client-supplied userId let anyone read another account's pro status and open a
// checkout session against it.
// ponytail: one /auth/user round-trip per call rather than local JWT verification --
// no crypto here, and spark-api is already a hard dependency of every request.
// Verify the signature locally only if this endpoint ever gets hot enough to care.
const API_URL = 'https://api.jaybulb.com';

async function callerId(request, env) {
  const auth = request.headers.get('authorization') || '';
  if (!auth.startsWith('Bearer ')) return null;
  let res;
  try {
    res = await fetch(`${API_URL}/auth/user`, {
      headers: { Authorization: auth },
      signal: AbortSignal.timeout(5000),
    });
  } catch {
    return null;
  }
  if (!res.ok) return null;
  const user = await res.json().catch(() => null);
  return user?.id || null;
}



function json(status, body, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json',
      'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
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
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    });
  }

  const url = new URL(request.url);
  const action = url.searchParams.get('action');

  if (request.method === 'GET' && action === 'status') {
    const userId = await callerId(request, env);
    if (!userId) return json(401, { error: 'unauthorized' });
    const isPro = await env.DOSE_KV.get(`pro:${userId}`);
    return json(200, { isPro: Boolean(isPro) });
  }

  if (request.method === 'POST' && action === 'checkout') {
    const userId = await callerId(request, env);
    if (!userId) return json(401, { error: 'unauthorized' });

    // Without these the Stripe call fails deep inside the SDK and the user sees a dead
    // button. Say so plainly instead -- this endpoint shipped for months with an unset key
    // and a placeholder price id in wrangler.toml.
    if (!env.STRIPE_SECRET_KEY || !env.STRIPE_PRICE_ID) {
      console.error('[STRIPE/checkout] not configured');
      return json(503, { error: 'Payments are not configured yet' });
    }

    try {
      const session = await getStripe(env).checkout.sessions.create({
        mode: 'payment',
        payment_method_types: ['card'],
        line_items: [{ price: env.STRIPE_PRICE_ID, quantity: 1 }],
        success_url: `${ALLOWED_ORIGIN}/journal?pro=1`,
        cancel_url: `${ALLOWED_ORIGIN}/journal`,
        client_reference_id: userId,
        customer_creation: 'always',
        allow_promotion_codes: true,
      });

      return json(200, { url: session.url });
    } catch (err) {
      console.error('[STRIPE/checkout] Error:', err.message);
      return json(500, { error: 'Checkout session creation failed' });
    }
  }

  return json(400, { error: 'Unknown action' });
}
