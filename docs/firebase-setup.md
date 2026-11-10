# Firebase setup

The configured project is `upridge-rwanda-dev`. The existing FlutterFire registrations are Android `com.example.upbridge`, iOS `com.example.upbridge`, and web. The Firebase CLI verified these registrations and the default Firestore database (`nam5`). No project settings were changed.

## Local prerequisites

- Flutter/Dart versions allowed by `pubspec.yaml`.
- Firebase CLI and Java for the Emulator Suite.
- Individual Firebase Console access granted by the project lead.
- Project-specific platform files supplied through the team's approved process.

Run `flutter pub get`. Local `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are ignored by Git. Do not create or share service-account keys. The Dart options contain client identifiers, not privileged credentials.

## Email verification requirement

Firebase Auth must have the **Email/Password** provider enabled in the existing project (`Authentication → Sign-in method`). The default Firebase Auth verification template sends the link; configure its sender name and continue URL in `Authentication → Templates`, and make sure the continue URL's host is an authorized domain. The app calls `User.sendEmailVerification()`, reloads the Firebase user after the link is clicked, and refreshes the ID token. Firestore rules require the verified-email token claim. These Console settings have not been changed or verified in this pass.

The current auth screens still use the demo store and phone-based UI. Ghislaine must connect signup/login to Firebase Email/Password and navigate a newly created user to `/verify-email`; until then, the real account flow is not usable end to end. Do not turn demo login into a production bypass.

Start local Auth and Firestore emulators with `firebase emulators:start --only auth,firestore`. The configured ports are Auth `9099`, Firestore `8080`, and Emulator UI `4000`. To connect a debug Flutter run, pass `--dart-define=USE_FIREBASE_EMULATORS=true`. Android emulators use `10.0.2.2`; other debug platforms use loopback. This switch is ignored in release builds.

Stop emulators with Ctrl+C. Restarting without an export directory clears emulator data. Never point emulator or integration-test data at the production project.

## Project access

Ask the Firebase project owner to invite each developer from **Project settings → Users and permissions** using their own Google account. Grant only the project permissions needed for their assigned tasks. A Firebase collaborator is a Console/IAM identity; an Authentication user is an app account; `youth`, `mentor`, and `admin` are separate application roles. Admin application roles must be assigned through trusted custom claims, never by a client profile edit.

Verify configuration with `firebase projects:list`, `firebase apps:list --project upridge-rwanda-dev`, and `firebase firestore:databases:list --project upridge-rwanda-dev`. Do not deploy rules or indexes without project lead approval.

## Current blockers

The CLI can see registered apps and Firestore, but enabled Authentication providers and Storage configuration were not verified. Platform native config files are not committed. Ask the project owner for approved local config and confirm enabled providers before live sign-in work. Firebase Storage is not currently a Flutter dependency.
