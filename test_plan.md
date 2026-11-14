# UpBridge Rwanda test plan

Status is recorded for this checkout on 13 Nov 2026. Feature-specific tests remain
with their owners; this plan tracks Jonathan's startup and cross-feature QA scope.

## Local execution

```bash
flutter pub get
flutter analyze
flutter test
flutter test integration_test
```

For emulator checks, start Auth and Firestore with
`firebase emulators:start --only auth,firestore`, then run the Flutter app with
`--dart-define=USE_FIREBASE_EMULATORS=true`. Never point these checks at production.

## Test cases

| Category | Case and expected behavior | Status |
|---|---|---|
| Unit | Splash destination resolves signed-out, unverified, onboarding, and role-home states using existing router conventions. | Passed (`flutter test --no-pub`) |
| Unit | Firebase emulator host defaults work for Android and local desktop; a supplied LAN host supports physical devices. | Passed (`flutter test --no-pub`) |
| Widget | Splash renders the supplied Kigali night image, brand content, and account actions without overflow at compact phone and wide desktop sizes. | Passed (`flutter test --no-pub`) |
| Widget | Configured duration triggers one destination; tapping an account action cancels the timer destination. | Passed (`flutter test --no-pub`) |
| Widget | Application launches into the splash route. | Passed (`flutter test --no-pub`) |
| Widget | Youth home and admin overview identify sample content as demo data. | Passed (`flutter test --no-pub`) |
| Integration | Cold start, relaunch, auth changes, logout, back behavior, and youth/mentor/admin navigation. | Not configured; blocked on app auth integration and `integration_test/` harness |
| Firebase emulator | Auth email verification plus Firestore owner profile create; reject unverified and cross-user writes. | Passed using disposable Auth and Firestore emulators; temporary users and documents cleared after the run |
| Firebase rules | Check-in ownership, one-per-month constraints, and notification read-state transition. | Rules are implemented; direct emulator cases remain to be added |
| Regression | Feature-owned screens and cross-feature routes remain stable after integration. | Pending broader journey coverage; feature owners retain feature-folder tests |
| Manual | Small-screen/large-text overflow, semantics/accessibility, reduced motion, and visual comparison against the supplied image. | Pending device exploration |

## Known gaps and blockers

- Firebase-backed login and role provisioning are not connected end to end yet;
  Ghislaine owns those feature files. Signed-in routing without the app's role
  record therefore falls back to the existing welcome route.
- Feature collection permissions depend on schema decisions from their owners.
  No production rules or indexes are deployed by this work.
- The supplied reference image is a Google thumbnail. The bundled image is used
  locally so launch does not depend on a network request.
- Integration tests require a configured device/emulator and a maintained
  `integration_test/` harness; none is currently present in the repository.

## Execution log

- `flutter pub get` - passed.
- `flutter analyze --no-pub` - passed with no issues.
- `flutter test --no-pub` - passed, 22 tests.
- `flutter build web --debug --no-pub` - passed; built `build/web` in 44.2s.
- `firebase emulators:exec` with isolated project `demo-upbridge-jonathan` - passed: unverified profile writes denied; verified owner write allowed; cross-user profile write denied. Temporary Auth accounts and Firestore documents were cleared in the script's `finally` cleanup; emulator shut down after execution.
- `scripts/start_firebase_emulators.ps1` - started Auth/Firestore and selected the installed Node runtime; stopped after readiness confirmation.
- The earlier REST smoke attempt used an unsupported direct verified-claim update and failed the positive write case. The current test uses the Auth Emulator's actual email verification OOB code flow and passes; no production project was contacted.
- `flutter test integration_test` - not run; the repository has no
  `integration_test/` directory or harness.
- Firebase emulator authorization tests - not run in this pass; Firebase rules
  and repositories were not changed. Existing setup notes document incomplete
  emulator authorization coverage.
