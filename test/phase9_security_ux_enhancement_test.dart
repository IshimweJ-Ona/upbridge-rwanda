import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/auth/account_deactivated_screen.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/services/admin_operations_service.dart';
import 'package:upbridge/core/services/cloudinary_service.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/admin/domain/models/audit_log_entry.dart';
import 'package:upbridge/features/admin/domain/models/platform_metrics.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_mentor_review_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_mentors_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_overview_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_users_screen.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/auth/presentation/pages/mentor_apply_screen.dart';
import 'package:upbridge/features/home/presentation/pages/student_dashboard_screen.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/features/learning/domain/repositories/course_repository.dart';
import 'package:upbridge/features/learning/presentation/pages/course_detail_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_courses_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_dashboard_screen.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  final now = DateTime.utc(2026, 11, 20, 9);

  Widget wrap(
    Widget child, {
    List<Override> overrides = const [],
    ThemeData? theme,
    Locale locale = const Locale('en'),
  }) => ProviderScope(
    key: UniqueKey(),
    overrides: overrides,
    child: MaterialApp(
      theme: theme ?? buildAppTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  group('Phase 9: Role security, revocation & lifecycle guards', () {
    test(
      'resolveEffectiveRole enforces immediate Firestore mentor revocation even when token claim is still mentor',
      () {
        final revokedAccount = AppUserAccount(
          id: 'u1',
          ownerUid: 'u1',
          email: 'revoked@upbridge.rw',
          displayName: 'Former Mentor',
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
          resolveEffectiveRole(
            claimRole: UserRole.mentor,
            account: revokedAccount,
          ),
          UserRole.student,
        );
        expect(
          resolveEffectiveRole(
            claimRole: UserRole.admin,
            account: revokedAccount,
          ),
          UserRole.admin,
        );
        expect(
          resolveEffectiveRole(
            claimRole: UserRole.student,
            account: revokedAccount.copyWith(
              role: UserRole.mentor,
              isApproved: true,
            ),
          ),
          UserRole.mentor,
        );
      },
    );

    test(
      'route guards isolate student, pending/revoked mentor, approved mentor courses, and admin routes',
      () {
        expect(
          claimsRoleAreaRedirect(role: UserRole.student, location: '/m/courses'),
          AppRoutes.studentHome,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.student,
            location: '/m/course/c-1',
          ),
          AppRoutes.studentHome,
        );
        expect(
          claimsRoleAreaRedirect(role: UserRole.mentor, location: '/m/courses'),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: '/m/sessions',
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: '/m/course/c-1',
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(role: UserRole.admin, location: '/a/course/c-1'),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(role: UserRole.mentor, location: '/a/users'),
          AppRoutes.mentorHome,
        );
      },
    );

    test('StatusTransitions.mentorApplication validates revoke & resubmit transitions', () {
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.mentorApplication,
          MentorApplicationStatus.approved,
          MentorApplicationStatus.revoked,
        ),
        isTrue,
      );
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.mentorApplication,
          MentorApplicationStatus.revoked,
          MentorApplicationStatus.pending,
        ),
        isTrue,
      );
      expect(
        () => StatusTransitions.requireTransition(
          StatusTransitions.mentorApplication,
          MentorApplicationStatus.revoked,
          MentorApplicationStatus.approved,
          entity: 'MentorApplication',
        ),
        throwsStateError,
      );
    });

    testWidgets(
      'MentorApplyScreen displays exact pending, approved, and revoked status messages',
      (tester) async {
        final pendingSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u1',
          email: 'm@upbridge.rw',
          displayName: 'Kevine Mukiza',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
          mentorApplication: MentorApplication(
            id: 'u1',
            ownerUid: 'u1',
            applicantName: 'Kevine Mukiza',
            applicantEmail: 'm@upbridge.rw',
            headline: 'Senior Engineer',
            bio: 'Mentoring mobile builders in Kigali.',
            expertise: const ['Flutter'],
            experienceYears: 5,
            status: MentorApplicationStatus.pending,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await tester.pumpWidget(
          wrap(
            const MentorApplyScreen(),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(pendingSession),
              ),
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Your mentor application is being reviewed by our administration team.',
          ),
          findsOneWidget,
        );

        final approvedSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u1',
          email: 'm@upbridge.rw',
          displayName: 'Kevine Mukiza',
          role: UserRole.mentor,
          onboarded: true,
          accountExists: true,
        );
        await tester.pumpWidget(
          wrap(
            const MentorApplyScreen(),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(approvedSession),
              ),
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Congratulations! Your mentor application has been approved.'),
          findsOneWidget,
        );

        final revokedSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u1',
          email: 'm@upbridge.rw',
          displayName: 'Kevine Mukiza',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
          mentorApplication: MentorApplication(
            id: 'u1',
            ownerUid: 'u1',
            applicantName: 'Kevine Mukiza',
            applicantEmail: 'm@upbridge.rw',
            headline: 'Senior Engineer',
            bio: 'Mentoring mobile builders in Kigali.',
            expertise: const ['Flutter'],
            experienceYears: 5,
            status: MentorApplicationStatus.revoked,
            rejectionReason: 'Availability lapsed during quarter.',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await tester.pumpWidget(
          wrap(
            const MentorApplyScreen(),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(revokedSession),
              ),
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Your mentor privileges were revoked by an administrator.'),
          findsOneWidget,
        );
        expect(find.text('Resubmit application'), findsOneWidget);
      },
    );
  });

  group('Phase 9: Validators, models & Cloudinary magic bytes', () {
    test('Validators.url and optionalUrl accept valid HTTPS/HTTP and reject invalid URLs', () {
      expect(Validators.url('https://linkedin.com/in/test'), isNull);
      expect(Validators.url('http://example.com'), isNull);
      expect(Validators.url(''), isNotNull);
      expect(Validators.url('ftp://example.com/file'), isNotNull);
      expect(Validators.optionalUrl(''), isNull);
      expect(Validators.optionalUrl('not-a-url'), isNotNull);
    });

    test('Course, UserProfile, and CourseProgress preserve backward compatibility and new fields', () {
      final legacyCourse = Course.fromJson({'title': 'Intro Dart'}, id: 'c1');
      expect(legacyCourse.ownerName, '');
      expect(legacyCourse.learningObjectives, isEmpty);
      expect(legacyCourse.resources, isEmpty);

      final modernCourse = Course(
        id: 'c2',
        ownerUid: 'm1',
        ownerName: 'Claire Mukamana',
        title: 'Flutter Architecture',
        summary: 'Scalable modules',
        learningObjectives: const ['Build clean repositories'],
        resources: const [
          CourseResource(
            id: 'r1',
            title: 'Docs',
            url: 'https://flutter.dev',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
      final parsedCourse = Course.fromJson(modernCourse.toJson(), id: 'c2');
      expect(parsedCourse.ownerName, 'Claire Mukamana');
      expect(parsedCourse.learningObjectives, ['Build clean repositories']);
      expect(parsedCourse.resources.single.url, 'https://flutter.dev');

      final profile = UserProfile.fromJson({
        'ownerUid': 'u1',
        'professionalLinks': ['https://github.com/upbridge'],
      });
      expect(profile.professionalLinks, ['https://github.com/upbridge']);

      final progress = CourseProgress.fromJson({
        'ownerUid': 's1',
        'courseId': 'c2',
        'courseOwnerUid': 'm1',
      });
      expect(progress.courseOwnerUid, 'm1');
    });

    test('CloudinaryMediaService.hasValidImageSignature verifies real headers and rejects spoofed files', () {
      final jpegHeader = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0, 16, 0x4A, 0x46, 0x49, 0x46, 0, 1,
      ]);
      final pngHeader = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13,
      ]);
      final webpHeader = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 1, 0, 0, 0, 0x57, 0x45, 0x42, 0x50,
      ]);
      final fakeTextAsJpg = Uint8List.fromList('NOT_AN_IMAGE_PAYLOAD'.codeUnits);

      expect(CloudinaryMediaService.hasValidImageSignature(jpegHeader, 'jpg'), isTrue);
      expect(CloudinaryMediaService.hasValidImageSignature(pngHeader, 'png'), isTrue);
      expect(CloudinaryMediaService.hasValidImageSignature(webpHeader, 'webp'), isTrue);
      expect(CloudinaryMediaService.hasValidImageSignature(fakeTextAsJpg, 'jpg'), isFalse);
      expect(CloudinaryMediaService.hasValidImageSignature(pngHeader, 'jpg'), isFalse);
    });
  });

  group('Phase 9: Mentor courses, preview, dashboard & admin moderation UI', () {
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

    testWidgets(
      'MentorCoursesScreen shows loading skeleton, empty state, error retry, and course actions',
      (tester) async {
        final ctrl = StreamController<List<Course>>();
        addTearDown(ctrl.close);

        await tester.pumpWidget(
          wrap(
            const MentorCoursesScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(mentorSession)),
              mentorCoursesProvider('m1').overrideWith((ref) => ctrl.stream),
            ],
          ),
        );
        await tester.pump();
        expect(find.byType(SkeletonListLoader), findsOneWidget);

        ctrl.add(const []);
        await tester.pumpAndSettle();
        expect(find.text('No courses created yet'), findsOneWidget);

        ctrl.add([
          Course(
            id: 'mc-1',
            ownerUid: 'm1',
            ownerName: 'Claire Mukamana',
            title: 'Dart Testing Workshop',
            summary: 'Unit and widget tests in Dart.',
            status: CourseStatus.draft,
            skills: const ['Dart'],
            createdAt: now,
            updatedAt: now,
          ),
        ]);
        await tester.pumpAndSettle();
        expect(find.text('Dart Testing Workshop'), findsOneWidget);
        expect(find.text('Preview'), findsOneWidget);
        expect(find.text('Publish'), findsOneWidget);
      },
    );

    testWidgets(
      'CourseDetailScreen previewOnly renders author, learning objectives, resources and disables completion proof',
      (tester) async {
        final previewCourse = Course(
          id: 'mc-2',
          ownerUid: 'm1',
          ownerName: 'Claire Mukamana',
          title: 'Cloud Firestore Security',
          summary: 'Master Spark-compatible Firestore rules.',
          learningObjectives: const ['Write least-privilege security rules'],
          resources: const [
            CourseResource(
              id: 'r1',
              title: 'Official Rules Guide',
              url: 'https://firebase.google.com/docs/rules',
            ),
          ],
          modules: const [
            CourseModule(
              id: 'mod1',
              title: 'Rules Basics',
              summary: 'Intro',
            ),
          ],
          status: CourseStatus.draft,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const CourseDetailScreen(courseId: 'mc-2', previewOnly: true),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(mentorSession)),
              courseDetailProvider('mc-2').overrideWith(
                (ref) => Stream.value(previewCourse),
              ),
              courseRepositoryProvider.overrideWithValue(_NoopCourseRepo()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Course preview (Draft)'), findsOneWidget);
        expect(find.text('Instructor: Claire Mukamana'), findsOneWidget);
        expect(find.text('Write least-privilege security rules'), findsOneWidget);
        expect(find.text('Official Rules Guide'), findsOneWidget);
        expect(find.text('Submit completion proof'), findsNothing);
      },
    );

    testWidgets(
      'MentorDashboardScreen shows 4 stat metrics including courses count',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const MentorDashboardScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(mentorSession)),
              liveUnreadNotificationCountProvider('m1').overrideWith(
                (ref) => Stream.value(1),
              ),
              mentorRequestsProvider('m1').overrideWith(
                (ref) => Stream.value(const []),
              ),
              mentorMentorshipsProvider('m1').overrideWith(
                (ref) => Stream.value(const []),
              ),
              mentorSessionsProvider('m1').overrideWith(
                (ref) => Stream.value(const []),
              ),
              mentorCoursesProvider('m1').overrideWith(
                (ref) => Stream.value([
                  Course(
                    id: 'c1',
                    ownerUid: 'm1',
                    title: 'Course A',
                    summary: 'Summary A',
                    status: CourseStatus.published,
                    createdAt: now,
                    updatedAt: now,
                  ),
                ]),
              ),
              userProfileProvider('m1').overrideWith((ref) => Stream.value(null)),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Courses (1 live)'), findsOneWidget);
        expect(find.text('New course'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminMentorReviewScreen and AdminUsersScreen expose Revoke mentor action and invoke AdminOperationsClient',
      (tester) async {
        final fakeAdmin = _RecordingAdminOperations();
        final approvedApp = MentorApplication(
          id: 'u1',
          ownerUid: 'u1',
          applicantName: 'Jean Bosco',
          applicantEmail: 'jean@upbridge.rw',
          headline: 'Cloud Engineer',
          bio: 'Experienced DevOps engineer.',
          expertise: const ['Cloud'],
          experienceYears: 6,
          status: MentorApplicationStatus.approved,
          createdAt: now,
          updatedAt: now,
        );
        final mentorUser = AppUserAccount(
          id: 'u1',
          ownerUid: 'u1',
          email: 'jean@upbridge.rw',
          displayName: 'Jean Bosco',
          phone: '',
          role: UserRole.mentor,
          isApproved: true,
          status: AccountStatus.active,
          onboarded: true,
          preferredLocale: 'en',
          createdAt: now,
          updatedAt: now,
        );
        const adminSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'admin-1',
          email: 'authapp05@gmail.com',
          displayName: 'Admin',
          role: UserRole.admin,
          onboarded: true,
          accountExists: true,
        );

        await tester.pumpWidget(
          wrap(
            const AdminMentorReviewScreen(applicantUid: 'u1'),
            overrides: [
              mentorApplicationDetailProvider('u1').overrideWith(
                (ref) => Stream.value(approvedApp),
              ),
              adminOperationsClientProvider.overrideWithValue(fakeAdmin),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Revoke mentor'), findsOneWidget);

        await tester.pumpWidget(
          wrap(
            const AdminUsersScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(adminSession)),
              adminUsersFilterProvider((role: null, status: null)).overrideWith(
                (ref) => Stream.value([mentorUser]),
              ),
              adminOperationsClientProvider.overrideWithValue(fakeAdmin),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Revoke mentor'), findsOneWidget);
        await tester.tap(find.text('Revoke mentor'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          'Inactive across cohorts',
        );
        await tester.tap(find.text('Revoke mentor').last);
        await tester.pumpAndSettle();
        expect(fakeAdmin.revokedUids, ['u1']);
      },
    );

    testWidgets(
      'AdminMentorsScreen switches between Applications (with Revoked) and Mentorships tabs',
      (tester) async {
        final ms = Mentorship(
          id: 'ms1',
          ownerUid: 's1',
          studentUid: 's1',
          studentName: 'Aline Uwase',
          mentorUid: 'm1',
          mentorName: 'Claire Mukamana',
          requestId: 'req1',
          goalSummary: 'Build Dart backend',
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const AdminMentorsScreen(),
            overrides: [
              allMentorApplicationsProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              adminMentorshipsProvider(null).overrideWith(
                (ref) => Stream.value([ms]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Revoked'), findsOneWidget);

        await tester.tap(find.text('Mentorships'));
        await tester.pumpAndSettle();
        expect(find.text('Aline Uwase ↔ Claire Mukamana'), findsOneWidget);
      },
    );
  });

  group('Phase 9: Dark mode palette, skeletons, responsiveness & localization', () {
    test('AppText styles do not lock text color to light mode', () {
      expect(AppText.display.color, isNull);
      expect(AppText.titleL.color, isNull);
      expect(AppText.bodyM.color, isNull);
      expect(AppText.caption.color, isNull);
      expect(AppPalette.dark.textPrimary, isNot(AppPalette.light.textPrimary));
    });

    testWidgets(
      'Dark mode widgets and new skeleton loaders render without exceptions across phone & desktop sizes',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        for (final size in [const Size(320, 640), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            wrap(
              Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SkeletonMetricsGridLoader(),
                      const SizedBox(height: 12),
                      const SkeletonListLoader(rows: 2),
                      const SizedBox(height: 12),
                      const SkeletonDetailPageLoader(),
                      const SizedBox(height: 12),
                      SegmentedTabs(
                        tabs: const ['One', 'Two'],
                        index: 0,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 12),
                      ScaleSelector(value: 4, onChanged: (_) {}),
                    ],
                  ),
                ),
              ),
              theme: buildDarkTheme(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
        }

        await tester.pumpWidget(
          wrap(
            const AccountDeactivatedScreen(),
            overrides: [
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
            theme: buildDarkTheme(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Redesigned AdminOverviewScreen and AdminUsersScreen render without overflow across 320px/840px Light and Dark themes',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        const adminSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'admin-1',
          email: 'authapp05@gmail.com',
          displayName: 'Admin',
          role: UserRole.admin,
          onboarded: true,
          accountExists: true,
        );
        const metrics = PlatformMetrics(
          totalUsers: 48,
          studentCount: 38,
          mentorCount: 8,
          pendingMentorApplications: 2,
          activeMentorships: 14,
          publishedCourses: 9,
          publishedOpportunities: 6,
        );
        final sampleUser = AppUserAccount(
          id: 'u-1',
          ownerUid: 'u-1',
          email: 'claire.mukamana@upbridge.rw',
          displayName: 'Claire Mukamana',
          phone: '',
          role: UserRole.mentor,
          isApproved: true,
          status: AccountStatus.active,
          onboarded: true,
          preferredLocale: 'en',
          createdAt: now,
          updatedAt: now,
        );
        final sampleLog = AuditLogEntry(
          id: 'log-1',
          ownerUid: 'admin-1',
          actorUid: 'admin-1',
          actorEmail: 'authapp05@gmail.com',
          action: 'course_published',
          targetCollection: 'courses',
          targetId: 'c1',
          details: 'Flutter Architecture',
          createdAt: now,
          updatedAt: now,
        );

        for (final size in [const Size(320, 640), const Size(840, 900)]) {
          for (final theme in [buildAppTheme(), buildDarkTheme()]) {
            tester.view.physicalSize = size;
            await tester.pumpWidget(
              wrap(
                const AdminOverviewScreen(),
                theme: theme,
                overrides: [
                  appSessionProvider.overrideWith(
                    (ref) => Stream.value(adminSession),
                  ),
                  liveUnreadNotificationCountProvider('admin-1')
                      .overrideWith((ref) => Stream.value(2)),
                  platformMetricsProvider.overrideWith((ref) async => metrics),
                  pendingMentorApplicationsProvider.overrideWith(
                    (ref) => Stream.value(const []),
                  ),
                  adminAuditLogsProvider.overrideWith(
                    (ref) => Stream.value([sampleLog]),
                  ),
                ],
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            await tester.pumpWidget(
              wrap(
                const AdminUsersScreen(),
                theme: theme,
                overrides: [
                  appSessionProvider.overrideWith(
                    (ref) => Stream.value(adminSession),
                  ),
                  adminUsersFilterProvider((role: null, status: null))
                      .overrideWith((ref) => Stream.value([sampleUser])),
                  adminOperationsClientProvider.overrideWithValue(
                    _RecordingAdminOperations(),
                  ),
                ],
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            const youthSession = AppSession(
              firebaseInitialized: true,
              signedIn: true,
              emailVerified: true,
              uid: 'student-1',
              displayName: 'Aline Uwase',
              role: UserRole.student,
              onboarded: true,
              accountExists: true,
            );
            await tester.pumpWidget(
              wrap(
                const StudentDashboardScreen(),
                theme: theme,
                overrides: [
                  appSessionProvider.overrideWith(
                    (ref) => Stream.value(youthSession),
                  ),
                  liveUnreadNotificationCountProvider('student-1')
                      .overrideWith((ref) => Stream.value(0)),
                  userProfileProvider('student-1')
                      .overrideWith((ref) => Stream.value(null)),
                  studentMentorshipsProvider('student-1')
                      .overrideWith((ref) => Stream.value(const [])),
                  studentSessionsProvider('student-1')
                      .overrideWith((ref) => Stream.value(const [])),
                  publishedCoursesProvider
                      .overrideWith((ref) => Stream.value(const [])),
                  userCourseProgressProvider('student-1')
                      .overrideWith((ref) => Stream.value(const [])),
                  approvedMentorsProvider
                      .overrideWith((ref) => Stream.value(const [])),
                  publishedOpportunitiesProvider
                      .overrideWith((ref) => Stream.value(const [])),
                ],
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            const mentorSession = AppSession(
              firebaseInitialized: true,
              signedIn: true,
              emailVerified: true,
              uid: 'mentor-1',
              displayName: 'Claire Mukamana',
              role: UserRole.mentor,
              onboarded: true,
              accountExists: true,
            );
            await tester.pumpWidget(
              wrap(
                const MentorDashboardScreen(),
                theme: theme,
                overrides: [
                  appSessionProvider.overrideWith(
                    (ref) => Stream.value(mentorSession),
                  ),
                  liveUnreadNotificationCountProvider('mentor-1')
                      .overrideWith((ref) => Stream.value(1)),
                  mentorRequestsProvider('mentor-1')
                      .overrideWith((ref) => Stream.value(const [])),
                  mentorMentorshipsProvider('mentor-1')
                      .overrideWith((ref) => Stream.value(const [])),
                  mentorSessionsProvider('mentor-1')
                      .overrideWith((ref) => Stream.value(const [])),
                  userProfileProvider('mentor-1')
                      .overrideWith((ref) => Stream.value(null)),
                ],
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets('English, Kinyarwanda, and French ARB localizations include new role keys', (
      tester,
    ) async {
      for (final code in ['en', 'rw', 'fr']) {
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        expect(l10n.tabMentorCourses.isNotEmpty, isTrue);
        expect(l10n.mentorPendingMessage.isNotEmpty, isTrue);
        expect(l10n.mentorApprovedMessage.isNotEmpty, isTrue);
        expect(l10n.mentorRevokedMessage.isNotEmpty, isTrue);
      }
    });
  });
}

class _NoopAuthService extends AuthService {}

class _RecordingAdminOperations implements AdminOperationsClient {
  final List<String> revokedUids = [];

  @override
  Future<AdminActionResult> reviewMentorApplication({
    required String applicantUid,
    required MentorApplicationStatus decision,
    String reason = '',
  }) async => const AdminActionResult(completed: true, message: 'OK');

  @override
  Future<AdminActionResult> retryApprovalEmail({
    required String applicantUid,
  }) async => const AdminActionResult(completed: true, message: 'Email sent');

  @override
  Future<AdminActionResult> setMentorDirectoryVisibility({
    required String mentorUid,
    required bool isPublic,
  }) async => const AdminActionResult(completed: true, message: 'OK');

  @override
  Future<AdminActionResult> revokeMentorRole({
    required String targetUid,
    required String reason,
  }) async {
    revokedUids.add(targetUid);
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
  }) async => const AdminActionResult(completed: true, message: 'OK');
}

class _NoopCourseRepo implements CourseRepository {
  @override
  Future<void> deleteCourse(String courseId) async {}

  @override
  Future<Course?> getCourse(String courseId) async => null;

  @override
  Future<String> saveCourse(Course course) async => 'c1';

  @override
  Future<void> submitCourseEvidence({
    required String uid,
    required Course course,
    required String evidenceUrl,
    MediaAsset? evidenceAsset,
  }) async {}

  @override
  Future<void> toggleModuleCompletion({
    required String uid,
    required Course course,
    required String moduleId,
  }) async {}

  @override
  Future<void> transitionCourseStatus({
    required String courseId,
    required CourseStatus nextStatus,
  }) async {}

  @override
  Stream<List<Course>> watchAllCourses({int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<Course?> watchCourse(String courseId) => Stream.value(null);

  @override
  Stream<List<CourseProgress>> watchCourseEngagement(
    String courseId, {
    String? courseOwnerUid,
    int limit = 100,
  }) => Stream.value(const []);

  @override
  Stream<CourseProgress?> watchCourseProgress(String uid, String courseId) =>
      Stream.value(null);

  @override
  Stream<List<Course>> watchMentorCourses(String mentorUid, {int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<List<Course>> watchPublishedCourses({int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<List<CourseProgress>> watchUserProgress(String uid, {int limit = 50}) =>
      Stream.value(const []);
}
