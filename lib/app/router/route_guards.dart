// Keeps email-verification redirect policy separate and easy to test.

import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/core/constants/app_routes.dart';

/// Resolves the launch destination using the same auth and role state as routing.
String splashDestination({
  required bool firebaseInitialized,
  required bool firebaseSignedIn,
  required bool emailVerified,
  required AppUser? appUser,
}) {
  if (firebaseInitialized) {
    if (!firebaseSignedIn) return '/welcome';
    if (!emailVerified) return '/verify-email';
    if (appUser == null) return '/welcome';
  }

  if (appUser == null) return '/welcome';
  if (!appUser.onboarded) return '/onboarding/goal';
  return appUser.role.home;
}

String? emailVerificationRedirect({
  required bool signedIn,
  required bool emailVerified,
  required String location,
}) {
  if (!signedIn) return null;
  if (!emailVerified && location != '/verify-email') return '/verify-email';
  if (emailVerified && location == '/verify-email') return '/welcome';
  return null;
}

/// Keeps role areas isolated while allowing routes shared by every role.
String? roleAreaRedirect({required Role role, required String location}) {
  if (location == AppRoutes.language) return null;

  final mentorArea = location.startsWith('/m/') || location.startsWith('/m-');
  final adminArea = location.startsWith('/a/') || location.startsWith('/a-');
  return switch (role) {
    Role.youth => (mentorArea || adminArea) ? role.home : null,
    Role.mentor => mentorArea ? null : role.home,
    Role.admin => adminArea ? null : role.home,
  };
}
