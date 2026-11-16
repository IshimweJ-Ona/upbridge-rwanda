# Local testing

Run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter test --coverage`. The current automated test inventory and known gaps are in [`../test_plan.md`](../test_plan.md).

The real Auth/Firestore rules test runs against Firebase Emulator Suite, never production. On Windows, run:

```powershell
.\scripts\test_firebase_emulator_rules.ps1
```

The helper selects an installed Node binary directly, creates a unique `demo-*` emulator project, starts Auth and Firestore, tests email verification and Firestore profile/check-in rules, removes the run's emulator data, and shuts the emulators down. This avoids modifying the app's development or production Firebase projects.

For interactive Firebase-backed development, start Auth and Firestore with `scripts/start_firebase_emulators.ps1`, then launch Flutter with `--dart-define=USE_FIREBASE_EMULATORS=true`. Physical Android devices also need `--dart-define=FIREBASE_EMULATOR_HOST=<computer-LAN-IP>`.

Cloudinary adapter unit tests use a mocked HTTP transport because an account and upload preset have not been configured. They are not Firebase integration tests. Do not run integration tests against production.
