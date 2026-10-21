import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import Auth from '../pages/Auth';
import ResetPassword from '../pages/ResetPassword';

const mockSignIn = vi.fn();
const mockSignUp = vi.fn();
const mockResetPassword = vi.fn();
const mockUpdateUser = vi.fn();
const mockClearRecovery = vi.fn();

vi.mock('../lib/spark', () => ({
  spark: {
    auth: {
      signInWithPassword: (...a) => mockSignIn(...a),
      signUp: (...a) => mockSignUp(...a),
      resetPasswordForEmail: (...a) => mockResetPassword(...a),
      updateUser: (...a) => mockUpdateUser(...a),
    },
  },
}));

vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({ clearPasswordRecovery: mockClearRecovery }),
}));

beforeEach(() => {
  vi.clearAllMocks();
  mockSignIn.mockResolvedValue({ error: null });
  mockSignUp.mockResolvedValue({ error: null });
  mockResetPassword.mockResolvedValue({ error: null });
  mockUpdateUser.mockResolvedValue({ error: null });
});

describe('Auth page', () => {
  it('renders sign in form by default', () => {
    render(<Auth />);
    expect(screen.getByPlaceholderText('Email')).toBeTruthy();
    expect(screen.getByPlaceholderText('Password')).toBeTruthy();
    expect(screen.getAllByText('Sign in').length).toBeGreaterThan(0);
  });

  it('shows forgot password link on login tab', () => {
    render(<Auth />);
    expect(screen.getByText('Forgot password?')).toBeTruthy();
  });

  it('switches to reset form when forgot password clicked', () => {
    render(<Auth />);
    fireEvent.click(screen.getByText('Forgot password?'));
    expect(screen.queryByPlaceholderText('Password')).toBeNull();
    expect(screen.getByText('Send reset email')).toBeTruthy();
    expect(screen.getByText(/Back to sign in/)).toBeTruthy();
  });

  it('calls resetPasswordForEmail on submit in reset mode', async () => {
    render(<Auth />);
    fireEvent.click(screen.getByText('Forgot password?'));
    fireEvent.change(screen.getByPlaceholderText('Email'), { target: { value: 'test@test.com' } });
    fireEvent.submit(screen.getByText('Send reset email').closest('form'));
    await waitFor(() => expect(mockResetPassword).toHaveBeenCalledWith('test@test.com', expect.objectContaining({ redirectTo: expect.stringContaining('machaon.jaybulb.com') })));
  });

  it('shows confirmation message after successful reset request', async () => {
    render(<Auth />);
    fireEvent.click(screen.getByText('Forgot password?'));
    fireEvent.change(screen.getByPlaceholderText('Email'), { target: { value: 'test@test.com' } });
    fireEvent.submit(screen.getByText('Send reset email').closest('form'));
    await waitFor(() => expect(screen.getByText(/Check your email/)).toBeTruthy());
  });

  it('shows error from the server on reset failure', async () => {
    mockResetPassword.mockResolvedValue({ error: { message: 'Rate limit exceeded' } });
    render(<Auth />);
    fireEvent.click(screen.getByText('Forgot password?'));
    fireEvent.change(screen.getByPlaceholderText('Email'), { target: { value: 'test@test.com' } });
    fireEvent.submit(screen.getByText('Send reset email').closest('form'));
    await waitFor(() => expect(screen.getByText('Rate limit exceeded')).toBeTruthy());
  });
});

describe('ResetPassword page', () => {
  it('renders new password form', () => {
    render(<ResetPassword />);
    expect(screen.getByPlaceholderText('New password')).toBeTruthy();
    expect(screen.getByPlaceholderText('Confirm password')).toBeTruthy();
  });

  it('shows error when passwords do not match', async () => {
    render(<ResetPassword />);
    fireEvent.change(screen.getByPlaceholderText('New password'), { target: { value: 'abc123' } });
    fireEvent.change(screen.getByPlaceholderText('Confirm password'), { target: { value: 'xyz999' } });
    fireEvent.submit(screen.getByText('Update password').closest('form'));
    await waitFor(() => expect(screen.getByText('Passwords do not match')).toBeTruthy());
    expect(mockUpdateUser).not.toHaveBeenCalled();
  });

  it('calls updateUser with new password on matching submit', async () => {
    render(<ResetPassword />);
    fireEvent.change(screen.getByPlaceholderText('New password'), { target: { value: 'newpass1' } });
    fireEvent.change(screen.getByPlaceholderText('Confirm password'), { target: { value: 'newpass1' } });
    fireEvent.submit(screen.getByText('Update password').closest('form'));
    await waitFor(() => expect(mockUpdateUser).toHaveBeenCalledWith({ password: 'newpass1' }));
  });

  it('calls clearPasswordRecovery on success', async () => {
    render(<ResetPassword />);
    fireEvent.change(screen.getByPlaceholderText('New password'), { target: { value: 'newpass1' } });
    fireEvent.change(screen.getByPlaceholderText('Confirm password'), { target: { value: 'newpass1' } });
    fireEvent.submit(screen.getByText('Update password').closest('form'));
    await waitFor(() => expect(mockClearRecovery).toHaveBeenCalled());
  });

  it('shows error from the server on update failure', async () => {
    mockUpdateUser.mockResolvedValue({ error: { message: 'Password too weak' } });
    render(<ResetPassword />);
    fireEvent.change(screen.getByPlaceholderText('New password'), { target: { value: 'weak' } });
    fireEvent.change(screen.getByPlaceholderText('Confirm password'), { target: { value: 'weak' } });
    fireEvent.submit(screen.getByText('Update password').closest('form'));
    await waitFor(() => expect(screen.getByText('Password too weak')).toBeTruthy());
  });
});
