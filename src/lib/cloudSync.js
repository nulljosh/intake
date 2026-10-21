// Account sync: the web keeps its log in localStorage, the phone in UserDefaults. On sign-in (and whenever the tab
// is hidden) we pull the account's copy from /api/sync, keep every entry either side has, and push the union back,
// so the web shows what the phone logged and the other way round. The server merges too, by entry id.
import { spark } from './spark';

const KEYS = { log: 'dose:log', biometrics: 'dose:biometrics' };

const read = (key) => { try { return JSON.parse(localStorage.getItem(key) || '[]'); } catch { return []; } };

export function union(local = [], remote = []) {
  const out = new Map();
  for (const e of [...remote, ...local]) out.set(e?.id ?? JSON.stringify(e), e); // a local edit wins over the copy it replaced
  return [...out.values()];
}

// Returns true when something new arrived, so the caller can reload the views reading localStorage.
export async function syncNow() {
  const { data } = await spark.auth.getSession();
  const token = data?.session?.access_token;
  if (!token) return false;
  const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
  const res = await fetch('/api/sync', { headers });
  if (!res.ok) return false;
  const remote = await res.json();
  let changed = false, body = {};
  for (const [field, key] of Object.entries(KEYS)) {
    const local = read(key), merged = union(local, remote[field]);
    if (merged.length !== local.length) { localStorage.setItem(key, JSON.stringify(merged)); changed = true; }
    body[field] = merged;
  }
  await fetch('/api/sync', { method: 'PUT', headers, body: JSON.stringify(body) });
  return changed;
}
