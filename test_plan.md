# UpBridge Rwanda test plan

This plan tracks `main` (`d8785ba`) after Jonathan's routing, rules, live-provider wiring, cross-team contract alignment, and test updates. It separates verified automated coverage from flows that depend on running local Firebase Emulators or fixes owned by teammates.

## Commands

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib/app lib/core lib/features/admin lib/features/home lib/shared test/app test/core test/shared test/features/home test/features/admin test/widget_test.dart
flutter analyze --no-pub
flutter test --no-pub --coverage --reporter expanded test/app test/core test/shared test/features/home test/features/admin test/widget_test.dart
flutter test --no-pub --reporter compact
```

Firebase rules smoke test (isolated `demo-*` project; never point at production):

```powershell
.\scripts\test_firebase_emulator_rules.ps1
```

## Automated coverage

| Area | Coverage |
|---|---|
| Unit & domain | Date/currency/phone formatting, Kigali time (`UTC+2`), check-in validation & payload, admin listing draft validation, `ForwardApplication` & `RemoveListing` use cases, route guard & verified-session routing policy (`trustedRoleFromClaim`, `verifiedUserDestination`, `splashDestination` including `firebaseProfileExists`, `emailVerificationRedirect`, `roleAreaRedirect`), `AppFailure`, `errorMessage`, Firestore timestamp helpers, uninitialized `AuthService` safety (`signIn`, `signUp`, `sendPasswordReset`, `sendVerificationEmail`, `signOut`), `AppData.copyWith` including `mentors`. |
| Home & shared data layers | `HomeRepositoryImpl.loadSummary`, `CheckInRepositoryImpl` duplicate/create rules, `NotificationRepositoryImpl` streams, `NotificationRemoteDataSource.markAllRead` pagination beyond 100 and across 450-write batches + `markRead` ownership, and `UpBridgeRepository.ensureYouthProfile` / `setTaskStatus` / `addProject` / `submitWork`. |
| Admin data layer | `AdminRemoteDataSource` (`listUsers` bounds, cursor pagination, `getUser`, `countUsers`), `AdminListingDataSource` (`listPublished`), `AdminUsersRepositoryImpl`. |
| Widget & UI | Splash layout/routing and `/signup` + `/login` navigation; `VerifyEmailScreen` resend/verify/role routing/sign-out; `RoleShell` live desktop header & demo-badge suppression; `HomeScreen`, `CheckInScreen`, `NotificationsScreen` (both live provider wiring and labeled demo mode); `AdminOverviewScreen` live Firestore count + all admin demo detail screens labeled `'Demonstration data'`; `AppAlert`, `AppBarChart`, `AppDonutChart`, `AppLineChart`; reveal timer cleanup; app startup. |
| Cloudinary & HTTP | Multipart request shape, missing configuration, image size/type rejection, response validation, and upload error handling with `MockClient`; `HttpJsonClient` JSON parsing & HTTP status handling. |
| Firebase emulator script (`scripts/firebase_emulator_rules_smoke.mjs`) | Expanded to verify email verification, youth baseline creation & self-escalation denial, custom claims (`role: 'admin'`, `role: 'mentor'`), immutable `checkIns` against admins, notification owner read/`markRead`/client-create denial, `mentorProfiles` mentor update allowlist & `verified` tamper denial, `mentorSessions` `mentorId` read & transition rules, `applications` `{uid}_{oppId}` submit & withdraw rules, `auditLogs`, `appSettings`, catalog visibility, and locked `projects`/`submissions` collections. |

## Gaps & Team Blockers

- **Pre-existing test failures on `main` (`d8785ba`, PR #5 — Lisa)**:
  1. `test/features/learning/learning_screens_test.dart:42` expects `'About this task'` while `SectionLabel` (`MonoLabel`) uppercases titles to `'ABOUT THIS TASK'`.
  2. `test/features/portfolio/portfolio_screens_test.dart:34` fails with 4 `RenderFlex overflowed` exceptions in `lib/features/portfolio/presentation/pages/portfolio_screen.dart` lines 64 and 173 at 390 px viewport / test font metrics.
  3. `test/features/portfolio/portfolio_screens_test.dart:89` expects `'Project description'` while `SectionLabel` renders `'PROJECT DESCRIPTION'`.
- No `integration_test/` suite exists yet (`integration_test` is not declared in `pubspec.yaml`).
- Line coverage across files instrumented by Jonathan's suite is **37.6%** (`2,777 / 7,382` lines), and **57.9%** (`2,684 / 4,633` lines) across `lib/app`, `lib/shared`, `lib/features/home`, and `lib/features/admin`. Remaining project-wide gap toward 70% comes from `app_store.dart` demo state methods (`72 / 367`), unintegrated feature modules without Firestore persistence yet, and learning/portfolio/mentorship/application flows awaiting device/emulator integration tests.
- `.\scripts\test_firebase_emulator_rules.ps1` and physical Android device/APK runtime checks must be executed locally with Node, Java, Firebase CLI, and an attached Android emulator/device.

## Latest verified results

- `dart format` (on Jonathan-scope updated files in `jonathan-updates/`): clean (`37 files`, 0 formatting diffs).
- `flutter analyze --no-pub` (on `main` `d8785ba` + `jonathan-updates`): **No issues found**.
- `flutter test --no-pub --coverage --reporter expanded test/app test/core test/shared test/features/home test/features/admin test/widget_test.dart`: **76 passed, 0 failures** (`coverage/lcov.info`: 37.6% instrumented / 57.9% across `app` + `shared` + `home` + `admin`).
- `flutter test --no-pub --reporter compact` (full repository on `main` `d8785ba` + `jonathan-updates`): **101 passed, 3 failed** — all 3 failures are PR #5's pre-existing `learning_screens_test.dart` / `portfolio_screens_test.dart` failures already present on `main`.
