# UpBridge Rwanda

UpBridge Rwanda is a production Flutter + Firebase mobile application enabling Rwandan youth (`student`) to build IT and soft skills, connect with verified mentors (`mentor`), publish CVs and evidence-backed portfolios, and apply to career opportunities. Platform operators (`admin`) manage user status, mentor review, and content catalogs while keeping infrastructure 100% on the **Firebase Spark (free) plan** and **Cloudinary Free plan** (`vbzq5ssu`).

## Architecture Overview

- **State & Routing**: Riverpod (`flutter_riverpod`) + `go_router` using role-scoped `StatefulShellRoute.indexedStack` shells with isolated per-tab navigators and claims-based route guards (`lib/app/router/`).
- **Database (Spark Plan)**: Cloud Firestore (`upridge-rwanda-dev`) using strict ownership, lifecycle status enums/transitions (`StatusTransitions`), and role enforcement via `firestore.rules` and `firestore.indexes.json` — zero Cloud Functions or Secret Manager dependencies.
- **Media Storage (Cloudinary Free Plan)**: Direct frontend unsigned uploads (`POST https://api.cloudinary.com/v1_1/vbzq5ssu/image/upload`) using upload preset `upbridge_public_images` for validated `jpg`/`jpeg`/`png`/`webp` images (`<= 10 MB`). Firestore stores only `{ url, publicId, resourceType, size, ownerUid, createdAt }`.
- **Admin Privileged Operations**: In-app `isAdmin()` Firestore controls handle mentor reviews and user status updates; Auth custom-claim admin bootstrap, custom-claim mentor promotion (`role: 'mentor'`), and refresh-token revocation run via trusted local Admin SDK scripts (`scripts/`) or an optional external REST backend (`ADMIN_API_BASE_URL`).
- **Design System, Localization & Theming**: Centralized Material 3 design system (`lib/core/themes/`, `lib/shared/`), full `AppLocalizations` (`en`, `rw`, `fr`), and adaptive light/dark themes (`AppPalette`).

## Project Layout

```text
lib/
  app/                 App bootstrap, startup splash, verification & router/shells
  core/                Schema constants, lifecycle enums, models, providers, themes, Spark admin & Cloudinary services
  features/            Feature-first modules (auth, onboarding, home, learning, mentorship, mentor_workspace, opportunities, profile, notifications, admin)
  l10n/                ARB translations (app_en.arb, app_rw.arb, app_fr.arb) and generated localizations
  shared/              Shared Material 3 widgets, animation helpers, Firebase service wrappers
docs/                  Team integration, Firebase Spark, Cloudinary, and Firestore schema guides
rules_tests/           Firebase Emulator Suite security rules tests (@firebase/rules-unit-testing, node --test)
scripts/               Emulator launcher, rules test runner, admin bootstrap, mentor review & user status Admin SDK scripts
test/                  Unit & widget tests across all phases
integration_test/      End-to-end Flutter integration tests
```

## Documentation Guides

- [`docs/integration-guide.md`](docs/integration-guide.md) — Post-rework team integration, branch sync, and PR handoff workflow.
- [`docs/firebase-setup.md`](docs/firebase-setup.md) — Spark Firebase setup, rules/indexes deployment, emulators, and admin scripts (`authapp05@gmail.com`).
- [`docs/cloudinary-setup.md`](docs/cloudinary-setup.md) — Free-plan unsigned Cloudinary setup (`vbzq5ssu` / `upbridge_public_images`) and Console security hardening.
- [`docs/firestore-schema.md`](docs/firestore-schema.md) — Collections, fields, status lifecycles, and composite index contracts.

## Quick Start

### 1. Prerequisites & Local Configuration
- Install Flutter SDK, Firebase CLI (`firebase login`), and Node.js.
- Static checks (`flutter analyze`) and automated suites (`flutter test`, `integration_test`, rules tests) run out of the box on a fresh clone with **no** gitignored Firebase files.
- To run the live app (`flutter run`) against `upridge-rwanda-dev`, use **one** of these gitignored local setups:
  - **Mobile native config (simplest for plain `flutter run`)**: place `android/app/google-services.json` (for Android) and `ios/Runner/GoogleServiceInfo.plist` (for iOS) obtained from your team lead (or via `flutterfire configure --project=upridge-rwanda-dev`).
  - **Environment file (`--dart-define-from-file=.env`, works on Android, iOS, and Web)**: copy [`.env.example`](.env.example) to `.env`, fill in your `FIREBASE_*` values from your team lead, and run `flutter run --dart-define-from-file=.env`.
  - **Local emulators only (no Firebase keys required)**: start `.\scripts\start_firebase_emulators.ps1` and run `flutter run --dart-define=USE_FIREBASE_EMULATORS=true`.

### 2. Install Dependencies & Generate Localizations
```powershell
flutter pub get
flutter gen-l10n
npm install
npm --prefix rules_tests install
```

### 3. Run the App
```powershell
# Run against live Firebase using native google-services.json / GoogleServiceInfo.plist
flutter run

# Or run against live Firebase on Android, iOS, or Web using gitignored .env
flutter run --dart-define-from-file=.env

# Run against local Firebase Emulators (emulator started separately; works without .env or google-services.json)
flutter run --dart-define=USE_FIREBASE_EMULATORS=true

# Physical device targeting your computer's local Firebase Emulators
flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=<computer-LAN-IP>
```

## Verification & Tests

Run all checks before pushing a branch or opening a PR to `main`:

```powershell
# Static analysis
flutter analyze

# Unit & widget test suite
flutter test --reporter compact

# End-to-end Flutter integration tests (in-memory service harness)
flutter test -d flutter-tester integration_test/app_flows_test.dart --reporter compact

# Firestore security rules test suite (isolated Firebase Emulator via node --test)
.\scripts\run_rules_tests.ps1
```

## Firebase Emulators, Deployment & Admin Scripts

Start local Auth (`9099`), Firestore (`8080`), and Emulator UI (`4000`):

```powershell
# Windows
.\scripts\start_firebase_emulators.ps1

# macOS / Linux
firebase emulators:start --project upridge-rwanda-dev --only auth,firestore
```

Deploy Firestore security rules and composite indexes to Firebase (`upridge-rwanda-dev` — note `--project` is required because no `.firebaserc` is committed):

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project upridge-rwanda-dev
```

Run trusted Admin SDK operator scripts (set `GOOGLE_APPLICATION_CREDENTIALS` for live Firebase, or `FIREBASE_AUTH_EMULATOR_HOST`/`FIRESTORE_EMULATOR_HOST` for emulators):

```powershell
# Bootstrap initial admin custom claim
node scripts/bootstrap_admin.mjs --project upridge-rwanda-dev --email authapp05@gmail.com

# Mirror mentor role custom claim or reject application
node scripts/review_mentor.mjs --project upridge-rwanda-dev --uid <uid> --decision approve

# Activate or deactivate a user account + revoke Auth refresh tokens
node scripts/set_user_status.mjs --project upridge-rwanda-dev --uid <uid> --status deactivated
```

## Security Principles

- Self-registration creates only `role = student`. Client apps cannot self-assign `role`, `isApproved`, or `status`.
- Mentor onboarding creates a `mentorApplications/{uid}` record in `pending` state; mentor approval updates `users/{uid}` (`role: 'mentor'`, `isApproved: true`) under verified `isAdmin()` rules, while `scripts/review_mentor.mjs` (or optional external Admin API) optionally mirrors Auth custom claims.
- Account deactivation runs via verified `isAdmin()` Firestore status rules (`active <-> deactivated`) and optional `scripts/set_user_status.mjs` for Auth token revocation + immutable `auditLogs`.
- Never commit `.env`, service-account JSON keys, native Firebase config secrets, or Cloudinary API secrets.
