import 'server-only';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
const projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
const app = getApps()[0] ?? initializeApp({ credential: applicationDefault(), projectId });
export const adminAuth = getAuth(app);
export const db = getFirestore(app);
export function isAdmin(uid: string): boolean {
  return (process.env.ADMIN_UIDS ?? '').split(',').map(x => x.trim()).filter(Boolean).includes(uid);
}
