# UpBridge Rwanda

**A career development platform connecting young people in Rwanda with learning opportunities, mentors, and career pathways.**

UpBridge Rwanda is a Flutter application designed to help young people build practical skills, develop professional portfolios, connect with mentors, and discover opportunities that support their career growth.

The project is being developed collaboratively by a team of five students using a feature-based architecture.

> **Project status:** This repository currently contains the Flutter application prototype and its UI structure. Some features still use demonstration data. Firebase integration, authentication workflows, Firestore operations, and production configuration are not yet fully implemented or verified. Do not treat the current application as production-ready.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Main Features](#main-features)
- [Technology Stack](#technology-stack)
- [Project Architecture](#project-architecture)
- [Getting Started](#getting-started)
- [Firebase Configuration](#firebase-configuration)
- [Development Workflow](#development-workflow)
- [Team Responsibilities](#team-responsibilities)
- [Code Guidelines](#code-guidelines)
- [Testing and Verification](#testing-and-verification)
- [Security Guidelines](#security-guidelines)
- [Project Status and Limitations](#project-status-and-limitations)
- [Contributing](#contributing)

---

## Project Overview

UpBridge Rwanda aims to provide a central platform where young people can:

- Improve their professional and technical skills.
- Access structured learning activities.
- Build and showcase portfolios.
- Receive guidance from experienced mentors.
- Discover internships, jobs, and other career opportunities.
- Track applications and learning progress.

The application is organized around different user roles, including learners, mentors, and administrators.

The long-term goal is to develop a reliable, accessible, and maintainable platform that supports youth career development in Rwanda.

---

## Main Features

The application is organized into the following feature areas:

| Feature | Description |
|---|---|
| Authentication and onboarding | User registration, sign-in, and onboarding experiences. |
| User profiles | Personal information and professional profile management. |
| Learning | Learning activities, progress tracking, and educational content. |
| Submissions | Submission and review of learning activities or projects. |
| Portfolio | Showcasing completed projects, skills, and achievements. |
| Mentorship | Connecting learners with mentors and supporting mentorship activities. |
| Opportunities | Discovering career opportunities such as internships and jobs. |
| Applications | Managing applications for available opportunities. |
| Notifications | Keeping users informed about relevant activities and updates. |
| Administration | Administrative views and platform management features. |

**Note:** The presence of a screen or UI flow does not necessarily mean its backend functionality is complete. Some features currently use local demonstration data.

---

## Technology Stack

The project uses the following technologies and packages:

- **Flutter** — cross-platform application development.
- **Dart** — application programming language.
- **Riverpod** — state management.
- **GoRouter** — application navigation and routing.
- **Firebase Core** — Firebase initialization.
- **Firebase Authentication** — planned authentication integration.
- **Cloud Firestore** — planned cloud database integration.

Other dependencies are listed in `pubspec.yaml`.

---

## Project Architecture

The project follows a feature-based structure to separate responsibilities and make collaboration easier.

```text
lib/
├── app/
│   ├── router/
│   ├── theme/
│   └── ...
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── services/
│   ├── utils/
│   └── ...
│
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
│
├── shared/
│   ├── services/
│   ├── widgets/
│   └── ...
│
└── main.dart

test/
└── widget_test.dart
```

The structure above illustrates the intended organization. Refer to the actual repository for the current folders and files.

### Architectural principles

- Keep feature-specific code inside its corresponding feature folder.
- Keep reusable application-wide widgets in `shared/widgets`.
- Keep shared services and infrastructure in appropriate shared or core locations.
- Separate presentation, business logic, and data access where applicable.
- Use Riverpod for state management.
- Use GoRouter for navigation.
- Avoid duplicating shared functionality across feature modules.

---

## Getting Started

### Prerequisites

Before running the project, install:

1. [Flutter SDK](https://docs.flutter.dev/get-started/install)
2. [Dart SDK](https://dart.dev/get-dart) compatible with the constraint in `pubspec.yaml`.
3. [Git](https://git-scm.com/downloads)
4. [Android Studio](https://developer.android.com/studio) or Visual Studio Code.
5. An Android emulator or a physical device.

For iOS development, a Mac with Xcode is required.

Check your Flutter installation:

```bash
flutter doctor
```

### 1. Clone the repository

```bash
git clone https://github.com/IshimweJ-Ona/upbridge-rwanda.git
```

Navigate into the project:

```bash
cd upbridge-rwanda
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Check the project

```bash
flutter analyze
```

### 4. Run the application

Start an emulator or connect a device, then run:

```bash
flutter devices
flutter run
```

If the application requires Firebase configuration or other local setup that is not included in the repository, follow the instructions in the Firebase Configuration section or contact the project integration lead.

---

## Firebase Configuration

Firebase is intended to provide backend services for the application. However, the current repository still requires Firebase configuration and integration work.

The Firebase project intended for this application is:

```text
upridge-rwanda-dev
```

**Important:** Do not assume that Firebase is fully configured just because Firebase dependencies or initialization code exist in the project.

Before using Firebase:

1. Confirm that the project lead has provided access to the correct Firebase project.
2. Confirm that the Firebase project ID is `upridge-rwanda-dev`.
3. Confirm that the FlutterFire configuration files and their import paths are correct.
4. Confirm that the Android and iOS applications are registered with the correct application identifiers.
5. Confirm that the required Firebase services are enabled.
6. Follow the integration lead's instructions before changing shared Firebase configuration.

### Firebase CLI

If the integration lead has approved Firebase CLI access, install and authenticate the Firebase CLI:

```bash
firebase login
```

Check the available projects:

```bash
firebase projects:list
```

Do not create a new Firebase project or deploy Firestore rules or indexes without approval from the project lead.

### Local configuration files

Some Firebase configuration files contain project-specific information and may be excluded from Git.

Do not commit:

- Private service account keys.
- Firebase Admin SDK credentials.
- Local environment files containing secrets.
- Signing keys or passwords.
- Personal access tokens.

Ask the integration lead for the approved configuration process if a required local file is missing.

---

## Development Workflow

All contributors should follow the same Git workflow to reduce conflicts and keep the `main` branch stable.

### Branch strategy

- `main` — stable and reviewed project baseline.
- `feature/*` — new features and assigned development work.
- `fix/*` — bug fixes.
- `docs/*` — documentation changes.

Example:

```bash
git checkout main
git pull origin main
git checkout -b feature/UB-AUTH
```

Use a branch name that identifies your assigned task.

### Before starting work

Always update your local `main` branch:

```bash
git checkout main
git pull origin main
```

Create your own branch:

```bash
git checkout -b feature/your-task-name
```

### While working

Check your changes:

```bash
git status
flutter analyze
```

Run relevant tests:

```bash
flutter test
```

Commit your work using clear messages:

```bash
git add .
git commit -m "feat: implement assigned feature"
```

Push your branch:

```bash
git push -u origin feature/your-task-name
```

### Pull requests

1. Push your feature branch to GitHub.
2. Open a pull request targeting `main`.
3. Explain what you implemented.
4. List the important files changed.
5. Mention any known issues or incomplete work.
6. Request a review from the integration lead.
7. Merge only after review and approval.

**Do not push unfinished work directly to `main`.**

---

## Team Responsibilities

The project is divided into five workstreams.

| Team member | Responsibility | Main areas |
|---|---|---|
| Student 1 | Authentication and user management | Authentication, onboarding, profiles |
| Student 2 | Learning and portfolio | Learning activities, submissions, portfolio |
| Student 3 | Mentorship | Mentor and learner mentorship workflows |
| Student 4 | Career opportunities | Opportunities and applications |
| Student 5 | Core and integration | App shell, shared components, administration, configuration, integration |

The team should agree on the exact ownership of files before implementation begins.

### Shared development responsibilities

Every contributor should:

- Work only on assigned feature areas unless collaboration is agreed upon.
- Communicate before modifying shared files.
- Reuse shared widgets and services where appropriate.
- Avoid changing another contributor's files without coordination.
- Keep their branch updated with approved changes from `main`.
- Test their changes before opening a pull request.

---

## Code Guidelines

To maintain consistency:

1. Follow the existing folder structure.
2. Use descriptive file, class, and variable names.
3. Keep widgets focused and reusable.
4. Avoid putting all application logic inside screen widgets.
5. Use Riverpod consistently for state management.
6. Use GoRouter for navigation.
7. Avoid hardcoding repeated values; use shared constants where appropriate.
8. Handle loading, success, empty, and error states.
9. Do not commit generated build files or local machine configuration.
10. Do not introduce new dependencies without checking with the team.

Before changing an existing architecture or shared API, discuss the change with the integration lead.

---

## Testing and Verification

Run the following commands before submitting changes:

### Analyze the project

```bash
flutter analyze
```

### Run tests

```bash
flutter test
```

### Check connected devices

```bash
flutter devices
```

### Run the application

```bash
flutter run
```

Report any command that fails and include the relevant error message in your pull request.

A successful dependency installation or static analysis does not automatically prove that every application workflow works.

---

## Security Guidelines

Protect the project and its users by following these rules:

- Never commit passwords, access tokens, API secrets, or private keys.
- Never share personal Firebase credentials with other contributors.
- Each contributor should use their own authorized account.
- Do not share Firebase Owner access unnecessarily.
- Use the minimum permissions required for assigned work.
- Do not deploy database rules or modify production data without approval.
- Do not expose private user information in logs, screenshots, or commits.
- Review staged files before committing.

---

## Project Status and Limitations

The repository is an active development project.

The following areas require verification or further implementation:

- Complete Firebase initialization and configuration.
- Functional authentication connected to Firebase Authentication.
- Firestore integration for application data.
- Consistent data models, repositories, and service implementations.
- Firestore security rules and required indexes.
- Missing or uncommitted application assets.
- Correct platform application identifiers.
- Automated tests for important application workflows.
- Updated documentation and setup instructions.

Features should only be described as complete after their implementation and behavior have been tested.

---

## Contributing

We welcome contributions from the assigned project team.

To contribute:

1. Read this README.
2. Understand your assigned feature and file ownership.
3. Pull the latest approved `main` branch.
4. Create a feature branch.
5. Implement and test your changes.
6. Commit and push your branch.
7. Open a pull request for review.

For questions about architecture, Firebase configuration, shared files, or integration, contact the project integration lead.

---

## Repository

GitHub: [https://github.com/IshimweJ-Ona/upbridge-rwanda](https://github.com/IshimweJ-Ona/upbridge-rwanda)

**UpBridge Rwanda — Building skills, connecting talent, and creating opportunities.**