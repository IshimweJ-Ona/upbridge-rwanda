import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/session_providers.dart';

/// Publicly reachable routes before sign-in completes.
const kPublicRoutes = <String>{
  AppRoutes.splash,
  AppRoutes.welcome,
  AppRoutes.signup,
  AppRoutes.login,
  AppRoutes.forgotPassword,
  AppRoutes.passwordUpdated,
  AppRoutes.verifyEmail,
  AppRoutes.accountDeactivated,
  AppRoutes.language,
};

/// Exact shared utility routes available to any verified active user.
const kSharedExactRoutes = <String>{
  AppRoutes.notifications,
  AppRoutes.language,
  '/profile-edit',
  '/project-new',
  AppRoutes.mentorApply,
};

/// Parameterized shared route prefixes available to verified active users.
const kSharedRoutePrefixes = <String>[
  '/mentorship/',
  '/user-profile/',
  '/project/',
  '/project-edit/',
];

/// Exact routes accessible while a prospective mentor is awaiting admin review or updating a rejected application.
const kPendingMentorRoutes = <String>{
  AppRoutes.mentorPending,
  AppRoutes.mentorApply,
  AppRoutes.notifications,
  AppRoutes.language,
};

/// Returns true when [location] points to a route shared across roles.
bool isSharedRouteLocation(String location) {
  if (kSharedExactRoutes.contains(location)) return true;
  for (final prefix in kSharedRoutePrefixes) {
    if (location.startsWith(prefix)) return true;
  }
  return false;
}

/// Resolves the landing route for a verified, active account.
String homeRouteForRole(
  UserRole role, {
  required bool onboarded,
  bool isPendingOrRejectedMentor = false,
}) {
  if (role == UserRole.student && isPendingOrRejectedMentor) {
    return AppRoutes.mentorPending;
  }
  if (role == UserRole.student && !onboarded) return AppRoutes.onboardingGoal;
  return switch (role) {
    UserRole.student => AppRoutes.studentHome,
    UserRole.mentor => AppRoutes.mentorHome,
    UserRole.admin => AppRoutes.adminOverview,
  };
}

/// Evaluates full redirect rules from verified Firebase ID token claims and account state.
String? evaluateSessionRedirect({
  required AppSession session,
  required String location,
  Set<String> publicRoutes = kPublicRoutes,
  Set<String> sharedRoutes = kSharedExactRoutes,
}) {
  if (location == AppRoutes.splash) return null;
  final isPublic = publicRoutes.contains(location);

  if (!session.signedIn) {
    return isPublic ? null : AppRoutes.welcome;
  }
  if (!session.emailVerified) {
    return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
  }
  // Wait for users/{uid} and mentorApplications/{uid} to finish initial load before
  // evaluating onboarding/pending redirects, eliminating 1-frame startup route flashes.
  if (!session.accountLoaded ||
      !session.applicationLoaded ||
      session.accountError) {
    return null;
  }
  if (!session.isActive) {
    return location == AppRoutes.accountDeactivated
        ? null
        : AppRoutes.accountDeactivated;
  }
  if (session.role == UserRole.student && !session.accountExists) {
    return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
  }

  final isPendingOrRejectedMentor =
      session.role == UserRole.student &&
      (session.hasPendingMentorApplication ||
          session.hasRejectedMentorApplication ||
          session.hasRevokedMentorApplication);

  if (isPendingOrRejectedMentor) {
    if (kPendingMentorRoutes.contains(location)) {
      return null;
    }
    return AppRoutes.mentorPending;
  }

  final destination = homeRouteForRole(
    session.role,
    onboarded: session.onboarded,
  );
  if (session.role == UserRole.student && !session.onboarded) {
    if (location == AppRoutes.mentorApply ||
        location == AppRoutes.mentorPending ||
        location == AppRoutes.language) {
      return null;
    }
    return location.startsWith('/onboarding') ? null : AppRoutes.onboardingGoal;
  }

  if (isPublic ||
      location == '/' ||
      location == AppRoutes.accountDeactivated ||
      location == AppRoutes.mentorPending ||
      location.startsWith('/onboarding')) {
    return destination;
  }

  if (sharedRoutes.contains(location) || isSharedRouteLocation(location)) {
    return claimsRoleAreaRedirect(role: session.role, location: location);
  }

  return claimsRoleAreaRedirect(role: session.role, location: location);
}

/// Enforces strict route isolation by trusted role.
String? claimsRoleAreaRedirect({
  required UserRole role,
  required String location,
}) {
  if (isSharedRouteLocation(location)) return null;

  final mentorArea = location.startsWith('/m/') || location.startsWith('/m-');
  final adminArea = location.startsWith('/a/') || location.startsWith('/a-');

  return switch (role) {
    UserRole.student =>
      (mentorArea || adminArea) ? AppRoutes.studentHome : null,
    UserRole.mentor =>
      (mentorArea || isSharedRouteLocation(location))
          ? null
          : AppRoutes.mentorHome,
    UserRole.admin =>
      (adminArea || isSharedRouteLocation(location))
          ? null
          : AppRoutes.adminOverview,
  };
}
