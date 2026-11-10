# Jonathan implementation log

## Baseline

- Branch: `feature/jonathan-engineering-execution` (created from clean `main`).
- `flutter analyze`: passed before changes.
- Initial `flutter test`: blocked before test execution because the declared IBM Plex font files were absent; after removing that invalid declaration, it exposed a pending stagger-animation timer during teardown.
- Firebase CLI read-only checks confirmed project `upridge-rwanda-dev`, Android/iOS/web registrations, and the default Firestore database in `nam5`.
- Repository has no committed Google Services JSON or iOS plist; local copies are ignored.

## Work completed

- Removed missing font asset declarations and selected Flutter's platform font fallback.
- Made Firebase initialization safe when an app is already initialized and added an opt-in debug emulator connection.
- Exposed injectable Firebase Auth and Firestore providers, auth state, current user, sign-out, verification email send/reload, and token refresh without anonymous sign-in.
- Added a shared router gate and resend/check verification screen; startup now fails closed if Firebase initialization fails, and Firestore rules require the verified-email claim.
- Implemented typed app failures, Firebase error mapping without exposing service messages, and timestamp/document converters; helper behavior is covered by tests.
- Added a local Auth/Firestore emulator configuration, baseline Firestore rules, and composite indexes derived from the shared repository's queries.
- Added Firebase, schema, local development, and team integration documentation.
- Cancelled stagger timers when shared reveal widgets are disposed and added a regression test.
- Marked the home dashboard's sample content and the administration dashboard's hardcoded statistics as demonstration data.

## Verification after changes

- `flutter pub get`: passed.
- `flutter analyze --no-pub --no-fatal-infos`: passed with no issues.
- `flutter test`: passed (9 tests: three email-gate tests, four shared Firebase helper tests, reveal timer regression, and app welcome smoke test).
- `firebase emulators:exec --project demo-upbridge --only auth,firestore "echo Firebase-auth-and-firestore-emulators-ready"`: exited successfully; startup/rule parsing only, not authorization behavior.
- `flutter build web --debug --no-pub`: produced `build/web/index.html`.
- `flutter run -d web-server --web-port 8765 --web-hostname 127.0.0.1 --no-pub`: served the app; local HTTP check returned 200.
- Emulator REST check confirmed an unverified account's profile write is denied. The follow-up verified-token test did not complete because the local Auth Emulator verification-code retrieval step did not return a code; full authorization tests remain pending.
- `git diff --check`: passed.
- `dart format --output=none --set-exit-if-changed .`: reports pre-existing formatting differences in 80 Dart files across the repository. It did not modify them; out-of-scope feature files remain untouched.
- `flutter devices`: Windows, Chrome, and Edge are available. A platform launch was not verified.

## Outstanding

- Firebase project services and authentication providers require console verification; no project mutations were made.
- Email/Password must be enabled and the verification template/authorized continue URL configured in Firebase Console. That configuration was not changed.
- Ghislaine's signup/login screens remain demo/phone-based; she must connect them to Firebase so real users can create accounts and reach the shared verification gate.
- Rules need Emulator Suite authorization tests against each feature owner's final data contract before deployment.
- Dashboard and administration screens currently render demo-store data. Their figures are labeled as demo until approved live data providers exist.
- Feature-owned collection writes are denied by the initial rules until each owner supplies verified field and transition requirements. Lisa's portfolio path mismatch is recorded in `firestore-schema.md`.
- Font files are absent; obtain licensed assets from the team if IBM Plex is required.
- Jonathan's implementation is recorded in local commits on the feature branch. Nothing was pushed, merged, or deployed to production.
