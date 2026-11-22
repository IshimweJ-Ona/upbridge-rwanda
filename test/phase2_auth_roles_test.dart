import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/auth/account_deactivated_screen.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/auth/presentation/pages/mentor_apply_screen.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

void main() {
  const publicRoutes = {
    AppRoutes.welcome,
    AppRoutes.signup,
    AppRoutes.login,
    AppRoutes.forgotPassword,
    AppRoutes.verifyEmail,
  };
  const sharedRoutes = {AppRoutes.language, '/notifications', '/mentor-apply'};

  group('Phase 2: Claims-based route guards', () {
    test('maps ID token role claims safely defaulting to student', () {
      expect(userRoleFromClaim('admin'), UserRole.admin);
      expect(userRoleFromClaim('mentor'), UserRole.mentor);
      expect(userRoleFromClaim('student'), UserRole.student);
      expect(userRoleFromClaim(null), UserRole.student);
      expect(userRoleFromClaim('superadmin'), UserRole.student);
    });

    test('resolves Spark admin-approved mentor from users doc and prevents mid-load bounce', () {
      final now = DateTime.utc(2026, 11, 19);
      expect(
        resolveEffectiveRole(claimRole: UserRole.student),
        UserRole.student,
      );

      const unapprovedLoadingSession = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'u1',
        role: UserRole.student,
        accountLoaded: false,
        accountExists: false,
      );
      expect(
        evaluateSessionRedirect(
          session: unapprovedLoadingSession,
          location: '/home',
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        isNull,
      );

      final approvedAccount = AppUserAccount(
        id: 'u1',
        ownerUid: 'u1',
        email: 'mentor@upbridge.rw',
        displayName: 'Approved Mentor',
        phone: '',
        role: UserRole.mentor,
        isApproved: true,
        status: AccountStatus.active,
        onboarded: true,
        preferredLocale: 'en',
        createdAt: now,
        updatedAt: now,
      );
      expect(
        resolveEffectiveRole(
          claimRole: UserRole.student,
          account: approvedAccount,
        ),
        UserRole.mentor,
      );
      expect(
        resolveEffectiveRole(
          claimRole: UserRole.student,
          account: approvedAccount.copyWith(isApproved: false),
        ),
        UserRole.student,
      );
      expect(resolveEffectiveRole(claimRole: UserRole.admin), UserRole.admin);
    });

    test(
      'blocks unauthenticated and unverified users from protected routes',
      () {
        expect(
          evaluateSessionRedirect(
            session: const AppSession.signedOut(),
            location: '/home',
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          AppRoutes.welcome,
        );
        expect(
          evaluateSessionRedirect(
            session: const AppSession(
              firebaseInitialized: true,
              signedIn: true,
              emailVerified: false,
              uid: 'u1',
            ),
            location: '/home',
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          AppRoutes.verifyEmail,
        );
      },
    );

    test('redirects deactivated accounts regardless of claim', () {
      const deactivated = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'u1',
        role: UserRole.mentor,
        accountStatus: AccountStatus.deactivated,
        onboarded: true,
        accountExists: true,
      );
      expect(
        evaluateSessionRedirect(
          session: deactivated,
          location: '/m/home',
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        '/account-deactivated',
      );
    });

    test(
      'blocks unapproved mentor (role=student claim) from mentor routes',
      () {
        final now = DateTime.utc(2026, 11, 19);
        final pendingMentorStudent = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u1',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
          mentorApplication: MentorApplication(
            id: 'u1',
            ownerUid: 'u1',
            applicantName: 'Pending Mentor',
            applicantEmail: 'p@upbridge.rw',
            headline: 'Engineer',
            bio: 'Experienced backend developer ready to mentor youth.',
            expertise: const ['Backend'],
            experienceYears: 5,
            status: MentorApplicationStatus.pending,
            createdAt: now,
            updatedAt: now,
          ),
        );

        expect(
          evaluateSessionRedirect(
            session: pendingMentorStudent,
            location: '/m/home',
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          AppRoutes.mentorPending,
        );
        expect(
          evaluateSessionRedirect(
            session: pendingMentorStudent,
            location: AppRoutes.studentHome,
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          AppRoutes.mentorPending,
        );
        expect(
          evaluateSessionRedirect(
            session: pendingMentorStudent,
            location: AppRoutes.mentorPending,
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          isNull,
        );
        expect(
          evaluateSessionRedirect(
            session: pendingMentorStudent,
            location: AppRoutes.mentorApply,
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          isNull,
        );

        final revokedMentorStudent = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u1',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
          mentorApplication: pendingMentorStudent.mentorApplication!.copyWith(
            status: MentorApplicationStatus.revoked,
            rejectionReason: 'Code of conduct violation',
          ),
        );
        expect(
          evaluateSessionRedirect(
            session: revokedMentorStudent,
            location: AppRoutes.studentHome,
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          AppRoutes.mentorPending,
        );
        expect(
          evaluateSessionRedirect(
            session: revokedMentorStudent,
            location: '/m/courses',
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          AppRoutes.mentorPending,
        );
        expect(
          evaluateSessionRedirect(
            session: revokedMentorStudent,
            location: AppRoutes.mentorPending,
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          isNull,
        );
        expect(
          evaluateSessionRedirect(
            session: revokedMentorStudent,
            location: AppRoutes.mentorApply,
            publicRoutes: publicRoutes,
            sharedRoutes: sharedRoutes,
          ),
          isNull,
        );
      },
    );

    test('allows approved mentor and admin only into their own role areas', () {
      const mentor = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'm1',
        role: UserRole.mentor,
        onboarded: true,
        accountExists: true,
      );
      expect(
        evaluateSessionRedirect(
          session: mentor,
          location: '/m/home',
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        isNull,
      );
      expect(
        evaluateSessionRedirect(
          session: mentor,
          location: '/a/overview',
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.mentorHome,
      );

      const admin = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'a1',
        role: UserRole.admin,
        onboarded: true,
        accountExists: true,
      );
      expect(
        evaluateSessionRedirect(
          session: admin,
          location: '/a/overview',
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        isNull,
      );
      expect(
        evaluateSessionRedirect(
          session: admin,
          location: '/home',
          publicRoutes: publicRoutes,
          sharedRoutes: sharedRoutes,
        ),
        AppRoutes.adminOverview,
      );
    });
  });

  group('Phase 2: Pending mentor & deactivated widgets', () {
    testWidgets('MentorApplyScreen renders pending banner and refresh button', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 11, 19);
      final session = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'u1',
        email: 'mentor@test.rw',
        displayName: 'Pending Mentor',
        role: UserRole.student,
        onboarded: true,
        accountExists: true,
        mentorApplication: MentorApplication(
          id: 'u1',
          ownerUid: 'u1',
          applicantName: 'Pending Mentor',
          applicantEmail: 'mentor@test.rw',
          headline: 'Senior Mobile Engineer',
          bio: 'Mentoring engineers in Rwanda for 5 years.',
          expertise: const ['Mobile Development'],
          experienceYears: 5,
          status: MentorApplicationStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith((ref) => Stream.value(session)),
            authServiceProvider.overrideWithValue(_NoopAuthService()),
          ],
          child: const MaterialApp(home: MentorApplyScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Application pending admin approval'), findsOneWidget);
      expect(find.text('Check approval status'), findsOneWidget);
    });

    testWidgets('AccountDeactivatedScreen renders notice and sign out', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(_NoopAuthService()),
          ],
          child: const MaterialApp(home: AccountDeactivatedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account deactivated'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}

class _NoopAuthService extends AuthService {}
