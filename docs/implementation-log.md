# Jonathan implementation log

## Baseline

- Branch: `feature/jonathan-engineering-execution` (at `d658038`, behind `main` `d8785ba` which merged PR #3, PR #5, and PR #6).
- `flutter analyze` on current `main` (`d8785ba`): passed with no issues.
- `flutter test` on current `main` (`d8785ba`) has 3 pre-existing failures introduced by PR #5 (`learning_screens_test.dart` line 42 and `portfolio_screens_test.dart` lines 34 & 89); all Jonathan/core/shared/home/admin tests pass.
- Repository has no committed Google Services JSON or iOS plist; local copies are ignored.

## Work completed

- Removed missing font asset declarations and selected Flutter's platform font fallback.
- Made Firebase initialization safe when an app is already initialized and added an opt-in debug emulator connection.
- Exposed injectable Firebase Auth and Firestore providers, `authUserChangesProvider`, `verifiedSessionProvider` (combining `userChanges`, ID token custom role claims, and `users/{uid}` `onboarded` / `displayName` / `accountStatus` streams), `ensureYouthProfile`, `getProfile`, 30s deduped `sendVerificationEmail`, and `signIn` / `signUp` / `sendPasswordReset` on `AuthService` (matching `feature/auth-profile`) with `Firebase.apps.isEmpty` guards.
- Re-exported `image_picker_field.dart` in `lib/shared/shared.dart` to match `feature/auth-profile`.
- Fixed cold-start / verified-session routing so verified Firebase users never get kicked to `/welcome` when `AppStore.user` is null, and verified youth missing `users/{uid}` route through `/verify-email` to ensure their baseline document exists before onboarding merge writes.
- Removed splash `'Waiting for registration screen'` / `'Waiting for login screen'` placeholders so splash action buttons route directly to `/signup` and `/login`, and updated the Kigali photo caption.
- Updated `RoleShell` to display signed-in `VerifiedSession` identity in desktop `SideNav` and hide fake demo tab badges during live Firebase sessions.
- Fixed `AppData.copyWith` to accept and forward `List<Mentor>? mentors`.
- Fixed `NotificationRemoteDataSource.markAllRead` pagination so it clears all unread notifications across 450-write batches instead of stopping at 100.
- Wired `HomeScreen`, `CheckInScreen`, `NotificationsScreen`, `AdminOverviewScreen`, `AdminUsersScreen`, and `AdminSettingsScreen` to live Firebase providers when authenticated, labeled every remaining `AppStore`-backed screen in `home` and `admin` as `'Demonstration data'` / `'Demo preview'`, fixed `AdminSettingsScreen` logout to sign out of Firebase Auth, and replaced hardcoded `DateTime(2026, 10, 17)` in `NewListingScreen` with `KigaliTime.startOfDay(DateTime.now())` and `ListingDraft` validation.
- Fixed `firestore.rules` `isGenericCollection` to exclude `checkIns`, `notifications`, `mentorProfiles`, `mentorSessions`, and `applications`, preserving `checkIns` immutability against admins and `notifications` create/delete lock while enabling finalized teammate rules for Boaz (`mentorProfiles` mentor self-updates, `mentorSessions` `mentorId` reads + create/withdraw/state transitions) and Kellen (`applications` `{uid}_{oppId}` create/withdraw/re-apply). Left `projects`, `submissions`, `reviews`, and `taskProgress` locked until Lisa finalizes her Firestore persistence contract.
- Expanded `scripts/firebase_emulator_rules_smoke.mjs` to cover `admin` and `mentor` custom claims, immutable `checkIns`, `notifications`, `auditLogs`, `appSettings`, catalog visibility, `mentorProfiles`, `mentorSessions`, and `applications`.
- Added unit and widget tests for Jonathan's app/shared/home/admin UI and data layers, bringing Jonathan's test suite to **76 / 76 passing** (`57.9%` coverage across `lib/app`, `lib/shared`, `lib/features/home`, and `lib/features/admin`; `37.6%` across instrumented repo files).

## Verification after latest update

- `dart format` (on Jonathan-scope updated Dart files in `jonathan-updates/`): `37 files`, clean.
- `flutter analyze --no-pub` (staged verification copy combining `main` `d8785ba` + `jonathan-updates`): **No issues found**.
- `flutter test --no-pub --coverage --reporter expanded test/app test/core test/shared test/features/home test/features/admin test/widget_test.dart`: **76 passed, 0 failures**.
- `flutter test --no-pub --reporter compact` (full repo): **101 passed, 3 failed** (all 3 failures pre-existing from PR #5 on `main`).
- `.gitignore`: ignores `analysis-output.txt`.

## Outstanding (Team / Pre-deployment)

- **Firebase Auth custom claims & Console setup**: Provision `{ "role": "admin" | "mentor" }` custom claims via Admin SDK / Cloud Function, and enable Email/Password auth in Firebase Console.
- **Teammate merges & cleanups**:
  - **Lisa**: Fix the 3 failing PR #5 widget tests/overflows on `main` (`portfolio_screen.dart` lines 64 & 173; `learning_screens_test.dart:42`; `portfolio_screens_test.dart:89`) and confirm `projects` top-level vs `users/{uid}/projects` + `taskProgress` / `submissions` schemas.
  - **Ghislaine (`feature/auth-profile`)**: Reconcile `verify_email_screen.dart` & `app_store.dart` (`setFirebaseProfile`) on merge and remove obsolete SMS reset screens (`verify_code_screen.dart`, `new_password_screen.dart`) + `/verify`, `/new-password` routes once merged.
  - **Boaz (`feature/mentorship-requests`, `feature/mentor-workspace`) & Kellen (`feature/opportunities-applications`)**: Verify `firestore.rules` with `.\scripts\test_firebase_emulator_rules.ps1` once their branches merge.
