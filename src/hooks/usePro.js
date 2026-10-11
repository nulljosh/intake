import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { spark } from '../lib/spark';

// The server derives the user id from this token; it no longer trusts a userId we send.
async function authHeader() {
  const { data } = await spark.auth.getSession();
  const token = data?.session?.access_token;
  return token ? { Authorization: `Bearer ${token}` } : null;
}

export function usePro() {
  const { user } = useAuth();
  const [isPro, setIsPro] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!user) return;
    authHeader()
      .then(h => (h ? fetch('/api/stripe?action=status', { headers: h }) : null))
      .then(r => (r && r.ok ? r.json() : null))
      .then(d => setIsPro(Boolean(d?.isPro)))
      .catch(() => {});
  }, [user]);

  const unlock = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    try {
      const h = await authHeader();
      if (!h) return;
      const res = await fetch('/api/stripe?action=checkout', { method: 'POST', headers: h });
      if (!res.ok) return;
      const { url } = await res.json();
      if (url) window.location.href = url;
    } finally {
      setLoading(false);
    }
  }, [user]);

  return { isPro, loading, unlock };
}
