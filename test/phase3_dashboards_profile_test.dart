import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/admin/domain/models/audit_log_entry.dart';
import 'package:upbridge/features/admin/domain/models/platform_metrics.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_overview_screen.dart';
import 'package:upbridge/features/admin/presentation/widgets/catalog_editor_sheets.dart';
import 'package:upbridge/features/home/presentation/pages/student_dashboard_screen.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/features/learning/domain/repositories/course_repository.dart';
import 'package:upbridge/features/learning/presentation/pages/courses_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_dashboard_screen.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentorship_repository.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/features/opportunities/domain/repositories/opportunity_repository.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunities_screen.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/features/profile/presentation/pages/profile_screen.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  final now = DateTime.utc(2026, 11, 19, 10);

  Widget wrap(Widget child, List overrides) => ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  group('Phase 3 Role Dashboards & Profile', () {
    testWidgets(
      'StudentDashboardScreen hides empty mentorship and session cards when none exist',
      (tester) async {
        const session = AppSession(
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
          wrap(const StudentDashboardScreen(), [
            appSessionProvider.overrideWith((ref) => Stream.value(session)),
            liveUnreadNotificationCountProvider('student-1')
                .overrideWith((ref) => Stream.value(0)),
            userProfileProvider('student-1')
                .overrideWith((ref) => Stream.value(null)),
            studentMentorshipsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            studentSessionsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
            userCourseProgressProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            approvedMentorsProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
            publishedOpportunitiesProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hello, Aline'), findsWidgets);
        expect(find.text('No active mentorship yet'), findsNothing);
        expect(find.text('No upcoming session'), findsNothing);
        expect(find.text('ACTIVE MENTORSHIP'), findsNothing);
        expect(find.text('UPCOMING SESSION'), findsNothing);
      },
    );

    testWidgets(
      'StudentDashboardScreen displays live active mentorship, upcoming session, courses & opportunities',
      (tester) async {
        const session = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'student-1',
          displayName: 'Aline Uwase',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        final profile = UserProfile(
          id: 'student-1',
          ownerUid: 'student-1',
          displayName: 'Aline Uwase',
          headline: 'CS Student',
          location: 'Kigali',
          about: 'Building Flutter apps.',
          skills: const ['Flutter', 'Dart'],
          createdAt: now,
          updatedAt: now,
        );
        final mentorship = Mentorship(
          id: 'ms-1',
          ownerUid: 'student-1',
          studentUid: 'student-1',
          studentName: 'Aline Uwase',
          mentorUid: 'mentor-1',
          mentorName: 'Jean Paul Habimana',
          requestId: 'ms-1',
          goalSummary: 'Ship mobile MVP',
          createdAt: now,
          updatedAt: now,
        );
        final upcoming = MentorshipSession(
          id: 'sess-1',
          ownerUid: 'mentor-1',
          mentorshipId: 'ms-1',
          studentUid: 'student-1',
          studentName: 'Aline Uwase',
          mentorUid: 'mentor-1',
          mentorName: 'Jean Paul Habimana',
          topic: 'Architecture review',
          scheduledAt: now.add(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
        );
        final course = Course(
          id: 'c-1',
          ownerUid: 'admin-1',
          title: 'Flutter Essentials',
          summary: 'Build cross-platform apps.',
          status: CourseStatus.published,
          createdAt: now,
          updatedAt: now,
        );
        final opp = OpportunityListing(
          id: 'opp-1',
          ownerUid: 'admin-1',
          title: 'Junior Mobile Intern',
          organization: 'Kigali Labs',
          location: 'Kigali',
          description: 'Internship role.',
          deadline: now.add(const Duration(days: 20)),
          status: OpportunityStatus.published,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(const StudentDashboardScreen(), [
            appSessionProvider.overrideWith((ref) => Stream.value(session)),
            liveUnreadNotificationCountProvider('student-1')
                .overrideWith((ref) => Stream.value(2)),
            userProfileProvider('student-1')
                .overrideWith((ref) => Stream.value(profile)),
            studentMentorshipsProvider('student-1')
                .overrideWith((ref) => Stream.value([mentorship])),
            studentSessionsProvider('student-1')
                .overrideWith((ref) => Stream.value([upcoming])),
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value([course]),
            ),
            userCourseProgressProvider('student-1').overrideWith(
              (ref) => Stream.value([
                CourseProgress(
                  id: 'student-1_c-1',
                  ownerUid: 'student-1',
                  courseId: 'c-1',
                  courseTitle: 'Flutter Essentials',
                  status: CourseProgressStatus.completed,
                  progressPercent: 100,
                  createdAt: now,
                  updatedAt: now,
                ),
              ]),
            ),
            approvedMentorsProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
            publishedOpportunitiesProvider.overrideWith(
              (ref) => Stream.value([opp]),
            ),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jean Paul Habimana'), findsWidgets);
        expect(find.text('Architecture review'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('Junior Mobile Intern'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Junior Mobile Intern'), findsOneWidget);
      },
    );

    testWidgets(
      'MentorDashboardScreen renders pending requests, sessions, and mentees and handles decline',
      (tester) async {
        const session = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'mentor-1',
          displayName: 'Jean Paul Habimana',
          role: UserRole.mentor,
          onboarded: true,
          accountExists: true,
        );
        final req = MentorRequest(
          id: 'req-1',
          ownerUid: 'student-1',
          studentUid: 'student-1',
          studentName: 'Aline Uwase',
          mentorUid: 'mentor-1',
          mentorName: 'Jean Paul Habimana',
          message: 'Looking for guidance on my capstone Flutter app.',
          goals: 'Ship portfolio project',
          createdAt: now,
          updatedAt: now,
        );
        final fakeRepo = _SpyMentorshipRepository();

        await tester.pumpWidget(
          wrap(const MentorDashboardScreen(), [
            appSessionProvider.overrideWith((ref) => Stream.value(session)),
            mentorshipRepositoryProvider.overrideWithValue(fakeRepo),
            liveUnreadNotificationCountProvider('mentor-1')
                .overrideWith((ref) => Stream.value(0)),
            mentorRequestsProvider('mentor-1')
                .overrideWith((ref) => Stream.value([req])),
            mentorMentorshipsProvider('mentor-1')
                .overrideWith((ref) => Stream.value(const [])),
            mentorSessionsProvider('mentor-1')
                .overrideWith((ref) => Stream.value(const [])),
            userProfileProvider('mentor-1')
                .overrideWith((ref) => Stream.value(null)),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hello, Jean'), findsWidgets);
        expect(find.text('Aline Uwase'), findsOneWidget);
        expect(find.text('Ship portfolio project'), findsOneWidget);
      },
    );

    testWidgets('AdminOverviewScreen renders live PlatformMetrics counts', (
      tester,
    ) async {
      const session = AppSession(
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
        totalUsers: 42,
        studentCount: 35,
        mentorCount: 6,
        pendingMentorApplications: 3,
        activeMentorships: 12,
        publishedCourses: 8,
        publishedOpportunities: 5,
      );

      final pendingApp = MentorApplication(
        id: 'u-pending',
        ownerUid: 'u-pending',
        applicantName: 'Claire Mukamana',
        applicantEmail: 'claire@upbridge.rw',
        headline: 'Senior Product Engineer',
        bio: 'Mentoring mobile builders in Kigali.',
        expertise: const ['Flutter'],
        experienceYears: 5,
        createdAt: now,
        updatedAt: now,
      );
      final logEntry = AuditLogEntry(
        id: 'log-1',
        ownerUid: 'admin-1',
        actorUid: 'admin-1',
        actorEmail: 'authapp05@gmail.com',
        action: 'mentor_application_approved',
        targetCollection: 'mentorApplications',
        targetId: 'u-1',
        details: 'Verified credentials',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        wrap(const AdminOverviewScreen(), [
          appSessionProvider.overrideWith((ref) => Stream.value(session)),
          liveUnreadNotificationCountProvider('admin-1')
              .overrideWith((ref) => Stream.value(1)),
          platformMetricsProvider.overrideWith((ref) async => metrics),
          pendingMentorApplicationsProvider.overrideWith(
            (ref) => Stream.value([pendingApp]),
          ),
          adminAuditLogsProvider.overrideWith((ref) => Stream.value([logEntry])),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Overview'), findsWidgets);
      expect(find.text('Platform activity and management'), findsOneWidget);
      expect(find.text('ADMIN COMMAND CENTER'), findsNothing);
      expect(find.text('New course'), findsOneWidget);
      expect(find.text('Post opportunity'), findsOneWidget);
      expect(find.text('Manage users'), findsOneWidget);
      expect(find.text('3 mentor applications waiting'), findsOneWidget);
      expect(find.text('Claire Mukamana'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Approved mentor application'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Approved mentor application'), findsOneWidget);
      expect(find.textContaining('Cloud Functions'), findsNothing);
    });

    testWidgets(
      'ProfileScreen presents complete CV and portfolio sections from live Firestore streams',
      (tester) async {
        const session = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'student-1',
          email: 'aline@upbridge.rw',
          displayName: 'Aline Uwase',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        final profile = UserProfile(
          id: 'student-1',
          ownerUid: 'student-1',
          displayName: 'Aline Uwase',
          headline: 'Mobile Engineering Fellow',
          location: 'Kigali, Rwanda',
          about: 'Passionate about fintech and youth education tools.',
          skills: const ['Dart', 'Flutter', 'Cloud Firestore'],
          education: const [
            EducationEntry(
              id: 'ed-1',
              institution: 'University of Rwanda',
              program: 'BSc Software Engineering',
              period: '2022–2026',
            ),
          ],
          experience: const [
            ExperienceEntry(
              id: 'ex-1',
              roleTitle: 'Flutter Intern',
              organization: 'Norrsken Kigali',
              period: 'Summer 2025',
            ),
          ],
          certificates: const [
            CertificateEntry(
              id: 'cert-1',
              title: 'Google Associate Android Dev',
              issuer: 'Google',
              issuedDate: '2025',
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );
        final project = PortfolioProject(
          id: 'proj-1',
          ownerUid: 'student-1',
          title: 'AgriTrack Rwanda',
          description: 'Offline-first farm cooperative ledger app.',
          skills: const ['Flutter', 'SQLite'],
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(const ProfileScreen(), [
            appSessionProvider.overrideWith((ref) => Stream.value(session)),
            userProfileProvider('student-1')
                .overrideWith((ref) => Stream.value(profile)),
            userProjectsProvider('student-1')
                .overrideWith((ref) => Stream.value([project])),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aline Uwase'), findsWidgets);
        expect(find.text('Mobile Engineering Fellow'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('AgriTrack Rwanda'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('AgriTrack Rwanda'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('University of Rwanda · 2022–2026'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('BSc Software Engineering'), findsOneWidget);
      },
    );

    testWidgets(
      'CourseEditorSheet supports custom categories, levels, custom skills, and publish-immediately creation',
      (tester) async {
        final courseSpy = _SpyCourseRepository();
        Future<void> enterField(String label, String text) async {
          final target = find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == label,
          );
          await tester.ensureVisible(target);
          await tester.enterText(
            find.descendant(of: target, matching: find.byType(TextField)),
            text,
          );
          await tester.pump();
        }

        await tester.pumpWidget(
          wrap(const Scaffold(body: CourseEditorSheet(adminUid: 'admin-1')), [
            courseRepositoryProvider.overrideWithValue(courseSpy),
          ]),
        );
        await tester.pumpAndSettle();

        await enterField('Course title', 'Drone Mapping for AgriTech');
        await enterField(
          'Summary',
          'Collect aerial data and map Rwandan smallholder farms.',
        );

        final customCategoryChip = find.text('Custom Category');
        await tester.ensureVisible(customCategoryChip);
        await tester.tap(customCategoryChip);
        await tester.pumpAndSettle();

        await enterField('Custom category name', 'Robotics & IoT');

        final bootcampChip = find.text('Bootcamp');
        await tester.ensureVisible(bootcampChip);
        await tester.tap(bootcampChip);
        await tester.pump();

        await enterField('Add custom skill(s)', 'Photogrammetry, QGIS');
        final addButton = find.widgetWithText(AppButton, 'Add');
        await tester.ensureVisible(addButton);
        await tester.tap(addButton);
        await tester.pump();

        await enterField('Module title', 'Flight Safety & Calibration');
        await enterField(
          'Summary / lesson notes (optional)',
          'Pre-flight check',
        );
        await enterField(
          'Resource URL (optional)',
          'https://example.com/drone',
        );

        final publishBtn = find.text('Publish course');
        await tester.ensureVisible(publishBtn);
        await tester.tap(publishBtn);
        await tester.pumpAndSettle();

        expect(courseSpy.savedCourses, hasLength(1));
        final saved = courseSpy.savedCourses.single;
        expect(saved.category, CourseCategory.custom);
        expect(saved.customCategory, 'Robotics & IoT');
        expect(saved.displayCategory, 'Robotics & IoT');
        expect(saved.level, 'Bootcamp');
        expect(saved.skills, containsAll(['Photogrammetry', 'QGIS']));
        expect(saved.modules.single.title, 'Flight Safety & Calibration');
        expect(saved.modules.single.resourceUrl, 'https://example.com/drone');
        expect(saved.status, CourseStatus.published);
      },
    );

    testWidgets(
      'OpportunityEditorSheet supports custom types, work modes, compensation, and immediate publish',
      (tester) async {
        final oppSpy = _SpyOpportunityRepository();
        Future<void> enterField(String label, String text) async {
          final target = find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == label,
          );
          await tester.ensureVisible(target);
          await tester.enterText(
            find.descendant(of: target, matching: find.byType(TextField)),
            text,
          );
          await tester.pump();
        }

        await tester.pumpWidget(
          wrap(
            const Scaffold(body: OpportunityEditorSheet(adminUid: 'admin-1')),
            [opportunityRepositoryProvider.overrideWithValue(oppSpy)],
          ),
        );
        await tester.pumpAndSettle();

        await enterField(
          'Role or program title',
          'Kigali Seed Venture Residency',
        );
        await enterField('Organization / host', 'Norssken House Kigali');

        final remoteChip = find.text('Remote');
        await tester.ensureVisible(remoteChip);
        await tester.tap(remoteChip);
        await tester.pump();

        final customTypeChip = find.text('Custom Type');
        await tester.ensureVisible(customTypeChip);
        await tester.tap(customTypeChip);
        await tester.pumpAndSettle();

        await enterField('Custom opportunity type', 'Venture Grant');
        await enterField(
          'Compensation details (optional)',
          'RWF 1,500,000 seed stipend',
        );
        await enterField(
          'Description',
          'Six-month equity-free venture building residency for youth teams.',
        );

        final publishBtn = find.text('Publish opportunity');
        await tester.ensureVisible(publishBtn);
        await tester.tap(publishBtn);
        await tester.pumpAndSettle();

        expect(oppSpy.savedOpportunities, hasLength(1));
        final saved = oppSpy.savedOpportunities.single;
        expect(saved.type, OpportunityType.custom);
        expect(saved.customType, 'Venture Grant');
        expect(saved.displayType, 'Venture Grant');
        expect(saved.workMode, 'Remote');
        expect(saved.compensation, 'RWF 1,500,000 seed stipend');
        expect(saved.status, OpportunityStatus.published);
      },
    );

    testWidgets(
      'CoursesScreen renders dynamic custom filter chips and filters items',
      (tester) async {
        const studentSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'student-1',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        final courses = [
          Course(
            id: 'c1',
            ownerUid: 'admin-1',
            title: 'Dart Foundations',
            summary: 'Core syntax and collections.',
            category: CourseCategory.it,
            status: CourseStatus.published,
            createdAt: now,
            updatedAt: now,
          ),
          Course(
            id: 'c2',
            ownerUid: 'admin-1',
            title: 'AgriTech Sensors',
            summary: 'Soil sensors for Rwandan cooperatives.',
            category: CourseCategory.custom,
            customCategory: 'Robotics & IoT',
            status: CourseStatus.published,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await tester.pumpWidget(
          wrap(const CoursesScreen(), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            publishedCoursesProvider.overrideWith(
              (ref) => Stream.value(courses),
            ),
            userCourseProgressProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Robotics & IoT'), findsWidgets);
        await tester.tap(find.text('Robotics & IoT').first);
        await tester.pumpAndSettle();
        expect(find.text('AgriTech Sensors'), findsOneWidget);
        expect(find.text('Dart Foundations'), findsNothing);
      },
    );

    testWidgets(
      'OpportunitiesScreen renders dynamic custom filter chips and filters items',
      (tester) async {
        const studentSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'student-1',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        final opportunities = [
          OpportunityListing(
            id: 'o1',
            ownerUid: 'admin-1',
            title: 'Mobile Intern',
            organization: 'Bank of Kigali',
            location: 'Kigali',
            type: OpportunityType.internship,
            description: 'Support Flutter releases.',
            deadline: now.add(const Duration(days: 20)),
            status: OpportunityStatus.published,
            createdAt: now,
            updatedAt: now,
          ),
          OpportunityListing(
            id: 'o2',
            ownerUid: 'admin-1',
            title: 'Youth Innovation Grant',
            organization: 'Rwanda ICT Chamber',
            location: 'Kigali',
            type: OpportunityType.custom,
            customType: 'Venture Grant',
            workMode: 'Hybrid',
            compensation: 'RWF 2,000,000',
            description: 'Non-dilutive youth prototype funding.',
            deadline: now.add(const Duration(days: 45)),
            status: OpportunityStatus.published,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await tester.pumpWidget(
          wrap(const OpportunitiesScreen(), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            publishedOpportunitiesProvider.overrideWith(
              (ref) => Stream.value(opportunities),
            ),
            userApplicationsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Venture Grant'), findsWidgets);
        expect(find.text('RWF 2,000,000'), findsOneWidget);
        await tester.tap(find.text('Venture Grant').first);
        await tester.pumpAndSettle();
        expect(find.text('Youth Innovation Grant'), findsOneWidget);
        expect(find.text('Mobile Intern'), findsNothing);
      },
    );
  });
}

class _SpyCourseRepository implements CourseRepository {
  final List<Course> savedCourses = [];

  @override
  Future<void> deleteCourse(String courseId) async {}

  @override
  Future<Course?> getCourse(String courseId) async => null;

  @override
  Stream<Course?> watchCourse(String courseId) => Stream.value(null);

  @override
  Stream<List<Course>> watchMentorCourses(String mentorUid, {int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<List<CourseProgress>> watchCourseEngagement(
    String courseId, {
    String? courseOwnerUid,
    int limit = 100,
  }) => Stream.value(const []);

  @override
  Future<String> saveCourse(Course course) async {
    savedCourses.add(course);
    return 'course-${savedCourses.length}';
  }

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
      Stream.value(savedCourses);

  @override
  Stream<CourseProgress?> watchCourseProgress(String uid, String courseId) =>
      Stream.value(null);

  @override
  Stream<List<Course>> watchPublishedCourses({int limit = 50}) =>
      Stream.value(savedCourses);

  @override
  Stream<List<CourseProgress>> watchUserProgress(
    String uid, {
    int limit = 50,
  }) => Stream.value(const []);
}

class _SpyOpportunityRepository implements OpportunityRepository {
  final List<OpportunityListing> savedOpportunities = [];

  @override
  Future<OpportunityListing?> getOpportunity(String opportunityId) async =>
      null;

  @override
  Stream<OpportunityListing?> watchOpportunity(String opportunityId) =>
      Stream.value(null);

  @override
  Stream<List<OpportunityApplication>> watchApplicationsForOpportunity(
    String opportunityId, {
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Future<void> reviewApplication({
    required String applicationId,
    required OpportunityApplicationStatus nextStatus,
  }) async {}

  @override
  Future<String> saveOpportunity(OpportunityListing listing) async {
    savedOpportunities.add(listing);
    return 'opp-${savedOpportunities.length}';
  }

  @override
  Future<void> submitApplication(OpportunityApplication application) async {}

  @override
  Future<void> transitionOpportunityStatus({
    required String opportunityId,
    required OpportunityStatus nextStatus,
  }) async {}

  @override
  Stream<List<OpportunityListing>> watchAll({int limit = 50}) =>
      Stream.value(savedOpportunities);

  @override
  Stream<OpportunityApplication?> watchApplicationFor(
    String uid,
    String opportunityId,
  ) => Stream.value(null);

  @override
  Stream<List<OpportunityListing>> watchPublished({int limit = 50}) =>
      Stream.value(savedOpportunities);

  @override
  Stream<List<OpportunityApplication>> watchUserApplications(
    String uid, {
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Future<void> withdrawApplication(String uid, String opportunityId) async {}
}

class _SpyMentorshipRepository implements MentorshipRepository {
  @override
  Future<String> acceptRequest({
    required String requestId,
    String responseNote = '',
  }) async => requestId;

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
  Future<Mentorship?> getMentorship(String mentorshipId) async => null;

  @override
  Stream<Mentorship?> watchMentorship(String mentorshipId) =>
      Stream.value(null);

  @override
  Future<String> sendRequest(MentorRequest request) async => 'req-new';

  @override
  Stream<List<Mentorship>> watchMentorMentorships(
    String mentorUid, {
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Stream<List<MentorRequest>> watchMentorRequests(
    String mentorUid, {
    MentorRequestStatus? status,
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Stream<List<Mentorship>> watchStudentMentorships(
    String studentUid, {
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Stream<List<MentorRequest>> watchStudentRequests(
    String studentUid, {
    int limit = 50,
  }) => Stream.value(const []);
}
