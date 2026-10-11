// Payment used to charge the card and unlock nothing: no handler ever wrote `pro:<userId>`.
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { onRequestPost } from '../../functions/api/stripe-webhook.js';
import { onRequest } from '../../functions/api/stripe.js';

// `webhooks` is an instance property, not on the prototype, so the whole module is stubbed.
const constructEventAsync = vi.fn();
vi.mock('stripe', () => {
  class Stripe {
    constructor() { this.webhooks = { constructEventAsync }; }
    static createFetchHttpClient() { return {}; }
    static createSubtleCryptoProvider() { return {}; }
  }
  return { default: Stripe };
});

const kv = { put: vi.fn(async () => {}), get: vi.fn(async () => null) };
const env = {
  DOSE_KV: kv,
  STRIPE_SECRET_KEY: 'sk_test', STRIPE_WEBHOOK_SECRET: 'whsec', STRIPE_PRICE_ID: 'price_real',
};
const post = (body = '{}') =>
  new Request('https://healstack.heyitsmejosh.com/api/stripe-webhook', {
    method: 'POST', headers: { 'stripe-signature': 'sig' }, body,
  });

beforeEach(() => { kv.put.mockClear(); constructEventAsync.mockReset(); });

describe('stripe webhook', () => {
  it('unlocks pro for the user named in client_reference_id', async () => {
    constructEventAsync.mockResolvedValue({
      type: 'checkout.session.completed',
      data: { object: { id: 'cs_1', client_reference_id: 'user-42' } },
    });
    const res = await onRequestPost({ request: post(), env });
    expect(res.status).toBe(200);
    expect(kv.put).toHaveBeenCalledWith('pro:user-42', '1');
  });

  it('never unlocks anything on a forged signature', async () => {
    constructEventAsync.mockRejectedValue(new Error('no match'));
    const res = await onRequestPost({ request: post(), env });
    expect(res.status).toBe(400);
    expect(kv.put).not.toHaveBeenCalled();
  });

  it('refuses to run at all when Stripe is unconfigured', async () => {
    const res = await onRequestPost({ request: post(), env: { DOSE_KV: kv } });
    expect(res.status).toBe(503);
    expect(kv.put).not.toHaveBeenCalled();
  });
});

describe('checkout config guard', () => {
  it('says payments are unconfigured instead of dying inside the SDK', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => Response.json({ id: 'user-42' })));
    const request = new Request('https://healstack.heyitsmejosh.com/api/stripe?action=checkout', {
      method: 'POST', headers: { authorization: 'Bearer good' },
    });
    const res = await onRequest({ request, env: { ...env, STRIPE_SECRET_KEY: undefined } });
    expect(res.status).toBe(503);
  });
});
