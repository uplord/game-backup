"use client";
import { useState } from 'react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../../lib/firebase-client';
export default function Login() {
  const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [error, setError] = useState(''); const [busy, setBusy] = useState(false);
  async function login(e: React.FormEvent) {
    e.preventDefault(); setBusy(true); setError('');
    try {
      const credential = await signInWithEmailAndPassword(auth, email, password);
      const res = await fetch('/api/session', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ idToken: await credential.user.getIdToken() }) });
      if (!res.ok) throw new Error((await res.json()).error ?? 'Login failed');
      window.location.assign('/');
    } catch (err) { setError(err instanceof Error ? err.message : 'Login failed'); } finally { setBusy(false); }
  }
  return <main className="login"><div className="panel loginpanel"><div className="eyebrow">UPLORD / CONTROL</div><h1>Admin sign in</h1><p>Use an approved Firebase Authentication account.</p><form onSubmit={login}><label>Email<input type="email" required value={email} onChange={e => setEmail(e.target.value)} /></label><label>Password<input type="password" required value={password} onChange={e => setPassword(e.target.value)} /></label>{error && <p role="alert" className="error">{error}</p>}<button disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button></form></div></main>;
}
