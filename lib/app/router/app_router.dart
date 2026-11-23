import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/auth/account_access_issue_screen.dart';
import 'package:upbridge/app/auth/account_deactivated_screen.dart';
import 'package:upbridge/app/auth/verify_email_screen.dart';
import 'package:upbridge/app/router/role_shell.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/app/splash/splash_screen.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_catalog_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_mentor_review_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_mentors_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_overview_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_settings_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_users_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/login_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/mentor_apply_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/mentor_pending_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/password_updated_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/welcome_screen.dart';
import 'package:upbridge/features/home/presentation/pages/notifications_screen.dart';
import 'package:upbridge/features/home/presentation/pages/student_dashboard_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/course_detail_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/courses_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_courses_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_dashboard_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_mentees_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_profile_settings_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_requests_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_sessions_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentor_detail_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentors_discovery_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentorship_detail_screen.dart';
import 'package:upbridge/features/onboarding/presentation/pages/goal_screen.dart';
import 'package:upbridge/features/onboarding/presentation/pages/interests_screen.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunities_screen.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunity_detail_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/edit_profile_cv_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/language_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/not_found_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/profile_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/project_detail_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/project_editor_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:upbridge/shared/animations/page_transitions.dart';

class _SessionRefreshListenable extends ChangeNotifier {
  _SessionRefreshListenable(Ref ref) {
    _sessionSubscription = ref.listen<AsyncValue<AppSession>>(
      appSessionProvider,
      (_, _) => notifyListeners(),
    );
    _regSubscription = ref.listen<bool>(
      registrationInProgressProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AppSession>> _sessionSubscription;
  late final ProviderSubscription<bool> _regSubscription;

  @override
  void dispose() {
    _sessionSubscription.close();
    _regSubscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final studentHomeKey = GlobalKey<NavigatorState>(debugLabel: 'studentHome');
  final studentLearnKey = GlobalKey<NavigatorState>(debugLabel: 'studentLearn');
  final studentMentorsKey = GlobalKey<NavigatorState>(
    debugLabel: 'studentMentors',
  );
  final studentJobsKey = GlobalKey<NavigatorState>(debugLabel: 'studentJobs');
  final studentProfileKey = GlobalKey<NavigatorState>(
    debugLabel: 'studentProfile',
  );

  final mentorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'mentorHome');
  final mentorCoursesKey = GlobalKey<NavigatorState>(
    debugLabel: 'mentorCourses',
  );
  final mentorRequestsKey = GlobalKey<NavigatorState>(
    debugLabel: 'mentorRequests',
  );
  final mentorMenteesKey = GlobalKey<NavigatorState>(
    debugLabel: 'mentorMentees',
  );
  final mentorProfileKey = GlobalKey<NavigatorState>(
    debugLabel: 'mentorProfile',
  );

  final adminOverviewKey = GlobalKey<NavigatorState>(
    debugLabel: 'adminOverview',
  );
  final adminUsersKey = GlobalKey<NavigatorState>(debugLabel: 'adminUsers');
  final adminMentorsKey = GlobalKey<NavigatorState>(debugLabel: 'adminMentors');
  final adminCatalogKey = GlobalKey<NavigatorState>(debugLabel: 'adminCatalog');
  final adminSettingsKey = GlobalKey<NavigatorState>(
    debugLabel: 'adminSettings',
  );

  final refreshListenable = _SessionRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final sessionAsync = ref.read(appSessionProvider);
      if (sessionAsync.isLoading && !sessionAsync.hasValue) {
        return null;
      }
      final session = sessionAsync.value ?? const AppSession.signedOut();
      final registrationBusy = ref.read(registrationInProgressProvider);
      return evaluateSessionRedirect(
        session: session,
        location: state.uri.path,
        registrationInProgress: registrationBusy,
      );
    },
    errorBuilder: (_, _) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.splash),
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, s) => fadePage(s, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (_, s) => fadePage(s, const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (_, s) => slidePage(s, const SignUpScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, s) => slidePage(s, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (_, s) => slidePage(s, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.passwordUpdated,
        pageBuilder: (_, s) => scalePage(s, const PasswordUpdatedScreen()),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        pageBuilder: (_, s) => fadePage(s, const VerifyEmailScreen()),
      ),
      GoRoute(
        path: AppRoutes.accountDeactivated,
        pageBuilder: (_, s) => fadePage(s, const AccountDeactivatedScreen()),
      ),
      GoRoute(
        path: AppRoutes.accountAccessIssue,
        pageBuilder: (_, s) => fadePage(s, const AccountAccessIssueScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingGoal,
        pageBuilder: (_, s) => slidePage(s, const GoalScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingInterests,
        pageBuilder: (_, s) => slidePage(s, const InterestsScreen()),
      ),
      GoRoute(
        path: AppRoutes.mentorPending,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => fadePage(s, const MentorPendingScreen()),
      ),
      GoRoute(
        path: AppRoutes.mentorApply,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(
          s,
          MentorApplyScreen(
            startInEditMode: s.uri.queryParameters['edit'] == '1',
          ),
        ),
      ),

      // Student role bottom navigation shell with isolated per-tab navigators.
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            RoleShell(role: UserRole.student, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: studentHomeKey,
            routes: [
              GoRoute(
                path: AppRoutes.studentHome,
                pageBuilder: (_, s) =>
                    tabPage(s, const StudentDashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: studentLearnKey,
            routes: [
              GoRoute(
                path: '/learn',
                pageBuilder: (_, s) => tabPage(s, const CoursesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: studentMentorsKey,
            routes: [
              GoRoute(
                path: '/mentors',
                pageBuilder: (_, s) =>
                    tabPage(s, const MentorsDiscoveryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: studentJobsKey,
            routes: [
              GoRoute(
                path: '/jobs',
                pageBuilder: (_, s) => tabPage(s, const OpportunitiesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: studentProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (_, s) => tabPage(s, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      // Mentor role bottom navigation shell: Dashboard, My Courses, Requests, Mentees, Profile.
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            RoleShell(role: UserRole.mentor, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: mentorHomeKey,
            routes: [
              GoRoute(
                path: AppRoutes.mentorHome,
                pageBuilder: (_, s) =>
                    tabPage(s, const MentorDashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: mentorCoursesKey,
            routes: [
              GoRoute(
                path: '/m/courses',
                pageBuilder: (_, s) => tabPage(s, const MentorCoursesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: mentorRequestsKey,
            routes: [
              GoRoute(
                path: '/m/requests',
                pageBuilder: (_, s) => tabPage(s, const MentorRequestsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: mentorMenteesKey,
            routes: [
              GoRoute(
                path: '/m/mentees',
                pageBuilder: (_, s) => tabPage(s, const MentorMenteesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: mentorProfileKey,
            routes: [
              GoRoute(
                path: '/m/profile',
                pageBuilder: (_, s) =>
                    tabPage(s, const MentorProfileSettingsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/m/sessions',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(s, const MentorSessionsScreen()),
      ),
      GoRoute(
        path: '/m/course/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(
          s,
          CourseDetailScreen(courseId: _param(s, 'id'), previewOnly: true),
        ),
      ),

      // Admin role bottom navigation shell.
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            RoleShell(role: UserRole.admin, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: adminOverviewKey,
            routes: [
              GoRoute(
                path: AppRoutes.adminOverview,
                pageBuilder: (_, s) => tabPage(s, const AdminOverviewScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: adminUsersKey,
            routes: [
              GoRoute(
                path: '/a/users',
                pageBuilder: (_, s) => tabPage(s, const AdminUsersScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: adminMentorsKey,
            routes: [
              GoRoute(
                path: '/a/mentors',
                pageBuilder: (_, s) => tabPage(s, const AdminMentorsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: adminCatalogKey,
            routes: [
              GoRoute(
                path: '/a/catalog',
                pageBuilder: (_, s) => tabPage(s, const AdminCatalogScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: adminSettingsKey,
            routes: [
              GoRoute(
                path: '/a/settings',
                pageBuilder: (_, s) => tabPage(s, const AdminSettingsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/a/course/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(
          s,
          CourseDetailScreen(courseId: _param(s, 'id'), previewOnly: true),
        ),
      ),

      // Shared and detail routes presented above the active role shell.
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(s, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.language,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(s, const LanguageScreen()),
      ),
      GoRoute(
        path: '/course/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) =>
            slidePage(s, CourseDetailScreen(courseId: _param(s, 'id'))),
      ),
      GoRoute(
        path: '/mentor/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) =>
            slidePage(s, MentorDetailScreen(mentorUid: _param(s, 'id'))),
      ),
      GoRoute(
        path: '/mentorship/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) =>
            slidePage(s, MentorshipDetailScreen(mentorshipId: _param(s, 'id'))),
      ),
      GoRoute(
        path: '/opportunity/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) =>
            slidePage(s, OpportunityDetailScreen(oppId: _param(s, 'id'))),
      ),
      GoRoute(
        path: '/project-new',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(s, const ProjectEditorScreen()),
      ),
      GoRoute(
        path: '/project/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) =>
            slidePage(s, ProjectDetailScreen(projectId: _param(s, 'id'))),
      ),
      GoRoute(
        path: '/project-edit/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) =>
            slidePage(s, ProjectEditorScreen(projectId: _param(s, 'id'))),
      ),
      GoRoute(
        path: '/profile-edit',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(s, const EditProfileCvScreen()),
      ),
      GoRoute(
        path: '/user-profile/:uid',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) =>
            slidePage(s, PublicProfileScreen(uid: _param(s, 'uid'))),
      ),
      GoRoute(
        path: '/a-applicant/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => slidePage(
          s,
          AdminMentorReviewScreen(applicantUid: _param(s, 'id')),
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

String _param(GoRouterState state, String name) =>
    state.pathParameters[name] ?? '';
