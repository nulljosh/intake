// The status and checkout actions used to trust a userId from the caller: anyone could
// read another account's pro flag and open a Stripe session against it.
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { onRequest } from '../../functions/api/stripe.js';

const env = { DOSE_KV: { get: vi.fn(async () => '1') }, STRIPE_PRICE_ID: 'p' };

const req = (method, action, headers = {}) =>
  new Request(`https://machaon.jaybulb.com/api/stripe?action=${action}`, { method, headers });

beforeEach(() => { vi.restoreAllMocks(); env.DOSE_KV.get.mockClear(); });

describe('stripe endpoint identity', () => {
  it('rejects status with no bearer token', async () => {
    const res = await onRequest({ request: req('GET', 'status'), env });
    expect(res.status).toBe(401);
    expect(env.DOSE_KV.get).not.toHaveBeenCalled();
  });

  it('rejects status when the API does not recognise the token', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('nope', { status: 401 })));
    const res = await onRequest({ request: req('GET', 'status', { authorization: 'Bearer forged' }), env });
    expect(res.status).toBe(401);
  });

  it('reads the id from the token, never from the query', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => Response.json({ id: 'real-user' })));
    const request = new Request(
      'https://machaon.jaybulb.com/api/stripe?action=status&userId=victim',
      { headers: { authorization: 'Bearer good' } },
    );
    await onRequest({ request, env });
    expect(env.DOSE_KV.get).toHaveBeenCalledWith('pro:real-user');
  });

  it('rejects an unauthenticated checkout before touching Stripe', async () => {
    const res = await onRequest({ request: req('POST', 'checkout'), env });
    expect(res.status).toBe(401);
  });
});
