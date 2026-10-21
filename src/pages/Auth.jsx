import { useState } from 'react';
import { spark } from '../lib/spark';

export default function Auth() {
  const [tab, setTab] = useState('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [tosChecked, setTosChecked] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setMessage('');
    setLoading(true);

    if (tab === 'login') {
      const { error } = await spark.auth.signInWithPassword({ email, password });
      if (error) setError(error.message);
    } else if (tab === 'register') {
      if (!tosChecked) { setError('You must agree to the Terms of Service'); setLoading(false); return; }
      const { error } = await spark.auth.signUp({ email, password });
      if (error) setError(error.message);
    } else {
      const { error } = await spark.auth.resetPasswordForEmail(email, {
        redirectTo: 'https://machaon.jaybulb.com/',
      });
      if (error) setError(error.message);
      else setMessage('Check your email for a reset link');
    }

    setLoading(false);
  }

  return (
    <div style={{
      minHeight: '100dvh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '24px 16px',
      background: 'var(--bg-primary)',
    }}>
      <div style={{ width: '100%', maxWidth: 360 }}>
        <div style={{ marginBottom: 32, textAlign: 'center' }}>
          <div style={{
            width: 48, height: 48, borderRadius: 12, background: 'var(--bg-secondary)',
            border: '1px solid var(--border)', display: 'flex', alignItems: 'center',
            justifyContent: 'center', margin: '0 auto 16px',
          }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 2a4 4 0 1 0 0 8 4 4 0 0 0 0-8z"/>
              <path d="M20 21a8 8 0 1 0-16 0"/>
            </svg>
          </div>
          <h1 style={{ fontSize: '1.25rem', fontWeight: 600, margin: 0, color: 'var(--text-primary)' }}>Machaon</h1>
          <p style={{ fontSize: '0.83rem', color: 'var(--text-tertiary)', margin: '4px 0 0' }}>Health tracker</p>
        </div>

        {tab !== 'reset' && (
          <div style={{
            display: 'flex', gap: 4, background: 'var(--bg-secondary)',
            border: '1px solid var(--border)', borderRadius: 8, padding: 4, marginBottom: 20,
          }}>
            {['login', 'register'].map(t => (
              <button
                key={t}
                onClick={() => { setTab(t); setError(''); setMessage(''); }}
                style={{
                  flex: 1, padding: '7px 0', borderRadius: 6, border: 'none', cursor: 'pointer',
                  fontFamily: 'inherit', fontSize: '0.83rem', fontWeight: 500,
                  background: tab === t ? 'var(--bg-primary)' : 'transparent',
                  color: tab === t ? 'var(--text-primary)' : 'var(--text-tertiary)',
                  boxShadow: tab === t ? '0 1px 3px rgba(0,0,0,0.15)' : 'none',
                  transition: 'all 0.15s',
                }}
              >
                {t === 'login' ? 'Sign in' : 'Register'}
              </button>
            ))}
          </div>
        )}

        {tab === 'reset' && (
          <p style={{ fontSize: '0.83rem', color: 'var(--text-tertiary)', marginBottom: 20 }}>
            Enter your email and we'll send a reset link.{' '}
            <button
              type="button"
              onClick={() => { setTab('login'); setError(''); setMessage(''); }}
              style={{ background: 'none', border: 'none', color: 'var(--accent)', cursor: 'pointer', padding: 0, fontFamily: 'inherit', fontSize: 'inherit' }}
            >
              Back to sign in
            </button>
          </p>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <input
            className="input"
            type="email"
            placeholder="Email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            required
            autoComplete="email"
          />
          {tab !== 'reset' && (
            <input
              className="input"
              type="password"
              placeholder="Password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              minLength={8}
              autoComplete={tab === 'login' ? 'current-password' : 'new-password'}
            />
          )}

          {tab === 'login' && (
            <button
              type="button"
              onClick={() => { setTab('reset'); setError(''); setMessage(''); }}
              style={{ background: 'none', border: 'none', color: 'var(--text-tertiary)', cursor: 'pointer', padding: 0, fontFamily: 'inherit', fontSize: '0.78rem', textAlign: 'left' }}
            >
              Forgot password?
            </button>
          )}

          {tab === 'register' && (
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.78rem', color: 'var(--text-tertiary)', cursor: 'pointer' }}>
              <input type="checkbox" checked={tosChecked} onChange={e => setTosChecked(e.target.checked)} />
              I agree to the <a href="/tos.html" target="_blank" style={{ color: 'var(--text-secondary)' }}>Terms of Service</a>
            </label>
          )}
          {error && (
            <p style={{ fontSize: '0.78rem', color: 'var(--danger)', margin: 0 }}>{error}</p>
          )}
          {message && (
            <p style={{ fontSize: '0.78rem', color: 'var(--success)', margin: 0 }}>{message}</p>
          )}

          <button
            type="submit"
            className="btn-primary"
            disabled={loading}
            style={{ marginTop: 4 }}
          >
            {loading ? 'Loading...' : tab === 'login' ? 'Sign in' : tab === 'register' ? 'Create account' : 'Send reset email'}
          </button>
        </form>
      </div>
    </div>
  );
}
