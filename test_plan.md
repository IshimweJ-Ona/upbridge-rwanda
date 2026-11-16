# UpBridge Rwanda test plan

This plan tracks the current checkout. It separates automated coverage from flows that remain unimplemented or require owner contracts.

## Commands

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Firebase rules smoke test (isolated demo project; do not point at production):

```powershell
.\scripts\test_firebase_emulator_rules.ps1
```

## Automated coverage

| Area | Coverage |
|---|---|
| Unit | Date/currency/phone formatting, Kigali time, check-in validation and payload, admin listing validation, route guard policy, Firebase error and timestamp helpers. |
| Widget | Splash appearance/navigation, registration/login pending messages, demo-state labeling, shared reveal disposal, and app startup. |
| Cloudinary service | Multipart request shape, missing configuration, image size/type rejection, response validation, and upload error handling with an HTTP test client. |
| Firebase emulator | Email verification; allow verified owner profile/check-in writes; reject unverified and cross-user profile writes, invalid check-ins, duplicate submissions, and check-in edits. |

## Gaps

- No `integration_test/` harness currently exists for real app journeys on Android.
- The current full-suite line coverage is 18.6% (1,094 of 5,877 executable lines), below the assignment's 70% target. Coverage is not yet reported separately for Jonathan-owned code.
- Notification access, custom-claim admin access, and each teammate-owned entity still need emulator tests after owners confirm their contracts.
- Auth screens still use demo state; real email/password and Google auth are Ghislaine's work.
- Portfolio, learning, mentorship, opportunities, and applications still need their owners' persistence contracts before CRUD/security tests can be meaningful.
- Cloudinary upload tests use a mocked HTTP transport. A live upload cannot run until a free account and a restricted unsigned image preset are configured. Private certificates must wait for a trusted signing service.
- Physical Android emulator/device launch and release APK evidence still need recording for the assignment; web/desktop builds do not satisfy the mobile requirement.

## Latest known results

- `flutter test --no-pub --reporter expanded` passed 42 tests, including the five Cloudinary adapter tests.
- `flutter analyze --no-pub` passed with no issues after cleanup.
- `flutter test --no-pub --coverage --reporter compact` passed all 42 tests; generated `coverage/lcov.info` reports 18.6% overall line coverage.
- The Auth/Firestore rules smoke test passed against a unique disposable `demo-*` project. It confirmed email verification, profile ownership, and check-in validation/immutability against the actual Firestore rules; the emulator shut down and temporary Auth/Firestore data was cleared.
- `flutter build apk --debug --no-pub` built `build/app/outputs/flutter-apk/app-debug.apk` successfully. No Android emulator or phone is currently attached, so on-device launch remains unverified.
