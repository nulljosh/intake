import { describe, it, expect } from 'vitest';
import { authenticate, merge } from '../../functions/api/sync.js';

const req = (token) => new Request('https://intake.jaybulb.com/api/sync', { headers: token ? { authorization: `Bearer ${token}` } : {} });

describe('sync auth', () => {
  it('links both sign-in services by confirmed email, and refuses everything else', async () => {
    const verify = async (url, headers) => (headers.Authorization === 'Bearer web' && url.includes('jaybulb')) || (headers.Authorization === 'Bearer ios' && url.includes('supabase')) ? 'me@x.com' : null;
    const web = await authenticate(req('web'), {}, verify);
    const ios = await authenticate(req('ios'), {}, verify);
    expect(web.ok && ios.ok).toBe(true);
    expect(web.key).toBe(ios.key);
    expect((await authenticate(req('stranger'), {}, verify)).ok).toBe(false);
    expect((await authenticate(req(null), {}, verify)).ok).toBe(false);
    expect((await authenticate(req('legacy'), { DOSE_SYNC_TOKEN: 'legacy' }, verify)).key).toMatch(/^dose:/);
  });

  it('merges a push instead of overwriting the other device', () => {
    const m = merge({ log: [{ id: 'a' }], profile: { name: 'J' } }, { log: [{ id: 'b' }, { id: 'a', dose: 2 }], profile: { email: 'e' } });
    expect(m.log.map(e => e.id).sort()).toEqual(['a', 'b']);
    expect(m.log.find(e => e.id === 'a').dose).toBe(2);
    expect(m.profile).toEqual({ name: 'J', email: 'e' });
  });
});
