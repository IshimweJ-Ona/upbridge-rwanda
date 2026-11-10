# Developer integration guide

## Shared startup and providers

`main()` awaits `initFirebase()` before creating the app and fails closed if Firebase cannot initialize. Use `firebaseAuthProvider`, `firestoreProvider`, `authServiceProvider`, `authStateProvider`, and `repositoryProvider` from `lib/shared/services/firebase/firebase_providers.dart`. `AuthService` exposes current user, auth-state changes, email verification send/reload, and sign-out; it does not create anonymous accounts or implement login/signup. The shared router redirects a signed-in unverified Firebase user to `/verify-email`; the screen sends/resends the Firebase verification email, reloads the account and refreshes the ID token before leaving the gate.

Use the shared Firebase providers for injectable dependencies. Keep feature interfaces, entities, repositories, screens, and feature-specific tests in the owning developer's feature directory. Do not edit another owner's feature to register integrations; coordinate shared route changes with Jonathan. Use the shared `Fs` collection names, `SubmissionStatus`, and `OpportunityStatus` constants rather than duplicating literals.

Before introducing fields or status values, update the contract with Jonathan and record purpose, document ID, owner, data types, timestamps, validation, permitted transitions, and security access. Do not use client profile fields to grant admin permissions. Use `AppStore` only for clearly marked demonstration data; never mix it with Firebase records or present its counts as live platform data.

## Team onboarding

1. Clone the repository and run `flutter pub get`.
2. Request your own Firebase Console access from the project owner; never share accounts or service keys.
3. Obtain Android/iOS native Firebase files through the approved team process; they are ignored locally.
4. Read `firebase-setup.md`, this guide, and `firestore-schema.md`.
5. Run `firebase emulators:start --only auth,firestore`; launch with `flutter run --dart-define=USE_FIREBASE_EMULATORS=true` when testing Firebase integration.
6. Create test accounts only in the emulator or through the approved Firebase Auth process. Application role claims require trusted provisioning.
7. Implement only your assigned feature and consume shared providers/contracts.
8. Add feature-owned tests, run `flutter analyze` and `flutter test`, and open a pull request for review.

## Handoffs

- **Ghislaine:** Owns login, registration, onboarding, and profile workflows. Current screens still use phone/demo state and are not connected to Firebase; wire signup/login to Firebase Email/Password accounts and let the shared router send new unverified accounts to `/verify-email`. On later sign-in, check `emailVerified` and reload the Firebase user before opening app routes. Consume shared Auth state/sign-out; provision app roles through trusted claims. Confirm profile fields with the `users` rule allowlist before writes. Firestore denies unverified users even if a client route is bypassed. Until this handoff is implemented, end-to-end signup/login is not complete.
- **Lisa:** Owns learning, submissions, and portfolio. Confirm learning catalog, task progress, submission/review contracts, and mentor read access; use the shared collection/status constants where applicable. Resolve the portfolio path discrepancy (`users/{uid}/projects` in the feature data-source note vs. top-level `projects/{id}` with `ownerId` in the shared repository) before enabling writes.
- **Boaz:** Owns mentor discovery, workspace, requests, reviews, and sessions. Confirm mentor identity linkage and least-privilege review/session access before implementation.
- **Kellen:** Owns opportunities and applications. Confirm publication/moderation and application state transitions; current opportunity query index is supplied in the shared index file.

Shared route registration and changes to shared rules/indexes are coordinated with Jonathan. Feature owners retain their source and test files.
