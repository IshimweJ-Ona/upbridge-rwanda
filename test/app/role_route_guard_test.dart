import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';

void main() {
  group('claimsRoleAreaRedirect', () {
    test('student stays in student routes and shared locations', () {
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.studentHome,
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.language,
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: '/mentorship/m1',
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.mentorApply,
        ),
        AppRoutes.studentHome,
      );
    });

    test('student is redirected home when entering mentor or admin routes', () {
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.mentorHome,
        ),
        AppRoutes.studentHome,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.adminOverview,
        ),
        AppRoutes.studentHome,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: '/a-applicant/u1',
        ),
        AppRoutes.studentHome,
      );
    });

    test(
      'mentor stays in mentor routes and shared mentorship/profile routes',
      () {
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: AppRoutes.mentorHome,
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: '/m/requests',
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: '/mentorship/m1',
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: '/user-profile/s1',
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: AppRoutes.language,
          ),
          isNull,
        );
      },
    );

    test('mentor is sent to mentor home outside mentor & shared areas', () {
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.mentor,
          location: AppRoutes.studentHome,
        ),
        AppRoutes.mentorHome,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.mentor,
          location: AppRoutes.adminOverview,
        ),
        AppRoutes.mentorHome,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.mentor,
          location: '/a-applicant/u1',
        ),
        AppRoutes.mentorHome,
      );
    });

    test('admin stays in admin & shared routes and is redirected from other role areas', () {
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: AppRoutes.adminOverview,
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: '/a-applicant/u1',
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: '/user-profile/u1',
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: AppRoutes.mentorHome,
        ),
        AppRoutes.adminOverview,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: AppRoutes.studentHome,
        ),
        AppRoutes.adminOverview,
      );
    });
  });

  group('Fail-closed lifecycle route guard matrix', () {
    const publicRoutes = {
      AppRoutes.welcome,
      AppRoutes.signup,
      AppRoutes.login,
      AppRoutes.forgotPassword,
      AppRoutes.verifyEmail,
    };
    const sharedRoutes = {
      AppRoutes.language,
      AppRoutes.notifications,
      AppRoutes.mentorApply,
    };

    test('never defaults missing/invalid roles or errors to student dashboard', () {
      const invalidRoleSession = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'bad-role',
        role: UserRole.student,
        roleValid: false,
        accountExists: true,
      );
      expect(homeRouteForSession(invalidRoleSession), AppRoutes.accountAccessIssue);
      expect(
        evaluateSessionRedirect(
          session: invalidRoleSession,
          location: AppRoutes.studentHome,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.accountAccessIssue,
      );

      const errorSession = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'err-user',
        role: UserRole.student,
        accountError: true,
      );
      expect(homeRouteForSession(errorSession), AppRoutes.accountAccessIssue);
      expect(
        evaluateSessionRedirect(
          session: errorSession,
          location: AppRoutes.studentHome,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.accountAccessIssue,
      );
    });

    test('enforces unverified/pending/rejected/approved mentor isolation', () {
      const unverifiedMentor = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: false,
        uid: 'm-unv',
        role: UserRole.mentor,
        approvalStatus: ApprovalStatus.pending,
        accountExists: true,
      );
      expect(homeRouteForSession(unverifiedMentor), AppRoutes.verifyEmail);
      expect(
        evaluateSessionRedirect(
          session: unverifiedMentor,
          location: AppRoutes.mentorPending,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.verifyEmail,
      );

      const pendingMentor = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'm-pend',
        role: UserRole.mentor,
        approvalStatus: ApprovalStatus.pending,
        onboarded: true,
        accountExists: true,
      );
      expect(homeRouteForSession(pendingMentor), AppRoutes.mentorPending);
      for (final target in [
        AppRoutes.studentHome,
        AppRoutes.onboardingGoal,
        AppRoutes.mentorHome,
        AppRoutes.adminOverview,
      ]) {
        expect(
          evaluateSessionRedirect(
            session: pendingMentor,
            location: target,
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          AppRoutes.mentorPending,
        );
      }

      const approvedMentor = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'm-ok',
        role: UserRole.mentor,
        approvalStatus: ApprovalStatus.approved,
        onboarded: true,
        accountExists: true,
      );
      expect(homeRouteForSession(approvedMentor), AppRoutes.mentorHome);
      expect(
        evaluateSessionRedirect(
          session: approvedMentor,
          location: AppRoutes.studentHome,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.mentorHome,
      );
      expect(
        evaluateSessionRedirect(
          session: approvedMentor,
          location: AppRoutes.mentorHome,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        isNull,
      );
    });

    test('registrationInProgress prevents premature redirect from /signup', () {
      const justSignedUp = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: false,
        uid: 'm-new',
        role: UserRole.mentor,
        approvalStatus: ApprovalStatus.pending,
      );
      expect(
        evaluateSessionRedirect(
          session: justSignedUp,
          location: AppRoutes.signup,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
          registrationInProgress: true,
        ),
        isNull,
      );
    });

    test('blocks Youth from /mentor-apply and /mentor-pending, and fails closed on missing docs or demoted admins', () {
      const youthOnboarded = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'y1',
        role: UserRole.student,
        onboarded: true,
        accountExists: true,
      );
      expect(
        evaluateSessionRedirect(
          session: youthOnboarded,
          location: AppRoutes.mentorApply,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.studentHome,
      );
      expect(
        evaluateSessionRedirect(
          session: youthOnboarded,
          location: AppRoutes.mentorPending,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.studentHome,
      );

      const youthUnboarded = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'y2',
        role: UserRole.student,
        onboarded: false,
        accountExists: true,
      );
      expect(
        evaluateSessionRedirect(
          session: youthUnboarded,
          location: AppRoutes.mentorApply,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.onboardingGoal,
      );

      const missingAccountSession = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'missing-doc',
        role: UserRole.student,
        accountLoaded: true,
        accountExists: false,
      );
      expect(homeRouteForSession(missingAccountSession), AppRoutes.accountAccessIssue);
      expect(
        evaluateSessionRedirect(
          session: missingAccountSession,
          location: AppRoutes.studentHome,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.accountAccessIssue,
      );

      final now = DateTime.utc(2026, 11, 23);
      final demotedAccount = AppUserAccount(
        id: 'admin-demoted',
        ownerUid: 'admin-demoted',
        email: 'd@test.rw',
        displayName: 'Demoted',
        phone: '',
        role: UserRole.student,
        isApproved: false,
        status: AccountStatus.active,
        onboarded: true,
        preferredLocale: 'en',
        createdAt: now,
        updatedAt: now,
      );
      expect(
        resolveEffectiveRoleNullable(
          claimRole: UserRole.admin,
          account: demotedAccount,
        ),
        isNull,
      );

      // Stale mentor claim without an active Firestore users/{uid} account doc
      // must NEVER resolve to approved mentor or reach /m/home.
      expect(
        resolveApprovalStatus(
          role: UserRole.mentor,
          claimRole: UserRole.mentor,
          account: null,
          mentorApplication: null,
        ),
        ApprovalStatus.pending,
      );
      const staleClaimMissingDoc = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'stale-mentor',
        role: UserRole.mentor,
        approvalStatus: ApprovalStatus.approved,
        accountLoaded: true,
        accountExists: false,
      );
      expect(homeRouteForSession(staleClaimMissingDoc), AppRoutes.accountAccessIssue);
      expect(
        evaluateSessionRedirect(
          session: staleClaimMissingDoc,
          location: AppRoutes.mentorHome,
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.accountAccessIssue,
      );
    });
  });
}
