import 'server-only';
import { cookies } from 'next/headers';
import { adminAuth, isAdmin } from './firebase-admin';
export async function getAdmin() {
  const token = (await cookies()).get('uplord_admin_session')?.value;
  if (!token) return null;
  try {
    const user = await adminAuth.verifySessionCookie(token, true);
    return isAdmin(user.uid) ? user : null;
  } catch { return null; }
}
