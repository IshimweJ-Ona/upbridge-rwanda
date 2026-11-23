# Firebase Setup & Admin Provisioning (`upridge-rwanda-dev` — Spark Free Plan)

UpBridge Rwanda (`upridge-rwanda-dev`) is configured strictly for the **Firebase Spark (free) plan**:

- **Included on Spark**:
  - Firebase Authentication (Email/Password + mandatory Email Verification link)
  - Cloud Firestore + `firestore.rules` + `firestore.indexes.json`
  - Local Firebase Emulators for Auth (`9099`), Firestore (`8080`), and Emulator UI (`4000`)
- **Not required (Blaze-only features removed)**:
  - No Firebase Cloud Functions deployment (`firebase.json` has no `"functions"` target)
  - No Google Cloud Secret Manager (`firebase functions:secrets:set`)
  - No billing account configuration required

---

## Console Prerequisites

1. **Authentication -> Sign-in method**: Enable **Email/Password**.
2. **Authentication -> Templates -> Email address verification**: Confirm sender name and authorized continue domains match your Firebase configuration.
3. Fresh clones pass `flutter analyze` and `flutter test` without any gitignored Firebase config files. For live `flutter run`, either place `android/app/google-services.json` (matching `com.example.upbridge`) / `ios/Runner/GoogleServiceInfo.plist`, or copy `.env.example` to `.env` and launch with `flutter run --dart-define-from-file=.env`.

---

## Deploy Security Rules & Composite Indexes (Spark-Compatible)

```bash
firebase deploy --only firestore:rules,firestore:indexes --project upridge-rwanda-dev
```

---

## One-Time Admin Account Bootstrap (`authapp05@gmail.com`)

Admin privileges (`{ "role": "admin" }`) can **never** be self-assigned from the client app or edited directly in Firestore. Provision `authapp05@gmail.com` using the trusted local Admin SDK script:

1. **Register & Verify Email**:
   - Open the UpBridge app -> **Sign Up** with `authapp05@gmail.com` and your chosen password.
   - Open the Firebase email verification link sent to your inbox and tap **I verified my email**.
2. **Grant Admin Custom Claim**:
   - Download a temporary Firebase Admin service-account JSON key from **Firebase Console -> Project Settings -> Service accounts** (keep offline, never commit, delete after use).
   - Run:
     ```bash
     # Production (upridge-rwanda-dev)
     GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
       node scripts/bootstrap_admin.mjs --project upridge-rwanda-dev --email authapp05@gmail.com
     ```
     Or for local emulators:
     ```powershell
     $env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"
     $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"
     node scripts/bootstrap_admin.mjs --email authapp05@gmail.com
     ```
3. **Refresh Session**: Sign out and sign back in inside the app so your ID token picks up `{ "role": "admin" }` and routes to `/a/overview`.

---

## Admin Privileged Workflows on the Spark Plan

Because client SDKs cannot mint Firebase Auth custom claims or revoke refresh tokens safely, UpBridge uses a **Spark hybrid workflow** (`lib/core/services/admin_operations_service.dart`):

| Operation | In-App Spark Support | Optional Admin SDK / External API Action |
|---|---|---|
| **Approve mentor application (`pending -> approved`)** | Runs directly in-app (`AdminMentorReviewScreen`) via verified `isAdmin()` Firestore batch: approves `mentorApplications/{uid}`, promotes `users/{uid}` (`role='mentor'`, `isApproved=true`), seeds `profiles/{uid}`, and notifies applicant | `scripts/review_mentor.mjs --project upridge-rwanda-dev --uid <uid> --decision approve` (or `ADMIN_API_BASE_URL`) also mints `{ role: 'mentor' }` custom claim + records `auditLogs` |
| **Reject mentor application (`pending -> rejected`)** | Runs directly in-app (`AdminMentorReviewScreen`) via `isAdmin()` Firestore rules + writes applicant notification | Optional audit log via `scripts/review_mentor.mjs --decision reject` |
| **Activate / deactivate user account** | Updates `users/{uid}.status` directly in-app via `isAdmin()` rules; app session guard immediately redirects deactivated users to `/account-deactivated` | `scripts/set_user_status.mjs --uid <uid> --status deactivated` also sets Auth `disabled: true`, revokes refresh tokens, and records `auditLogs` |

### Optional Free-Tier External Admin Backend (`ADMIN_API_BASE_URL`) & Approval Emails

Run the included trusted backend (`server/index.mjs`) locally or on any Node host (Render/Fly/Cloud Run) with Resend (`RESEND_API_KEY`) or SMTP (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`) to send idempotent mentor approval emails and mint custom claims:

```bash
RESEND_API_KEY=re_xxx MAIL_FROM="SkillBridge Team <no-reply@yourdomain.com>" \
  node server/index.mjs
```

Then build/run Flutter pointing to the backend:

```bash
flutter run --dart-define=ADMIN_API_BASE_URL=https://your-admin-service.example.com
```

Alternatively, if using the official Firebase **Trigger Email from Firestore** extension (`mail` collection) without hosting a Node server, pass `--dart-define=ENABLE_TRIGGER_EMAIL_EXTENSION=true`. Without either configured, `SparkAdminOperationsClient` records `approvalEmailStatus: 'not_configured'` and never claims an email was sent.

### Legacy Account Migration (`scripts/migrate_mentor_accounts.mjs`)

Preview changes (dry-run by default):

```bash
node scripts/migrate_mentor_accounts.mjs --project upridge-rwanda-dev
```

Apply verified patches:

```bash
node scripts/migrate_mentor_accounts.mjs --project upridge-rwanda-dev --apply
```

---

## Local Firebase Emulators & Security Rules Tests

Ports configured in `firebase.json`:
- **Auth Emulator**: `9099`
- **Firestore Emulator**: `8080`
- **Emulator UI**: `4000`

Start local emulators:

```powershell
.\scripts\start_firebase_emulators.ps1
```

Run automated Firestore security rules tests:

```powershell
.\scripts\run_rules_tests.ps1
```
