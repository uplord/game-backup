# Uplord Admin — Phase 5.3

A **separate Next.js CMS foundation** inside the existing Godot project. Phase 5.3 provides a Firebase Authentication login, a **server-verified UID allowlist**, secure HTTP-only session cookie, a read-only published-content dashboard, release list, and category counts. No editing or publishing is implemented yet (Phases 5.4–5.5).

## Setup

1. `cd admin && npm install`
2. Copy `.env.example` to `.env.local` and fill Firebase Web App configuration from Firebase Console → Project settings → Your apps.
3. Enable **Email/Password** in Firebase Console → Authentication → Sign-in method; create an admin user.
4. Copy that user's **Firebase Auth UID** into `ADMIN_UIDS` (comma-separated for multiple admins). Email alone does not grant admin access.
5. Set up server-side **Application Default Credentials** or point `GOOGLE_APPLICATION_CREDENTIALS` to a service-account JSON stored **outside the repo**. Never use a service-account key in `NEXT_PUBLIC_*` or commit it.
6. `npm run dev`, then open http://localhost:3000.

Server routes and dashboard use Firebase Admin SDK. This SDK bypasses Firestore Security Rules; the CMS therefore validates admin identity and allowlist **server-side**. Current Phase 5.3 provides no Firestore writes.

## Expected Firestore documents

- `content_config/current` with `publishedVersion: "v0.0.1"`
- `content_releases/v0.0.1` with `bundle` containing the content object, including `definitions`.

The existing Godot client remains unchanged and can use local fallback content if no release exists.

## Production checklist

- Deploy with HTTPS and private service credentials or workload identity.
- Restrict `ADMIN_UIDS`; rotate compromised accounts and revoke sessions.
- Use Firebase Authentication MFA for privileged users where available.
- Keep Firestore client rules deny-by-default except explicitly public published content.
- Add CSRF protection to any future state-changing CMS routes; never expose the Admin SDK to client components.
- Do not use this as a finished editor or publishing workflow.
