# Local testing

Run `flutter pub get`, `flutter analyze`, and `flutter test`. Tests cover email-verification redirect policy, shared Firebase error/date helpers, stagger-animation disposal, and the welcome smoke test. The initial test run was blocked before widget tests because pubspec referenced font files absent from the repository; the declaration was removed so Flutter uses platform fonts.

For Firebase-backed development, run `scripts/start_firebase_emulators.ps1` on Windows or `firebase emulators:start --project upridge-rwanda-dev --only auth,firestore` elsewhere. Launch with `--dart-define=USE_FIREBASE_EMULATORS=true`; physical devices also need `--dart-define=FIREBASE_EMULATOR_HOST=<computer-LAN-IP>`. Emulator data is isolated from production. The emulator rules smoke script uses an Auth email verification OOB code, verifies profile ownership, and clears its test users/documents before exit:

```powershell
firebase emulators:exec --project demo-upbridge-jonathan --only auth,firestore "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_firebase_emulator_rules_smoke.ps1"
```

Stop any other local Auth/Firestore emulator first so the default ports are free. The smoke test confirms unverified writes are denied, a verified owner can create their profile, and cross-user writes are denied. Check-in and notification rule cases, feature-specific mentor access, and end-to-end auth provisioning still need coverage before rules are deployed.

Do not call mocked repository tests Firebase integration tests. Do not run integration tests against production.
