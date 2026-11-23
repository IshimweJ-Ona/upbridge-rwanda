# Developer Integration Guide

## Shared Architecture & Providers (Post-Rework Baseline)

- `main()` initializes Firebase via `initFirebase()` (`lib/shared/services/firebase/firebase_bootstrap.dart`) and renders `FirebaseUnavailableApp` if startup fails.
- Shared auth, claims, and session state live in:
  - `lib/shared/services/firebase/firebase_providers.dart` (`firebaseAuthProvider`, `firestoreProvider`)
  - `lib/core/providers/session_providers.dart` (`appSessionProvider`, `resolveEffectiveRole`)
  - `lib/core/providers/repository_providers.dart` & `lib/core/providers/live_data_providers.dart`
- Schema constants and allowed status lifecycles are centralized in `lib/core/constants/firestore_schema.dart` (`Fs`) and `lib/core/domain/status_lifecycle.dart` (`StatusTransitions`). Never duplicate collection names or raw status literals.
- UI screens use shared Material 3 primitives from `lib/shared/shared.dart` (`PageFrame`, `DetailPage`, `SurfaceCard`, `ListGroup`, `AppButton`, `AppSearchField`, `MetricsGrid`, `StatusBadge`).
- All media uploads run directly from the client to **Cloudinary Free** (`vbzq5ssu` / `upbridge_public_images`) via `CloudinaryMediaService`. No Cloud Functions (`functions/`) or paid Firebase Blaze features are used.

---

## Local Setup

1. Clone the repository and fetch dependencies:
   ```powershell
   git checkout main
   git pull origin main
   flutter pub get
   flutter gen-l10n
   ```
2. Keep local config files out of Git (already listed in `.gitignore`): `.env`, `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleServiceInfo.plist`. Fresh clones compile and pass `flutter analyze` / `flutter test` without them; for live `flutter run`, either obtain `android/app/google-services.json` (and `ios/Runner/GoogleServiceInfo.plist` for iOS) from your team lead, or copy `.env.example` to `.env` and run `flutter run --dart-define-from-file=.env`.
3. Read `docs/firebase-setup.md`, `docs/cloudinary-setup.md`, and `docs/firestore-schema.md`.
4. To test against local Firebase Emulators:
   ```powershell
   .\scripts\start_firebase_emulators.ps1
   flutter run --dart-define=USE_FIREBASE_EMULATORS=true
   ```
5. To deploy Firestore security rules and composite indexes to `upridge-rwanda-dev`:
   ```powershell
   firebase deploy --only firestore:rules,firestore:indexes --project upridge-rwanda-dev
   ```

---

## Team Pull & Push Workflow (After `test/rework-v2` Merges to `main`)

Because `test/rework-v2` refactored feature modules into `lib/features/<feature>/{data,domain,presentation}/` and replaced legacy demo repositories and screens, **everyone must base new work off the updated `main`**.

### Standard Update Flow (For All Teammates)
1. Save/commit any local uncommitted work on your current branch.
2. Fetch and start a clean branch from updated `main`:
   ```powershell
   git fetch origin
   git checkout main
   git pull origin main
   git checkout -b feature/<your-topic>
   ```
3. Before pushing or opening a Pull Request to `main`, run all checks locally:
   ```powershell
   flutter pub get
   flutter gen-l10n
   flutter analyze
   flutter test --reporter compact
   flutter test -d flutter-tester integration_test/app_flows_test.dart --reporter compact
   ```
4. Push your branch and open a Pull Request into `main`:
   ```powershell
   git push -u origin feature/<your-topic>
   ```

---

## Per-Developer Branch Status & Handoff Actions

| Teammate | Feature Ownership | Current Branch Status vs `main` | What to Pull & Push |
|---|---|---|---|
| **Jonathan** | Core routing (`app_router.dart`, `route_guards.dart`), Spark `firestore.rules`, Admin Overview/Users/Catalog/Settings, CI/docs | `feature/jonathan-engineering-execution` already merged into `main` | Merge `test/rework-v2` -> `main` first, deploy `firestore.rules` + `firestore.indexes.json`, then coordinate PR reviews into `main`. |
| **Ghislaine** | Auth, Signup/Login, Email Verification, Onboarding, User Profile & CV | `feature/auth-profile` already merged into `main`; rework wired Auth, Verification, Onboarding & Profile to live Firestore | Pull `origin/main` into a fresh branch if making further Auth/Profile/CV updates, verify tests, then push PR -> `main`. |
| **Lisa** | Learning (`courses`, `courseProgress`), Course Detail/Evidence & Portfolio Projects (`projects`) | `feature/learning-portfolio-screens` and `feauture/lisa-learning-submissions-progress-portfolio` already merged into `main`; rework completed live `courses`/`projects` repos & UI | Pull `origin/main` into a fresh branch for any new Learning/Portfolio enhancements, verify tests, then push PR -> `main`. |
| **Boaz** | Mentors Discovery, Mentorship Requests, Mentorship Workspace, Sessions & Mentor Dashboard | `origin/feature/mentor-workspace`, `origin/feature/mentorship-requests`, `origin/feature/mentorship-data-layer`, and `origin/feature/mentorship-rules` still have older pre-rework commits | **Do not merge old branches straight into `main`.** Pull updated `origin/main` onto a fresh branch (`feature/mentor-followups`), check whether any slot/session logic from your old branch is still needed on top of `main`, cherry-pick or port only what is missing into `lib/features/mentorship/` or `lib/features/mentor_workspace/`, run checks, and push PR -> `main`. |
| **Kellen** | Opportunities & Applications | `origin/feature/opportunities-applications` still has pre-rework commits | **Do not merge the old branch straight into `main`.** Pull updated `origin/main` onto a fresh branch (`feature/opportunities-followups`), verify if any application-history/filter behavior from your old branch is still needed beyond what `main` already has, port only missing logic into `lib/features/opportunities/`, run checks, and push PR -> `main`. |
