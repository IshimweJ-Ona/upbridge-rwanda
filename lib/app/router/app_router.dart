// Defines application routes and redirects based on Firebase auth and app roles.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/features/admin/presentation/pages/add_user_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_jobs_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_mentors_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_overview_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_settings_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_users_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/check_application_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/new_listing_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/reported_listing_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/verify_mentor_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/login_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/new_password_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/password_updated_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/verify_code_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/welcome_screen.dart';
import 'package:upbridge/app/auth/verify_email_screen.dart';
import 'package:upbridge/features/home/presentation/pages/check_in_screen.dart';
import 'package:upbridge/features/home/presentation/pages/home_screen.dart';
import 'package:upbridge/features/home/presentation/pages/notifications_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/feedback_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/learn_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/submit_work_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/submitted_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/task_details_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentee_detail_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentees_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_home_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_profile_settings_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_sessions_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/review_queue_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/review_rubric_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/review_sent_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/submission_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentor_profile_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentors_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/my_mentorship_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/request_sent_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/request_session_screen.dart';
import 'package:upbridge/features/onboarding/presentation/pages/goal_screen.dart';
import 'package:upbridge/features/onboarding/presentation/pages/interests_screen.dart';
import 'package:upbridge/features/applications/presentation/pages/application_sent_screen.dart';
import 'package:upbridge/features/applications/presentation/pages/application_status_screen.dart';
import 'package:upbridge/features/applications/presentation/pages/apply_review_screen.dart';
import 'package:upbridge/features/applications/presentation/pages/apply_screen.dart';
import 'package:upbridge/features/applications/presentation/pages/my_applications_screen.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunities_screen.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunity_detail_screen.dart';
import 'package:upbridge/features/portfolio/presentation/pages/add_project_screen.dart';
import 'package:upbridge/features/portfolio/presentation/pages/edit_profile_screen.dart';
import 'package:upbridge/features/portfolio/presentation/pages/portfolio_screen.dart';
import 'package:upbridge/features/portfolio/presentation/pages/project_detail_screen.dart';
import 'package:upbridge/features/portfolio/presentation/pages/project_saved_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/language_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/not_found_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/profile_screen.dart';
import 'package:upbridge/app/router/role_shell.dart';
import 'package:upbridge/app/router/route_guards.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

const _publicRoutes = {
  '/welcome',
  '/signup',
  '/login',
  '/forgot',
  '/verify',
  '/new-password',
  '/password-updated',
  '/verify-email',
};
const _sharedRoutes = {'/language'};

/// Re-runs the redirect whenever who is signed in (or their onboarding state) changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<(String?, bool?)>(
      appStoreProvider.select((s) => (s.user?.id, s.user?.onboarded)),
      (_, _) => notifyListeners(),
    );
    ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, _) => notifyListeners(),
    );
  }
}

String? _redirect(Ref ref, GoRouterState state) {
  final user = ref.read(appStoreProvider).user;
  final loc = state.matchedLocation;
  final isPublic = _publicRoutes.contains(loc);

  if (Firebase.apps.isNotEmpty) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return isPublic ? null : '/welcome';
    final verificationRedirect = emailVerificationRedirect(
      signedIn: true,
      emailVerified: firebaseUser.emailVerified,
      location: loc,
    );
    if (verificationRedirect != null) return verificationRedirect;
  }

  if (user == null) {
    return isPublic ? null : '/welcome';
  }
  if (!user.onboarded) {
    return loc.startsWith('/onboarding') ? null : '/onboarding/goal';
  }
  if (isPublic || loc == '/' || loc.startsWith('/onboarding')) {
    return user.role.home;
  }
  if (_sharedRoutes.contains(loc)) {
    return null;
  }

  final mentorArea = loc.startsWith('/m/') || loc.startsWith('/m-');
  final adminArea = loc.startsWith('/a/') || loc.startsWith('/a-');
  return switch (user.role) {
    Role.youth => (mentorArea || adminArea) ? user.role.home : null,
    Role.mentor => mentorArea ? null : user.role.home,
    Role.admin => adminArea ? null : user.role.home,
  };
}

String _id(GoRouterState s) => s.pathParameters['id'] ?? '';
Object? _hero(GoRouterState s) => s.extra is String ? s.extra : null;

GoRoute _route(
  String path,
  Page<void> Function(GoRouterState s, Widget child) page,
  Widget Function(GoRouterState s) build,
) => GoRoute(
  path: path,
  pageBuilder: (context, state) => page(state, build(state)),
);

StatefulShellRoute _shell(Role role, List<StatefulShellBranch> branches) =>
    StatefulShellRoute(
      pageBuilder: (context, state, shell) =>
          shellPage(state, RoleShell(shell: shell, role: role)),
      navigatorContainerBuilder: (context, shell, children) =>
          BranchSwitcher(index: shell.currentIndex, children: children),
      branches: branches,
    );

StatefulShellBranch _branch(
  String path,
  Widget Function(GoRouterState s) build, {
  List<RouteBase> routes = const [],
}) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      pageBuilder: (context, state) => tabPage(state, build(state)),
      routes: routes,
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state),
    errorPageBuilder: (context, state) =>
        fadePage(state, const NotFoundScreen()),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/welcome'),

      // ── Auth & onboarding ──
      _route('/welcome', fadePage, (_) => const WelcomeScreen()),
      _route('/signup', slidePage, (_) => const SignUpScreen()),
      _route('/login', slidePage, (_) => const LoginScreen()),
      _route('/forgot', slidePage, (_) => const ForgotPasswordScreen()),
      _route('/verify', slidePage, (_) => const VerifyCodeScreen()),
      _route('/new-password', slidePage, (_) => const NewPasswordScreen()),
      _route(
        '/password-updated',
        scalePage,
        (_) => const PasswordUpdatedScreen(),
      ),
      _route('/verify-email', fadePage, (_) => const VerifyEmailScreen()),
      _route('/onboarding/goal', stepPage, (_) => const GoalScreen()),
      _route('/onboarding/interests', stepPage, (_) => const InterestsScreen()),

      // ── Youth ──
      _shell(Role.youth, [
        _branch('/home', (_) => const HomeScreen()),
        _branch('/learn', (_) => const LearnScreen()),
        _branch('/mentors', (_) => const MentorsScreen()),
        _branch(
          '/jobs',
          (_) => const OpportunitiesScreen(),
          routes: [
            GoRoute(
              path: 'applications',
              pageBuilder: (context, state) =>
                  slidePage(state, const MyApplicationsScreen()),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) => slidePage(
                    state,
                    ApplicationStatusScreen(appId: _id(state)),
                  ),
                ),
              ],
            ),
          ],
        ),
        _branch(
          '/profile',
          (_) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'portfolio',
              pageBuilder: (context, state) => slidePage(
                state,
                PortfolioScreen(
                  initialTab: state.uri.queryParameters['tab'] == 'about'
                      ? 1
                      : 0,
                ),
              ),
            ),
          ],
        ),
      ]),
      _route('/notifications', slidePage, (_) => const NotificationsScreen()),
      _route('/check-in', stepPage, (_) => const CheckInScreen()),
      _route('/task/:id', slidePage, (s) => TaskDetailsScreen(taskId: _id(s))),
      _route(
        '/task-submit/:id',
        slidePage,
        (s) => SubmitWorkScreen(taskId: _id(s)),
      ),
      _route(
        '/task-submitted/:id',
        scalePage,
        (s) => SubmittedScreen(taskId: _id(s)),
      ),
      _route(
        '/task-feedback/:id',
        slidePage,
        (s) => FeedbackScreen(taskId: _id(s)),
      ),
      _route(
        '/mentor/:id',
        slidePage,
        (s) => MentorProfileScreen(mentorId: _id(s), heroTag: _hero(s)),
      ),
      _route(
        '/mentor-request/:id',
        slidePage,
        (s) => RequestSessionScreen(mentorId: _id(s)),
      ),
      _route(
        '/request-sent/:id',
        scalePage,
        (s) => RequestSentScreen(sessionId: _id(s)),
      ),
      _route('/my-mentorship', slidePage, (_) => const MyMentorshipScreen()),
      _route(
        '/project/:id',
        slidePage,
        (s) => ProjectDetailScreen(projectId: _id(s), heroTag: _hero(s)),
      ),
      _route('/project-new', stepPage, (_) => const AddProjectScreen()),
      _route(
        '/project-saved/:id',
        scalePage,
        (s) => ProjectSavedScreen(projectId: _id(s)),
      ),
      _route('/profile-edit', slidePage, (_) => const EditProfileScreen()),
      _route('/language', slidePage, (_) => const LanguageScreen()),
      _route(
        '/opportunity/:id',
        slidePage,
        (s) => OpportunityDetailScreen(oppId: _id(s), heroTag: _hero(s)),
      ),
      _route('/apply/:id', slidePage, (s) => ApplyScreen(oppId: _id(s))),
      _route(
        '/apply-review/:id',
        slidePage,
        (s) => ApplyReviewScreen(oppId: _id(s)),
      ),
      _route(
        '/application-sent/:id',
        scalePage,
        (s) => ApplicationSentScreen(appId: _id(s)),
      ),

      // ── Mentor ──
      _shell(Role.mentor, [
        _branch('/m/home', (_) => const MentorHomeScreen()),
        _branch('/m/reviews', (_) => const ReviewQueueScreen()),
        _branch('/m/sessions', (_) => const MentorSessionsScreen()),
        _branch('/m/mentees', (_) => const MenteesScreen()),
        _branch('/m/profile', (_) => const MentorProfileSettingsScreen()),
      ]),
      _route(
        '/m-submission/:id',
        slidePage,
        (s) => SubmissionScreen(submissionId: _id(s)),
      ),
      _route(
        '/m-review/:id',
        slidePage,
        (s) => ReviewRubricScreen(submissionId: _id(s)),
      ),
      _route(
        '/m-review-sent/:id',
        scalePage,
        (s) => ReviewSentScreen(submissionId: _id(s)),
      ),
      _route(
        '/m-mentee/:id',
        slidePage,
        (s) => MenteeDetailScreen(menteeId: _id(s)),
      ),

      // ── Admin ──
      _shell(Role.admin, [
        _branch('/a/overview', (_) => const AdminOverviewScreen()),
        _branch('/a/users', (_) => const AdminUsersScreen()),
        _branch('/a/mentors', (_) => const AdminMentorsScreen()),
        _branch(
          '/a/jobs',
          (s) => AdminJobsScreen(
            initialTab: switch (s.uri.queryParameters['tab']) {
              'forward' => 1,
              'reported' => 2,
              _ => 0,
            },
          ),
        ),
        _branch('/a/settings', (_) => const AdminSettingsScreen()),
      ]),
      _route('/a-new-user', stepPage, (_) => const AddUserScreen()),
      _route(
        '/a-applicant/:id',
        slidePage,
        (s) => VerifyMentorScreen(applicantId: _id(s)),
      ),
      _route('/a-new-listing', stepPage, (_) => const NewListingScreen()),
      _route(
        '/a-listing/:id',
        slidePage,
        (s) => ReportedListingScreen(listingId: _id(s)),
      ),
      _route(
        '/a-forward/:id',
        slidePage,
        (s) => CheckApplicationScreen(forwardId: _id(s)),
      ),
    ],
  );
  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
});
