import Stripe from 'stripe';

// Nothing else in this app ever writes `pro:<userId>`, so without this handler a completed
// payment charged the card and unlocked nothing. Checkout carries the user id in
// client_reference_id (see functions/api/stripe.js); that is what we flip here.
export async function onRequestPost(context) {
  const { request, env } = context;

  if (!env.STRIPE_SECRET_KEY || !env.STRIPE_WEBHOOK_SECRET) {
    console.error('[STRIPE/webhook] not configured');
    return new Response('not configured', { status: 503 });
  }

  const stripe = new Stripe(env.STRIPE_SECRET_KEY, { httpClient: Stripe.createFetchHttpClient() });
  const signature = request.headers.get('stripe-signature');
  const body = await request.text();

  let event;
  try {
    // Workers has no synchronous crypto, so the async variant + SubtleCrypto provider is
    // mandatory here; constructEvent() throws at runtime.
    event = await stripe.webhooks.constructEventAsync(
      body, signature, env.STRIPE_WEBHOOK_SECRET, undefined, Stripe.createSubtleCryptoProvider(),
    );
  } catch (err) {
    console.error('[STRIPE/webhook] bad signature:', err.message);
    return new Response('bad signature', { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const userId = event.data.object.client_reference_id;
    if (!userId) {
      console.error('[STRIPE/webhook] session with no client_reference_id:', event.data.object.id);
      return new Response('ok', { status: 200 });
    }
    await env.DOSE_KV.put(`pro:${userId}`, '1');
    console.log('[STRIPE/webhook] pro unlocked:', userId);
  }

  return new Response('ok', { status: 200 });
}
