import { useState } from 'react';
import { spark } from '../lib/spark';
import { useAuth } from '../context/AuthContext';

export default function ResetPassword() {
  const { clearPasswordRecovery } = useAuth();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    if (password !== confirm) { setError('Passwords do not match'); return; }
    setError('');
    setLoading(true);
    const { error } = await spark.auth.updateUser({ password });
    setLoading(false);
    if (error) { setError(error.message); return; }
    clearPasswordRecovery();
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
          <h1 style={{ fontSize: '1.25rem', fontWeight: 600, margin: 0, color: 'var(--text-primary)' }}>Set new password</h1>
          <p style={{ fontSize: '0.83rem', color: 'var(--text-tertiary)', margin: '4px 0 0' }}>Enter a new password for your account</p>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <input
            className="input"
            type="password"
            placeholder="New password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            minLength={8}
            autoComplete="new-password"
          />
          <input
            className="input"
            type="password"
            placeholder="Confirm password"
            value={confirm}
            onChange={e => setConfirm(e.target.value)}
            required
            minLength={8}
            autoComplete="new-password"
          />

          {error && (
            <p style={{ fontSize: '0.78rem', color: 'var(--danger)', margin: 0 }}>{error}</p>
          )}

          <button
            type="submit"
            className="btn-primary"
            disabled={loading}
            style={{ marginTop: 4 }}
          >
            {loading ? 'Saving...' : 'Update password'}
          </button>
        </form>
      </div>
    </div>
  );
}
