# Local testing

Run `flutter pub get`, `flutter analyze`, and `flutter test`. Tests cover email-verification redirect policy, shared Firebase error/date helpers, stagger-animation disposal, and the welcome smoke test. The initial test run was blocked before widget tests because pubspec referenced font files absent from the repository; the declaration was removed so Flutter uses platform fonts.

For Firebase-backed development, run `firebase emulators:start --only auth,firestore` and launch with `--dart-define=USE_FIREBASE_EMULATORS=true`. Emulator data is isolated from production. Startup and rule parsing were verified, and an unverified Auth Emulator token was denied a profile write. The verified-token/role-escalation authorization suite did not complete because the local Auth Emulator OOB verification-code retrieval step did not return a code. Complete those tests, plus feature-specific mentor access checks, before deploying rules.

Do not call mocked repository tests Firebase integration tests. Do not run integration tests against production.
