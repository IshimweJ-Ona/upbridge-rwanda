import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:upbridge/app/router/role_shell.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/services/admin_operations_service.dart';
import 'package:upbridge/core/services/cloudinary_service.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_mentor_review_screen.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/presentation/pages/course_detail_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_requests_screen.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentor_application_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentorship_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentor_detail_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentorship_detail_screen.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 11, 19, 10);

  group('UpBridge E2E User Journeys (in-memory service harness)', () {
    testWidgets(
      '1. Student signup -> verification -> onboarding -> home redirect guard',
      (tester) async {
        const unverified = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: false,
          uid: 's1',
        );
        expect(
          evaluateSessionRedirect(
            session: unverified,
            location: AppRoutes.studentHome,
          ),
          AppRoutes.verifyEmail,
        );

        const verifiedUnboarded = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 's1',
          role: UserRole.student,
          onboarded: false,
          accountExists: true,
        );
        expect(
          evaluateSessionRedirect(
            session: verifiedUnboarded,
            location: AppRoutes.studentHome,
          ),
          AppRoutes.onboardingGoal,
        );

        const readyStudent = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 's1',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        expect(
          evaluateSessionRedirect(
            session: readyStudent,
            location: AppRoutes.onboardingInterests,
          ),
          AppRoutes.studentHome,
        );
      },
    );

    testWidgets(
      '2. Mentor application -> Admin approval via AdminOperationsClient -> Mentor access',
      (tester) async {
        final appRepo = _FakeMentorAppRepo(
          MentorApplication(
            id: 'm1',
            ownerUid: 'm1',
            applicantName: 'Claire Mukamana',
            applicantEmail: 'claire@upbridge.rw',
            headline: 'Senior Mobile Engineer',
            bio: 'Mentoring youth on Flutter & Firebase.',
            expertise: const ['Flutter', 'Architecture'],
            experienceYears: 7,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final adminOps = _FakeAdminOperations(onApprove: appRepo.markApproved);

        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('mentor-scope'),
            overrides: [
              mentorApplicationRepositoryProvider.overrideWithValue(appRepo),
              adminOperationsClientProvider.overrideWithValue(adminOps),
            ],
            child: MaterialApp(
              theme: buildAppTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const AdminMentorReviewScreen(applicantUid: 'm1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Claire Mukamana'), findsOneWidget);
        await tester.ensureVisible(find.text('Approve mentor application'));
        await tester.tap(find.text('Approve mentor application'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Approve mentor'));
        await tester.pumpAndSettle();

        expect(adminOps.approvedUids, ['m1']);
        expect(appRepo.application?.status, MentorApplicationStatus.approved);

        const promotedMentor = AppSession(
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
            session: promotedMentor,
            location: AppRoutes.studentHome,
          ),
          AppRoutes.mentorHome,
        );
      },
    );

    testWidgets(
      '3. Mentorship flow: Request -> Accept -> Schedule session -> Complete with rating',
      (tester) async {
        final mentorshipRepo = _FakeE2EMentorshipRepo();
        final sessionRepo = _FakeE2ESessionRepo();
        final mentorProfile = UserProfile(
          id: 'm1',
          ownerUid: 'm1',
          displayName: 'Claire Mukamana',
          headline: 'Mobile Architect',
          location: 'Kigali',
          about: 'Coaching mobile engineers.',
          isMentorPublic: true,
          mentorExpertise: const ['Flutter'],
          mentorExperienceYears: 7,
          createdAt: now,
          updatedAt: now,
        );
        const studentSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 's1',
          displayName: 'Aline Uwase',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        const mentorSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm1',
          displayName: 'Claire Mukamana',
          role: UserRole.mentor,
          onboarded: true,
          accountExists: true,
        );

        // Student requests mentorship.
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('student-scope'),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(studentSession),
              ),
              mentorshipRepositoryProvider.overrideWithValue(mentorshipRepo),
              userProfileProvider('m1')
                  .overrideWith((ref) => Stream.value(mentorProfile)),
              userProfileProvider('s1')
                  .overrideWith((ref) => Stream.value(null)),
              studentRequestsProvider('s1').overrideWith(
                (ref) => mentorshipRepo.watchStudentRequests('s1'),
              ),
              studentMentorshipsProvider('s1').overrideWith(
                (ref) => mentorshipRepo.watchStudentMentorships('s1'),
              ),
            ],
            child: MaterialApp(
              theme: buildAppTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MentorDetailScreen(mentorUid: 'm1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Request mentorship'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.byType(TextField).last,
          'Looking for help building my Flutter capstone project in Kigali.',
        );
        await tester.ensureVisible(find.text('Request mentorship'));
        await tester.tap(find.text('Request mentorship'));
        await tester.pumpAndSettle();
        expect(mentorshipRepo.requests, hasLength(1));

        // Mentor accepts request, creating mentorship.
        final router = GoRouter(
          initialLocation: '/m/requests',
          routes: [
            GoRoute(
              path: '/m/requests',
              builder: (_, _) => const MentorRequestsScreen(),
            ),
            GoRoute(
              path: '/mentorship/:id',
              builder: (_, s) =>
                  MentorshipDetailScreen(mentorshipId: s.pathParameters['id']!),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('mentor-scope'),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(mentorSession),
              ),
              mentorshipRepositoryProvider.overrideWithValue(mentorshipRepo),
              sessionRepositoryProvider.overrideWithValue(sessionRepo),
              mentorRequestsProvider(
                'm1',
              ).overrideWith((ref) => mentorshipRepo.watchMentorRequests('m1')),
              mentorshipSessionsProvider('req-1').overrideWith(
                (ref) => sessionRepo.watchMentorshipSessions('req-1'),
              ),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();
        expect(mentorshipRepo.mentorships, hasLength(1));
        expect(find.text('Schedule session'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Spark unsigned Cloudinary upload, validation, replace & unlink lifecycle',
      (tester) async {
        final deleted = <String>[];
        var counter = 0;

        final cloudinary = CloudinaryMediaService(
          onDeleteRemoteAsset: (asset) async {
            deleted.add(asset.publicId);
            return true;
          },
          clientFactory: () => MockClient((request) async {
            counter++;
            expect(
              request.url.toString(),
              'https://api.cloudinary.com/v1_1/vbzq5ssu/image/upload',
            );
            return http.Response(
              jsonEncode({
                'secure_url':
                    'https://res.cloudinary.com/vbzq5ssu/image/upload/v$counter/avatar.jpg',
                'public_id': 'upbridge/users/u1/avatar_$counter',
                'resource_type': 'image',
                'bytes': 2048,
              }),
              200,
            );
          }),
        );

        await expectLater(
          cloudinary.uploadImage(
            file: PickedUploadFile(
              name: 'cv.pdf',
              bytes: Uint8List.fromList([1, 2, 3]),
              contentType: 'application/pdf',
              resourceType: 'raw',
            ),
            ownerUid: 'u1',
            category: 'cvs',
          ),
          throwsException,
        );

        final replacement = await cloudinary.replaceFile(
          newFile: PickedUploadFile(
            name: 'new_avatar.jpg',
            bytes: Uint8List.fromList([5, 6, 7, 8]),
            contentType: 'image/jpeg',
            resourceType: 'image',
          ),
          ownerUid: 'u1',
          category: 'avatars',
          previousAsset: MediaAsset(
            url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/old.jpg',
            publicId: 'upbridge/users/u1/old_avatar',
            resourceType: 'image',
            size: 1024,
            ownerUid: 'u1',
            createdAt: now,
          ),
        );

        expect(replacement.publicId, 'upbridge/users/u1/avatar_1');
        expect(deleted, ['upbridge/users/u1/old_avatar']);
      },
    );

    testWidgets(
      '5. Bottom-tab navigation isolates branches and resets cleanly on re-tap',
      (tester) async {
        const student = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 's1',
          displayName: 'Aline Uwase',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, _, shell) =>
                  RoleShell(role: UserRole.student, navigationShell: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/home',
                      builder: (_, _) => const Center(child: Text('Tab Home')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/learn',
                      builder: (_, _) => const Center(child: Text('Tab Learn')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/mentors',
                      builder: (_, _) =>
                          const Center(child: Text('Tab Mentors')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/jobs',
                      builder: (_, _) => const Center(child: Text('Tab Jobs')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/profile',
                      builder: (_, _) =>
                          const Center(child: Text('Tab Profile')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('mentor-scope'),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(student)),
              liveUnreadNotificationCountProvider('s1')
                  .overrideWith((ref) => Stream.value(0)),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Learn'));
        await tester.pumpAndSettle();
        expect(find.text('Tab Learn'), findsOneWidget);

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Tab Profile'), findsOneWidget);

        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('Tab Home'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Mentor 5-tab shell renders Dashboard, Courses, Requests, Mentees, Profile and revocation redirects back to /home',
      (tester) async {
        const activeMentor = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm1',
          displayName: 'Claire Mukamana',
          role: UserRole.mentor,
          onboarded: true,
          accountExists: true,
        );
        const revokedAsStudent = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm1',
          displayName: 'Claire Mukamana',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );

        final router = GoRouter(
          initialLocation: '/m/home',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, _, shell) =>
                  RoleShell(role: UserRole.mentor, navigationShell: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/m/home',
                      builder: (_, _) => const Center(child: Text('Mentor Home')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/m/courses',
                      builder: (_, _) =>
                          const Center(child: Text('Mentor Courses Tab')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/m/requests',
                      builder: (_, _) =>
                          const Center(child: Text('Mentor Requests Tab')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/m/mentees',
                      builder: (_, _) =>
                          const Center(child: Text('Mentor Mentees Tab')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/m/profile',
                      builder: (_, _) =>
                          const Center(child: Text('Mentor Profile Tab')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('mentor-shell-e2e'),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(activeMentor)),
              mentorRequestsProvider('m1').overrideWith(
                (ref) => Stream.value(const []),
              ),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mentor Home'), findsOneWidget);
        await tester.tap(find.text('Courses'));
        await tester.pumpAndSettle();
        expect(find.text('Mentor Courses Tab'), findsOneWidget);

        await tester.tap(find.text('Requests'));
        await tester.pumpAndSettle();
        expect(find.text('Mentor Requests Tab'), findsOneWidget);

        expect(
          evaluateSessionRedirect(
            session: revokedAsStudent,
            location: '/m/courses',
            publicRoutes: kPublicRoutes,
            sharedRoutes: kSharedExactRoutes,
          ),
          AppRoutes.studentHome,
        );
      },
    );

    testWidgets(
      '7. Mentor lifecycle: pending restriction -> admin rejection -> resubmission -> approval -> course publish -> revocation recovery',
      (tester) async {
        final initialApp = MentorApplication(
          id: 'm2',
          ownerUid: 'm2',
          applicantName: 'Eric Nshuti',
          applicantEmail: 'eric@upbridge.rw',
          headline: 'Cloud Infrastructure Lead',
          profession: 'Site Reliability Architect',
          bio: 'Supporting Rwandan youth building resilient backends.',
          expertise: const ['Cloud & DevOps'],
          experienceYears: 6,
          createdAt: now,
          updatedAt: now,
        );
        final appRepo = _FakeMentorAppRepo(initialApp);
        final adminOps = _FakeStatefulAdminOperations(appRepo);

        final pendingSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm2',
          displayName: 'Eric Nshuti',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
          mentorApplication: appRepo.application,
        );
        expect(
          evaluateSessionRedirect(
            session: pendingSession,
            location: AppRoutes.studentHome,
          ),
          AppRoutes.mentorPending,
        );
        expect(
          evaluateSessionRedirect(
            session: pendingSession,
            location: '/m/courses',
          ),
          AppRoutes.mentorPending,
        );

        // Admin rejects pending application with reason -> applicant transitions Rejected -> Pending on resubmit.
        await adminOps.reviewMentorApplication(
          applicantUid: 'm2',
          decision: MentorApplicationStatus.rejected,
          reason: 'Please add verifiable community workshop history.',
        );
        expect(appRepo.application?.status, MentorApplicationStatus.rejected);

        final rejectedSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm2',
          displayName: 'Eric Nshuti',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
          mentorApplication: appRepo.application,
        );
        expect(
          evaluateSessionRedirect(
            session: rejectedSession,
            location: AppRoutes.mentorHome,
          ),
          AppRoutes.mentorPending,
        );

        await appRepo.submitApplication(
          appRepo.application!.copyWith(
            bio: '6+ years leading community cloud workshops in Kigali.',
            status: MentorApplicationStatus.pending,
            rejectionReason: '',
          ),
        );
        await adminOps.reviewMentorApplication(
          applicantUid: 'm2',
          decision: MentorApplicationStatus.approved,
        );
        expect(appRepo.application?.status, MentorApplicationStatus.approved);

        // Promoted mentor can publish courses cleanly inside mentor route.
        const approvedMentor = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm2',
          displayName: 'Eric Nshuti',
          role: UserRole.mentor,
          onboarded: true,
          accountExists: true,
        );
        expect(
          evaluateSessionRedirect(
            session: approvedMentor,
            location: AppRoutes.mentorHome,
          ),
          isNull,
        );

        final course = Course(
          id: 'c-cloud-1',
          ownerUid: 'm2',
          ownerName: 'Eric Nshuti',
          title: 'Cloud Deployment Fundamentals',
          summary: 'Deploy scalable Spark and cloud-native web apps.',
          status: CourseStatus.published,
          createdAt: now,
          updatedAt: now,
        );
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('journey7-course-preview'),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(approvedMentor)),
              courseDetailProvider('c-cloud-1').overrideWith((ref) => Stream.value(course)),
            ],
            child: MaterialApp(
              theme: buildAppTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const CourseDetailScreen(courseId: 'c-cloud-1', previewOnly: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cloud Deployment Fundamentals'), findsAtLeastNWidgets(1));

        // Revocation restores student role with revoked application -> routed safely to /mentor-pending.
        await adminOps.revokeMentorRole(
          targetUid: 'm2',
          reason: 'Temporarily paused availability',
        );
        final revokedSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm2',
          displayName: 'Eric Nshuti',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
          mentorApplication: appRepo.application,
        );
        expect(
          evaluateSessionRedirect(
            session: revokedSession,
            location: AppRoutes.mentorHome,
          ),
          AppRoutes.mentorPending,
        );
        expect(
          evaluateSessionRedirect(
            session: revokedSession,
            location: AppRoutes.studentHome,
          ),
          AppRoutes.mentorPending,
        );
      },
    );
  });
}

class _FakeMentorAppRepo implements MentorApplicationRepository {
  _FakeMentorAppRepo(this.application);
  MentorApplication? application;

  void markApproved() {
    application = application?.copyWith(
      status: MentorApplicationStatus.approved,
    );
  }

  @override
  Future<MentorApplication?> getApplication(String uid) async => application;

  @override
  Future<void> submitApplication(MentorApplication app) async {
    application = app;
  }

  @override
  Stream<List<MentorApplication>> watchApplications({
    MentorApplicationStatus? status,
    int limit = 50,
  }) => Stream.value(application == null ? const [] : [application!]);

  @override
  Stream<MentorApplication?> watchOwnApplication(String uid) =>
      Stream.value(application);
}

class _FakeAdminOperations implements AdminOperationsClient {
  _FakeAdminOperations({this.onApprove});
  final VoidCallback? onApprove;
  final List<String> approvedUids = [];

  @override
  Future<AdminActionResult> reviewMentorApplication({
    required String applicantUid,
    required MentorApplicationStatus decision,
    String reason = '',
  }) async {
    if (decision == MentorApplicationStatus.approved) {
      approvedUids.add(applicantUid);
      onApprove?.call();
      return const AdminActionResult(
        completed: true,
        message: 'Mentor approved',
      );
    }
    return const AdminActionResult(
      completed: true,
      message: 'Application rejected',
    );
  }

  @override
  Future<AdminActionResult> retryApprovalEmail({
    required String applicantUid,
  }) async => const AdminActionResult(completed: true, message: 'Email sent');

  @override
  Future<AdminActionResult> revokeMentorRole({
    required String targetUid,
    required String reason,
  }) async => const AdminActionResult(
    completed: true,
    message: 'Mentor privileges revoked',
  );

  @override
  Future<AdminActionResult> setUserAccountStatus({
    required String targetUid,
    required AccountStatus status,
    String reason = '',
  }) async => AdminActionResult(
    completed: true,
    message: status == AccountStatus.deactivated
        ? 'Account deactivated'
        : 'Account reactivated',
  );
}

class _FakeE2EMentorshipRepo implements MentorshipRepository {
  final List<MentorRequest> requests = [];
  final List<Mentorship> mentorships = [];
  final _reqCtrl = StreamController<List<MentorRequest>>.broadcast();
  final _msCtrl = StreamController<List<Mentorship>>.broadcast();

  @override
  Future<String> sendRequest(MentorRequest request) async {
    final created = MentorRequest(
      id: 'req-${requests.length + 1}',
      ownerUid: request.ownerUid,
      studentUid: request.studentUid,
      studentName: request.studentName,
      mentorUid: request.mentorUid,
      mentorName: request.mentorName,
      message: request.message,
      goals: request.goals,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
    );
    requests.add(created);
    _reqCtrl.add(List.unmodifiable(requests));
    return created.id;
  }

  @override
  Future<String> acceptRequest({
    required String requestId,
    String responseNote = '',
  }) async {
    final req = requests.firstWhere((r) => r.id == requestId);
    final ms = Mentorship(
      id: requestId,
      ownerUid: req.studentUid,
      studentUid: req.studentUid,
      studentName: req.studentName,
      mentorUid: req.mentorUid,
      mentorName: req.mentorName,
      requestId: requestId,
      goalSummary: req.goals,
      createdAt: req.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    mentorships.add(ms);
    _msCtrl.add(List.unmodifiable(mentorships));
    return ms.id;
  }

  @override
  Future<void> cancelRequest(String requestId) async {}

  @override
  Future<void> completeOrEndMentorship({
    required String mentorshipId,
    required MentorshipStatus nextStatus,
    required String actorUid,
    int? feedbackRating,
    String feedbackComment = '',
  }) async {}

  @override
  Future<void> declineRequest({
    required String requestId,
    String responseNote = '',
  }) async {}

  @override
  Future<Mentorship?> getMentorship(String mentorshipId) async =>
      mentorships.where((m) => m.id == mentorshipId).firstOrNull;

  @override
  Stream<Mentorship?> watchMentorship(String mentorshipId) async* {
    yield mentorships.where((m) => m.id == mentorshipId).firstOrNull;
    await for (final list in _msCtrl.stream) {
      yield list.where((m) => m.id == mentorshipId).firstOrNull;
    }
  }

  @override
  Stream<List<MentorRequest>> watchMentorRequests(
    String mentorUid, {
    MentorRequestStatus? status,
    int limit = 50,
  }) async* {
    yield List.unmodifiable(requests);
    yield* _reqCtrl.stream;
  }

  @override
  Stream<List<MentorRequest>> watchStudentRequests(
    String studentUid, {
    int limit = 50,
  }) async* {
    yield List.unmodifiable(requests);
    yield* _reqCtrl.stream;
  }

  @override
  Stream<List<Mentorship>> watchMentorMentorships(
    String mentorUid, {
    int limit = 50,
  }) => Stream.value(List.unmodifiable(mentorships));

  @override
  Stream<List<Mentorship>> watchStudentMentorships(
    String studentUid, {
    int limit = 50,
  }) => Stream.value(List.unmodifiable(mentorships));
}

class _FakeE2ESessionRepo implements SessionRepository {
  @override
  Future<String> scheduleSession(MentorshipSession session) async => 'sess-1';

  @override
  Future<void> rescheduleSession({
    required String sessionId,
    required DateTime scheduledAt,
    int? durationMinutes,
    String? meetingMode,
    String? meetingLink,
    String? topic,
    String? actorUid,
  }) async {}

  @override
  Future<void> transitionSession({
    required String sessionId,
    required SessionStatus nextStatus,
    String notes = '',
    String cancelReason = '',
    String? actorUid,
  }) async {}

  @override
  Future<void> updateSessionNotes({
    required String sessionId,
    required String notes,
  }) async {}

  @override
  Stream<List<MentorshipSession>> watchMentorSessions(
    String mentorUid, {
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Stream<List<MentorshipSession>> watchMentorshipSessions(
    String mentorshipId, {
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Stream<List<MentorshipSession>> watchStudentSessions(
    String studentUid, {
    int limit = 50,
  }) => Stream.value(const []);
}

class _FakeStatefulAdminOperations implements AdminOperationsClient {
  _FakeStatefulAdminOperations(this.appRepo);
  final _FakeMentorAppRepo appRepo;

  @override
  Future<AdminActionResult> reviewMentorApplication({
    required String applicantUid,
    required MentorApplicationStatus decision,
    String reason = '',
  }) async {
    appRepo.application = appRepo.application?.copyWith(
      status: decision,
      rejectionReason: reason,
    );
    return AdminActionResult(completed: true, message: decision.label);
  }

  @override
  Future<AdminActionResult> retryApprovalEmail({
    required String applicantUid,
  }) async => const AdminActionResult(completed: true, message: 'Email sent');

  @override
  Future<AdminActionResult> revokeMentorRole({
    required String targetUid,
    required String reason,
  }) async {
    appRepo.application = appRepo.application?.copyWith(
      status: MentorApplicationStatus.revoked,
      rejectionReason: reason,
    );
    return const AdminActionResult(
      completed: true,
      message: 'Mentor privileges revoked',
    );
  }

  @override
  Future<AdminActionResult> setUserAccountStatus({
    required String targetUid,
    required AccountStatus status,
    String reason = '',
  }) async => AdminActionResult(completed: true, message: status.label);
}
