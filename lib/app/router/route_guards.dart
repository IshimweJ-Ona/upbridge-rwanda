// Keeps launch, email-verification, and role-area redirect policy pure and testable.
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/shared/models/models.dart';

/// Resolves the target route for a verified, signed-in user.
String verifiedUserDestination({required Role role, required bool onboarded}) {
  if (role == Role.youth && !onboarded) return '/onboarding/goal';
  return role.home;
}

/// Resolves the launch destination using Firebase session state or demo fallback.
String splashDestination({
  required bool firebaseInitialized,
  required bool firebaseSignedIn,
  required bool emailVerified,
  Role? firebaseRole,
  bool? firebaseOnboarded,
  bool firebaseProfileExists = true,
  AppUser? appUser,
}) {
  if (firebaseInitialized) {
    if (!firebaseSignedIn) return AppRoutes.welcome;
    if (!emailVerified) return AppRoutes.verifyEmail;
    if (firebaseRole == Role.youth && !firebaseProfileExists) {
      return AppRoutes.verifyEmail;
    }
    if (firebaseRole != null) {
      return verifiedUserDestination(
        role: firebaseRole,
        onboarded: firebaseOnboarded ?? false,
      );
    }
    if (appUser == null) return '/onboarding/goal';
    return verifiedUserDestination(
      role: appUser.role,
      onboarded: appUser.onboarded,
    );
  }

  if (appUser == null) return AppRoutes.welcome;
  return verifiedUserDestination(
    role: appUser.role,
    onboarded: appUser.onboarded,
  );
}

String? emailVerificationRedirect({
  required bool signedIn,
  required bool emailVerified,
  required String location,
  String verifiedDestination = AppRoutes.youthHome,
}) {
  if (!signedIn) return null;
  if (!emailVerified && location != AppRoutes.verifyEmail) {
    return AppRoutes.verifyEmail;
  }
  if (emailVerified && location == AppRoutes.verifyEmail) {
    return verifiedDestination;
  }
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
