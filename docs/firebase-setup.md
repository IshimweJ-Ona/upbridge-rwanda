# Firebase setup

The configured project ID is `upridge-rwanda-dev`. It matches `firebase.json`,
the local Android configuration, and the FlutterFire Android/iOS/web options.
The local Android package is `com.example.upbridge`. Android configuration and
`lib/firebase_options.dart` are ignored by Git; the Android file is present in
this checkout. The iOS `GoogleService-Info.plist` is absent locally, so iOS
native builds need the approved file from the project owner. FlutterFire options
do not currently configure Windows, macOS, or Linux desktop.

There is no `.firebaserc`; Firebase CLI commands must name the project to avoid
relying on a developer's implicit project selection. Keep local work on the
development project and never deploy rules or indexes without project-lead
approval.

## Local prerequisites

- Flutter/Dart versions allowed by `pubspec.yaml`.
- Firebase CLI and Java for the Emulator Suite.
- Individual Firebase Console access granted by the project lead.
- Project-specific platform files supplied through the team's approved process.

Run `flutter pub get`. Local `android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist` are ignored by Git. Do not create or share
service-account keys. The Dart options contain client identifiers, not
privileged credentials.

## Email verification requirement

Firebase Auth must have the **Email/Password** provider enabled in the existing project (`Authentication → Sign-in method`). The default Firebase Auth verification template sends the link; configure its sender name and continue URL in `Authentication → Templates`, and make sure the continue URL's host is an authorized domain. The app calls `User.sendEmailVerification()`, reloads the Firebase user after the link is clicked, and refreshes the ID token. Firestore rules require the verified-email token claim. These Console settings have not been changed or verified in this pass.

The current auth screens still use the demo store and phone-based UI. Ghislaine must connect signup/login to Firebase Email/Password and navigate a newly created user to `/verify-email`; until then, the real account flow is not usable end to end. Do not turn demo login into a production bypass.

Start the Auth and Firestore emulators on Windows from the repository root with
`.\scripts\start_firebase_emulators.ps1`. The helper selects an installed
Node version directly when NVM is present and explicitly uses
`upridge-rwanda-dev`, matching the Flutter app. On other platforms, run
`firebase emulators:start --project upridge-rwanda-dev --only auth,firestore`.
The configured ports are Auth `9099`, Firestore `8080`, and Emulator UI `4000`.
In another terminal, launch Flutter with
`flutter run --dart-define=USE_FIREBASE_EMULATORS=true`. Android emulators use
`10.0.2.2`; desktop and simulators default to `127.0.0.1`. A physical phone must
use the development computer's reachable LAN address, for example:
`flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=192.168.1.12`.
Replace that example with the computer's current LAN address and allow the
emulator ports through the local firewall. Emulator settings are debug-only;
the switch is ignored in release builds.

Stop emulators with Ctrl+C. Restarting without an export directory clears emulator data. Never point emulator or integration-test data at the production project.

## Project access

Ask the Firebase project owner to invite each developer from **Project settings → Users and permissions** using their own Google account. Grant only the project permissions needed for their assigned tasks. A Firebase collaborator is a Console/IAM identity; an Authentication user is an app account; `youth`, `mentor`, and `admin` are separate application roles. Admin application roles must be assigned through trusted custom claims, never by a client profile edit.

Verify configuration with `firebase projects:list`, `firebase apps:list --project upridge-rwanda-dev`, and `firebase firestore:databases:list --project upridge-rwanda-dev`. Do not deploy rules or indexes without project lead approval.

## Current blockers

The local emulator startup and Firestore rules parsing were verified on
13 Nov 2026 with Firebase CLI 15.35.0 and Java 21. Enabled Authentication
providers, verification-email template settings, and Storage configuration
remain unverified in Firebase Console. Confirm Email/Password before live
sign-in work. Firebase Storage is not currently a Flutter dependency. The
Firebase CLI project-list commands below are read-only; do not run deploy
commands as part of local setup.
