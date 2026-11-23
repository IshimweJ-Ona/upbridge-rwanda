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
  AppRoutes.accountAccessIssue,
  AppRoutes.language,
};

/// Exact shared utility routes available to any verified active user.
const kSharedExactRoutes = <String>{
  AppRoutes.notifications,
  AppRoutes.language,
  '/profile-edit',
  '/project-new',
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
  bool isApprovedMentor = true,
}) {
  if (isPendingOrRejectedMentor) {
    return AppRoutes.mentorPending;
  }
  if (role == UserRole.mentor) {
    return isApprovedMentor ? AppRoutes.mentorHome : AppRoutes.mentorPending;
  }
  if (role == UserRole.student && !onboarded) return AppRoutes.onboardingGoal;
  return switch (role) {
    UserRole.student => AppRoutes.studentHome,
    UserRole.mentor => AppRoutes.mentorHome,
    UserRole.admin => AppRoutes.adminOverview,
  };
}

/// Resolves the canonical destination from a complete [AppSession].
String homeRouteForSession(AppSession session) {
  if (!session.signedIn) return AppRoutes.welcome;
  if (!session.emailVerified) return AppRoutes.verifyEmail;
  if (!session.isActive) return AppRoutes.accountDeactivated;
  if (session.accountError) return AppRoutes.accountAccessIssue;
  if (!session.accountExists && session.role != UserRole.admin) {
    return AppRoutes.accountAccessIssue;
  }
  if (session.requiresMentorApprovalScreen) return AppRoutes.mentorPending;
  if (!session.roleValid) return AppRoutes.accountAccessIssue;
  return homeRouteForRole(
    session.role,
    onboarded: session.onboarded,
    isPendingOrRejectedMentor: session.requiresMentorApprovalScreen,
    isApprovedMentor: session.isApprovedMentor,
  );
}

/// Evaluates full redirect rules from verified Firebase ID token claims and account state.
String? evaluateSessionRedirect({
  required AppSession session,
  required String location,
  Set<String> publicRoutes = kPublicRoutes,
  Set<String> sharedRoutes = kSharedExactRoutes,
  bool registrationInProgress = false,
}) {
  if (location == AppRoutes.splash) return null;
  if (registrationInProgress && location == AppRoutes.signup) return null;
  final isPublic = publicRoutes.contains(location);

  if (!session.signedIn) {
    return isPublic ? null : AppRoutes.welcome;
  }
  if (!session.emailVerified) {
    return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
  }
  // Wait for users/{uid} and mentorApplications/{uid} to finish initial load before
  // evaluating onboarding/pending redirects, eliminating startup route flashes.
  if (!session.accountLoaded || !session.applicationLoaded) {
    return null;
  }
  if (!session.isActive) {
    return location == AppRoutes.accountDeactivated
        ? null
        : AppRoutes.accountDeactivated;
  }
  if (session.accountError) {
    return location == AppRoutes.accountAccessIssue
        ? null
        : AppRoutes.accountAccessIssue;
  }
  if (!session.accountExists && session.role != UserRole.admin) {
    // Allow VerifyEmailScreen to complete first-time setup if offline at signup;
    // fail closed anywhere else so deleted/missing accounts never reach a dashboard.
    if (location == AppRoutes.verifyEmail) return null;
    return location == AppRoutes.accountAccessIssue
        ? null
        : AppRoutes.accountAccessIssue;
  }
  if (session.requiresMentorApprovalScreen) {
    if (kPendingMentorRoutes.contains(location)) {
      return null;
    }
    return AppRoutes.mentorPending;
  }
  if (!session.roleValid) {
    return location == AppRoutes.accountAccessIssue
        ? null
        : AppRoutes.accountAccessIssue;
  }
  if (session.role == UserRole.mentor && !session.isApprovedMentor) {
    if (kPendingMentorRoutes.contains(location)) {
      return null;
    }
    return AppRoutes.mentorPending;
  }

  final destination = homeRouteForSession(session);

  // Youth and Admin accounts cannot use self-service mentor application/pending routes.
  if (session.role != UserRole.mentor &&
      (location == AppRoutes.mentorApply ||
          location == AppRoutes.mentorPending)) {
    return destination;
  }

  if (session.role == UserRole.student && !session.onboarded) {
    if (location == AppRoutes.language) {
      return null;
    }
    return location.startsWith('/onboarding') ? null : AppRoutes.onboardingGoal;
  }

  if (isPublic ||
      location == '/' ||
      location == AppRoutes.accountDeactivated ||
      location == AppRoutes.accountAccessIssue ||
      location == AppRoutes.mentorPending ||
      location.startsWith('/onboarding')) {
    return destination;
  }

  if (sharedRoutes.contains(location) || isSharedRouteLocation(location)) {
    return claimsRoleAreaRedirect(
      role: session.role,
      location: location,
      isApprovedMentor: session.isApprovedMentor,
    );
  }

  return claimsRoleAreaRedirect(
    role: session.role,
    location: location,
    isApprovedMentor: session.isApprovedMentor,
  );
}

/// Enforces strict route isolation by trusted role.
String? claimsRoleAreaRedirect({
  required UserRole role,
  required String location,
  bool isApprovedMentor = true,
}) {
  if (role == UserRole.mentor && !isApprovedMentor) {
    return kPendingMentorRoutes.contains(location)
        ? null
        : AppRoutes.mentorPending;
  }
  if (isSharedRouteLocation(location)) return null;

  final mentorArea = location.startsWith('/m/') || location.startsWith('/m-');
  final mentorOnlyLifecycleRoute =
      location == AppRoutes.mentorApply || location == AppRoutes.mentorPending;
  final adminArea = location.startsWith('/a/') || location.startsWith('/a-');

  return switch (role) {
    UserRole.student =>
      (mentorArea || mentorOnlyLifecycleRoute || adminArea)
          ? AppRoutes.studentHome
          : null,
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
