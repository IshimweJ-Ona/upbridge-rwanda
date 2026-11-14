# UpBridge Rwanda

UpBridge Rwanda is a Flutter career development app for young people in Rwanda. It brings together practical learning, portfolios, mentorship, and career opportunities. The project is actively developed; some screens still use clearly labeled sample data, and feature completion varies by team owner.

## Current status

- The app starts on a branded splash screen with a bundled Kigali night image.
- Flutter, Riverpod, and GoRouter provide the app foundation and shared navigation.
- Firebase Core, Authentication, and Cloud Firestore are configured for local development and emulator use.
- Shared routing includes email-verification and role-area guards. Authentication screens and role provisioning still need their feature owner to connect real account flows.
- Jonathan's home and admin integration includes Firestore read boundaries, monthly check-ins, notifications, route policy, and shared app components. Screens backed by `AppStore` remain demo data and are labeled as such.
- Firestore rules and indexes are present locally. They have not been deployed to the development or production Firebase project.
- Firebase Storage is not configured as a dependency; image selection is local until an upload backend is agreed.

See [`docs/firestore-schema.md`](docs/firestore-schema.md) and [`docs/integration-guide.md`](docs/integration-guide.md) for contract ownership and handoffs.

## Technology

| Technology | Use |
|---|---|
| Flutter and Dart | Cross-platform app and UI |
| Riverpod | State and dependency management |
| GoRouter | Navigation and role-aware routing |
| Firebase Core | Firebase initialization |
| Firebase Authentication | Auth service and email-verification integration points |
| Cloud Firestore | Shared repository and data-source integration |

## Project layout

```text
lib/
  app/          App shell, routing, splash, and unavailable states
  core/         Shared constants, errors, themes, and utilities
  features/     Feature-owned presentation, domain, and data code
  shared/       Shared models, Firebase services, and reusable widgets
test/           Unit and widget tests
scripts/        Local Firebase emulator helpers and rule smoke test
docs/           Firebase setup, schemas, integration, and testing notes
firestore.rules Firestore authorization rules (local only)
```

Feature code belongs to its assigned owner. Coordinate changes to shared routes, models, Firebase configuration, rules, and indexes with Jonathan. Do not implement another feature owner's schema based on assumptions; agree on its fields and access rules first.

## Requirements

- Flutter and Dart versions compatible with [`pubspec.yaml`](pubspec.yaml)
- Git
- For Android: Android Studio and an emulator or device
- For Firebase emulator checks: Firebase CLI, Node.js, and Java
- For iOS builds: macOS and Xcode

## Get started

```bash
git clone https://github.com/IshimweJ-Ona/upbridge-rwanda.git
cd upbridge-rwanda
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

Some platform Firebase files are local and ignored by Git. Follow [`docs/firebase-setup.md`](docs/firebase-setup.md) for the approved setup; do not commit service account keys or secrets.

## Firebase emulators

Use Auth and Firestore emulators for local Firebase work. The app connects to them in debug builds with:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

On Windows, start the emulators with:

```powershell
.\scripts\start_firebase_emulators.ps1
```

Elsewhere, use:

```bash
firebase emulators:start --project upridge-rwanda-dev --only auth,firestore
```

The default ports are Auth `9099`, Firestore `8080`, and Emulator UI `4000`. Android emulators connect through `10.0.2.2`; physical devices need the computer's reachable LAN address via `FIREBASE_EMULATOR_HOST`. See [`docs/firebase-setup.md`](docs/firebase-setup.md) for platform details.

### Firestore rules smoke test

This check starts isolated demo emulators, verifies email through the Auth Emulator's local verification code, and exercises profile ownership rules. It deletes its temporary emulator accounts and documents when it finishes. Stop other emulators first so the default ports are available:

```powershell
firebase emulators:exec --project demo-upbridge-jonathan --only auth,firestore "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_firebase_emulator_rules_smoke.ps1"
```

The smoke test checks that unverified writes and cross-user profile writes are denied while a verified owner can create their own profile. It does not replace the remaining check-in, notification, or feature-owner authorization tests. Never use production data for tests.

## Tests

Run before opening a pull request:

```bash
flutter analyze
flutter test
```

Current unit and widget coverage includes routing policy, splash behavior, shared Firebase helpers, Kigali time and formatting, check-in validation, admin listing validation, and demo-state labeling. The current full suite passes 36 tests. See [`test_plan.md`](test_plan.md) for coverage and known gaps.

## Team ownership

| Owner | Area |
|---|---|
| Jonathan Ishimwe | App integration, Firebase setup, shared infrastructure, home, admin, and project-wide testing |
| Ghislaine Marie Inez | Authentication, onboarding, and user management |
| Lisa Ineza | Learning, submissions, progress, and portfolio |
| Boaz Prince Iza | Mentorship and mentor workspace |
| Kellen Ashley Mutoni | Opportunities and applications |

The authentication screens are not yet connected end to end to Firebase. Admin operations that depend on another owner's unconfirmed Firestore contract remain behind integration boundaries until that contract is agreed. Refer to [`docs/integration-guide.md`](docs/integration-guide.md) for owner-specific handoffs.

## Security and contribution

- Never commit passwords, access tokens, private keys, or service account files.
- Keep local tests on Firebase emulators; do not deploy rules/indexes or modify production data without explicit project approval.
- Work in your assigned feature area and coordinate shared API or schema changes.
- Run analysis and tests, describe known gaps, and submit work through a reviewed pull request.
- Do not push unfinished work directly to `main`.

Repository: [github.com/IshimweJ-Ona/upbridge-rwanda](https://github.com/IshimweJ-Ona/upbridge-rwanda)
