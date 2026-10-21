import { useState } from 'react';
import { spark } from '../lib/spark';
import './landing.css';
import './auth.css';

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

  const switchTo = (t) => { setTab(t); setError(''); setMessage(''); };

  // Dressed like the landing (landing.css, .hl scope): the halftone band beside the form, thin caps, square controls.
  return (
    <div className="hl auth">
      <div className="art auth-art" style={{ '--img': 'url(/art/ricci.png)' }} aria-hidden="true" />
      <div className="auth-panel">
        <a className="nav-brand" href="/"><img src="/icon.svg" alt="" width="28" height="28" /><span>Machaon</span></a>
        <p className="label">{tab === 'register' ? 'Start your log' : tab === 'reset' ? 'Reset your password' : 'Welcome back'}</p>
        <h1>{tab === 'register' ? 'Register' : tab === 'reset' ? 'Reset' : 'Sign in'}</h1>

        {tab !== 'reset' && (
          <div className="auth-tabs" role="tablist">
            {['login', 'register'].map(t => (
              <button key={t} role="tab" aria-selected={tab === t} onClick={() => switchTo(t)}>{t === 'login' ? 'Sign in' : 'Register'}</button>
            ))}
          </div>
        )}
        {tab === 'reset' && (
          <p className="auth-note">Enter your email and we'll send a reset link. <button type="button" className="auth-link" onClick={() => switchTo('login')}>Back to sign in</button></p>
        )}

        <form onSubmit={handleSubmit} className="auth-form">
          <input className="auth-input" type="email" placeholder="Email" aria-label="Email" value={email} onChange={e => setEmail(e.target.value)} required autoComplete="email" />
          {tab !== 'reset' && (
            <input className="auth-input" type="password" placeholder="Password" aria-label="Password" value={password} onChange={e => setPassword(e.target.value)} required minLength={8} autoComplete={tab === 'login' ? 'current-password' : 'new-password'} />
          )}
          {tab === 'login' && <button type="button" className="auth-link" onClick={() => switchTo('reset')}>Forgot password?</button>}
          {tab === 'register' && (
            <label className="auth-note auth-check">
              <input type="checkbox" checked={tosChecked} onChange={e => setTosChecked(e.target.checked)} />
              I agree to the <a href="/tos.html" target="_blank">Terms of Service</a>
            </label>
          )}
          {error && <p className="auth-error" role="alert">{error}</p>}
          {message && <p className="auth-ok" role="status">{message}</p>}
          <button type="submit" className="btn btn-solid auth-submit" disabled={loading}>
            {loading ? 'One moment' : tab === 'login' ? 'Sign in' : tab === 'register' ? 'Create account' : 'Send reset email'}
          </button>
        </form>
      </div>
    </div>
  );
}
