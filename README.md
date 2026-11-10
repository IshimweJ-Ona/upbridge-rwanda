# UpBridge Rwanda

A career development platform that connects young people in Rwanda with learning opportunities, mentors, and career pathways.

UpBridge Rwanda is a Flutter application that helps young people build practical skills, develop professional portfolios, connect with mentors, and discover opportunities for career growth. It is developed by a team of five students using a feature-based architecture.

> **Project status:** This repository contains the Flutter application prototype and its UI structure. Some features use demonstration data. Firebase integration, authentication workflows, Firestore operations, and production configuration are not yet fully implemented or verified. The application is not production-ready.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Firebase Configuration](#firebase-configuration)
- [Development Workflow](#development-workflow)
- [Team Responsibilities](#team-responsibilities)
- [Code Guidelines](#code-guidelines)
- [Testing and Verification](#testing-and-verification)
- [Security](#security)
- [Project Status and Limitations](#project-status-and-limitations)
- [Contributing](#contributing)

## Overview

UpBridge Rwanda provides a central platform where young people can:

- Improve their professional and technical skills
- Access structured learning activities
- Build and showcase portfolios
- Receive guidance from experienced mentors
- Discover internships, jobs, and other career opportunities
- Track applications and learning progress

The application supports three user roles: learners, mentors, and administrators. The long-term goal is a reliable, accessible, and maintainable platform for youth career development in Rwanda.

## Features

| Feature | Description |
|---|---|
| Authentication and onboarding | Registration, sign-in, and onboarding flows |
| User profiles | Personal information and professional profile management |
| Learning | Learning activities, progress tracking, and educational content |
| Submissions | Submission and review of learning activities and projects |
| Portfolio | Showcase of completed projects, skills, and achievements |
| Mentorship | Connecting learners with mentors and supporting mentorship activities |
| Opportunities | Discovery of internships, jobs, and other opportunities |
| Applications | Management of applications to available opportunities |
| Notifications | Updates on relevant activities |
| Administration | Administrative views and platform management |

> **Note:** The presence of a screen or UI flow does not mean its backend functionality is complete. Some features currently use local demonstration data.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application framework |
| Dart | Programming language |
| Riverpod | State management |
| GoRouter | Navigation and routing |
| Firebase Core | Firebase initialization |
| Firebase Authentication | Authentication (planned) |
| Cloud Firestore | Cloud database (planned) |

Additional dependencies are listed in `pubspec.yaml`.

## Architecture

The project uses a feature-based structure to separate responsibilities and ease collaboration.

```text
lib/
├── app/
│   ├── router/
│   ├── theme/
│   └── ...
├── core/
│   ├── constants/
│   ├── errors/
│   ├── services/
│   ├── utils/
│   └── ...
├── features/
│   ├── auth/
│   ├── learning/
│   ├── submissions/
│   ├── portfolio/
│   ├── mentorship/
│   ├── opportunities/
│   ├── applications/
│   ├── notifications/
│   └── admin/
├── shared/
│   ├── services/
│   ├── widgets/
│   └── ...
└── main.dart

test/
└── widget_test.dart
```

This structure shows the intended organization. Refer to the repository for the current layout.

### Principles

- Keep feature-specific code inside its feature folder.
- Place reusable application-wide widgets in `shared/widgets`.
- Place shared services and infrastructure in `shared` or `core`.
- Separate presentation, business logic, and data access where applicable.
- Use Riverpod for state management and GoRouter for navigation.
- Avoid duplicating shared functionality across features.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) compatible with the constraint in `pubspec.yaml`
- [Git](https://git-scm.com/downloads)
- [Android Studio](https://developer.android.com/studio) or Visual Studio Code
- An Android emulator or physical device
- For iOS development: a Mac with Xcode

Verify your Flutter installation:

```bash
flutter doctor
```

### Installation

1. Clone the repository and enter the project directory:

   ```bash
   git clone https://github.com/IshimweJ-Ona/upbridge-rwanda.git
   cd upbridge-rwanda
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Analyze the project:

   ```bash
   flutter analyze
   ```

4. Run the application on an emulator or connected device:

   ```bash
   flutter devices
   flutter run
   ```

If the application requires Firebase configuration or local setup not included in the repository, follow the [Firebase Configuration](#firebase-configuration) section or contact the integration lead.

## Firebase Configuration

Firebase is intended to provide backend services, but integration is incomplete. The presence of Firebase dependencies or initialization code does not mean Firebase is fully configured.

Target Firebase project:

```text
upridge-rwanda-dev
```

Before using Firebase:

1. Confirm the project lead has granted you access to the correct project.
2. Confirm the project ID is `upridge-rwanda-dev`.
3. Confirm the FlutterFire configuration files and their import paths are correct.
4. Confirm the Android and iOS apps are registered with the correct application identifiers.
5. Confirm the required Firebase services are enabled.
6. Follow the integration lead's instructions before changing shared Firebase configuration.

### Firebase CLI

With approval from the integration lead, authenticate the Firebase CLI:

```bash
firebase login
firebase projects:list
```

Do not create a new Firebase project or deploy Firestore rules or indexes without project lead approval.

### Local configuration files

Some Firebase configuration files contain project-specific information and may be excluded from Git. Never commit:

- Private service account keys
- Firebase Admin SDK credentials
- Local environment files containing secrets
- Signing keys or passwords
- Personal access tokens

If a required local file is missing, ask the integration lead for the approved configuration process.

## Development Workflow

All contributors follow the same Git workflow to reduce conflicts and keep `main` stable.

### Branch strategy

| Branch | Purpose |
|---|---|
| `main` | Stable, reviewed project baseline |
| `feature/*` | New features and assigned development work |
| `fix/*` | Bug fixes |
| `docs/*` | Documentation changes |

### Starting work

```bash
git checkout main
git pull origin main
git checkout -b feature/your-task-name
```

Use a branch name that identifies your assigned task, for example `feature/UB-AUTH`.

### During development

```bash
git status
flutter analyze
flutter test
```

Commit with clear messages:

```bash
git add .
git commit -m "feat: implement assigned feature"
git push -u origin feature/your-task-name
```

### Pull requests

1. Push your feature branch to GitHub.
2. Open a pull request targeting `main`.
3. Describe what you implemented.
4. List the important files changed.
5. Note any known issues or incomplete work.
6. Request a review from the integration lead.
7. Merge only after review and approval.

> **Do not push unfinished work directly to `main`.**

## Team Responsibilities and Task Ownership

The UpBridge Rwanda project is developed by five team members. Each member is responsible for specific features and tasks on the Scrum board.

| Team member | Assigned responsibilities | Main tasks |
|---|---|---|
| Jonathan Ishimwe | Project setup and integration | Repository setup, package configuration, Firebase setup, architecture, shared widgets, home dashboard, administration, and final integration/release. |
| Ghislaine Marie Inez | Authentication and user management | User registration, email/password login, logout, onboarding, authentication flows, and user profiles. |
| Lisa Ineza | Learning and portfolio | Learning paths, learning activities, submissions, progress tracking, and portfolio management. |
| Boaz Prince Iza | Mentorship | Mentor workspace, mentorship requests, mentor reviews, and mentorship sessions. |
| Kellen Ashley Mutoni | Career opportunities | Opportunities discovery, opportunity details, applications, and application management. |

### Individual ownership

**1. Jonathan Ishimwe — Project Setup and Integration**

- Repository and GitHub management.
- Flutter project configuration and dependencies.
- Firebase project configuration and integration.
- Application architecture and shared infrastructure.
- Shared widgets and application shell.
- Home dashboard and administration.
- Integration, testing, and release coordination.

**2. Ghislaine Marie Inez — Authentication and User Management**

- Email/password registration.
- User login and logout.
- Authentication validation and error handling.
- Onboarding workflows.
- User profile management.

**3. Lisa Ineza — Learning and Portfolio**

- Learning paths and learning content.
- Learning progress tracking.
- Assignment and project submissions.
- Submission management.
- Portfolio creation and management.

**4. Boaz Prince Iza — Mentorship**

- Mentor discovery and profiles.
- Mentorship requests.
- Mentor workspace.
- Mentor reviews and feedback.
- Mentorship session management.

**5. Kellen Ashley Mutoni — Opportunities and Applications**

- Career opportunities listing.
- Opportunity details.
- Opportunity search and filtering.
- Application submission.
- Application tracking and management.

### Collaboration rules

- Each member should primarily work on their assigned feature area.
- Shared files must be coordinated with Jonathan Ishimwe.
- All members should create feature branches and submit pull requests.
- No member should push unfinished work directly to `main`.
- Changes affecting multiple features must be communicated before implementation.
- All completed tasks should be reflected on the Scrum board.

## Code Guidelines

1. Follow the existing folder structure.
2. Use descriptive file, class, and variable names.
3. Keep widgets focused and reusable.
4. Keep application logic out of screen widgets.
5. Use Riverpod consistently for state management.
6. Use GoRouter for navigation.
7. Use shared constants instead of hardcoding repeated values.
8. Handle loading, success, empty, and error states.
9. Do not commit generated build files or local machine configuration.
10. Do not add new dependencies without team agreement.

Discuss changes to existing architecture or shared APIs with the integration lead before implementing them.

## Testing and Verification

Run these commands before submitting changes:

```bash
flutter analyze
flutter test
flutter devices
flutter run
```

Report any failing command, including the relevant error output, in your pull request. Successful dependency installation or static analysis does not prove that every workflow works.

### Firebase emulators

The local Auth and Firestore emulators are configured on ports `9099` and `8080`:

```bash
firebase emulators:start --only auth,firestore
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

The Emulator UI is available on port `4000`. Emulator mode is debug-only and does not connect to production. See [`docs/firebase-setup.md`](docs/firebase-setup.md), [`docs/firestore-schema.md`](docs/firestore-schema.md), and [`docs/integration-guide.md`](docs/integration-guide.md). Do not deploy rules or indexes without project lead approval.

Email verification is required by the shared Firestore rules. Firebase Console must have Email/Password sign-in enabled and a configured verification email template. The app-level verification screen is in place; the current signup/login screens still use demo state and must be connected by the authentication owner before real users can complete onboarding.

## Security

- Never commit passwords, access tokens, API secrets, or private keys.
- Never share personal Firebase credentials with other contributors.
- Use your own authorized account.
- Do not share Firebase Owner access unnecessarily.
- Use the minimum permissions required for your work.
- Do not deploy database rules or modify production data without approval.
- Do not expose private user information in logs, screenshots, or commits.
- Review staged files before committing.

## Project Status and Limitations

The repository is under active development. The following areas require implementation or verification:

- [ ] Complete Firebase initialization and configuration
- [ ] Functional authentication with Firebase Authentication
- [ ] Firestore integration for application data
- [ ] Consistent data models, repositories, and services
- [ ] Firestore security rules and required indexes
- [ ] Missing or uncommitted application assets
- [ ] Correct platform application identifiers
- [ ] Automated tests for key workflows
- [ ] Updated documentation and setup instructions

A feature should be described as complete only after its implementation has been tested.

## Contributing

Contributions are open to the assigned project team.

1. Read this README.
2. Understand your assigned feature and file ownership.
3. Pull the latest approved `main` branch.
4. Create a feature branch.
5. Implement and test your changes.
6. Commit and push your branch.
7. Open a pull request for review.

For questions about architecture, Firebase configuration, shared files, or integration, contact the project integration lead.

## Repository

[github.com/IshimweJ-Ona/upbridge-rwanda](https://github.com/IshimweJ-Ona/upbridge-rwanda)

---

**UpBridge Rwanda: building skills, connecting talent, and creating opportunities.**
