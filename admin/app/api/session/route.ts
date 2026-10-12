import { NextRequest, NextResponse } from 'next/server';
import { adminAuth, isAdmin } from '../../../lib/firebase-admin';
export async function POST(req: NextRequest) {
  try {
    const { idToken } = await req.json();
    if (typeof idToken !== 'string') return NextResponse.json({ error: 'Missing token' }, { status: 400 });
    const decoded = await adminAuth.verifyIdToken(idToken, true);
    if (!isAdmin(decoded.uid)) return NextResponse.json({ error: 'Not authorized' }, { status: 403 });
    if (Date.now() / 1000 - decoded.auth_time > 5 * 60) return NextResponse.json({ error: 'Please sign in again' }, { status: 401 });
    const cookie = await adminAuth.createSessionCookie(idToken, { expiresIn: 1000 * 60 * 60 * 8 });
    const res = NextResponse.json({ ok: true });
    res.cookies.set('uplord_admin_session', cookie, { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', path: '/', maxAge: 60 * 60 * 8 });
    return res;
  } catch { return NextResponse.json({ error: 'Authentication failed' }, { status: 401 }); }
}
export async function DELETE() {
  const res = NextResponse.json({ ok: true });
  res.cookies.set('uplord_admin_session', '', { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', path: '/', maxAge: 0 });
  return res;
}
