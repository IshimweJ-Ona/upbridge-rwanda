# UpBridge Rwanda

UpBridge Rwanda is a production Flutter + Firebase mobile application enabling Rwandan youth (`student`) to build IT and soft skills, connect with verified mentors (`mentor`), publish CVs and evidence-backed portfolios, and apply to career opportunities. Platform operators (`admin`) manage user status, mentor review, and content catalogs while keeping infrastructure 100% on the **Firebase Spark (free) plan** and **Cloudinary Free plan** (`vbzq5ssu`).

## Architecture Overview

- **State & Routing**: Riverpod (`flutter_riverpod`) + `go_router` using role-scoped `StatefulShellRoute.indexedStack` shells with isolated per-tab navigators and claims-based route guards.
- **Database (Spark Plan)**: Cloud Firestore (`upridge-rwanda-dev`) using strict ownership, lifecycle status enums/transitions, and custom-claim role enforcement via `firestore.rules` and `firestore.indexes.json` — zero Cloud Functions or Secret Manager dependencies.
- **Media Storage (Cloudinary Free Plan)**: Direct frontend unsigned uploads (`POST https://api.cloudinary.com/v1_1/vbzq5ssu/image/upload`) using upload preset `upbridge_public_images` for validated `jpg`/`jpeg`/`png`/`webp` images (`<= 10 MB`). Firestore stores only `{ url, publicId, resourceType, size, ownerUid, createdAt }`.
- **Admin Privileged Operations**: In-app `isAdmin()` Firestore controls handle mentor rejection and user status updates; Auth custom-claim mentor promotion (`role: 'mentor'`) and token revocation run via trusted local Admin SDK scripts (`scripts/review_mentor.mjs`, `scripts/set_user_status.mjs`) or an optional external REST backend (`ADMIN_API_BASE_URL`).
- **Localization & Theming**: Full `AppLocalizations` (`en`, `rw`, `fr`) plus adaptive light/dark Material 3 themes (`AppPalette`).

## Project Layout

```text
lib/
  app/                 App bootstrap, startup splash, verification & router/shells
  core/                Schema constants, lifecycle enums, models, providers, themes, Spark admin & Cloudinary services
  features/            Feature-first modules (auth, onboarding, home, learning, mentorship, mentor_workspace, opportunities, profile, notifications, admin)
  l10n/                ARB translations (app_en.arb, app_rw.arb, app_fr.arb) and generated localizations
  shared/              Shared Material 3 widgets, animation helpers, Firebase service wrappers
rules_tests/           Firebase Emulator Suite security rules tests (@firebase/rules-unit-testing)
scripts/               Emulator launcher, rules test runner, admin bootstrap, mentor review & user status Admin SDK scripts
test/                  Unit & widget tests across all phases
integration_test/      End-to-end Flutter integration tests
```

## Quick Start

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

See:
- [`docs/integration-guide.md`](docs/integration-guide.md) — Post-rework team integration, branch sync, and PR handoff workflow.
- [`docs/firebase-setup.md`](docs/firebase-setup.md) — Spark Firebase setup, rules/indexes deployment, emulators, and admin scripts (`authapp05@gmail.com`).
- [`docs/cloudinary-setup.md`](docs/cloudinary-setup.md) — Free-plan unsigned Cloudinary setup (`vbzq5ssu` / `upbridge_public_images`) and Console security hardening.
- [`docs/firestore-schema.md`](docs/firestore-schema.md) — Collections, fields, status lifecycles, and composite index contracts.

## Local Emulators & Security Rules Tests

Start Auth and Firestore emulators on Windows:

```powershell
.\scripts\start_firebase_emulators.ps1
```

Run the Flutter app against local emulators:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Run Firestore security rules unit tests (starts isolated emulator and runs Mocha suite):

```powershell
.\scripts\run_rules_tests.ps1
```

## Security Principles

- Self-registration creates only `role = student`. Client apps cannot self-assign `role`, `isApproved`, or `status`.
- Mentor onboarding creates a `mentorApplications/{uid}` record in `pending` state; only a verified `admin` executing `scripts/review_mentor.mjs` (or optional external Admin API) grants `{ role: 'mentor' }` custom claims.
- Account deactivation runs via verified `isAdmin()` Firestore status rules (`active <-> deactivated`) and optional `scripts/set_user_status.mjs` for Auth token revocation + immutable `auditLogs`.
- Never commit `.env`, service-account JSON keys, or Cloudinary API secrets.
