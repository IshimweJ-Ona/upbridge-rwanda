import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/auth/verify_email_screen.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/services/admin_operations_service.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_mentor_review_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/mentor_apply_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/mentor_pending_screen.dart';
import 'package:upbridge/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:upbridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:upbridge/features/home/presentation/pages/notifications_screen.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/presentation/pages/course_detail_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_dashboard_screen.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/notifications/domain/models/user_notification.dart';
import 'package:upbridge/features/notifications/domain/repositories/user_notification_repository.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/features/profile/presentation/pages/edit_profile_cv_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/project_editor_screen.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  final now = DateTime.utc(2026, 11, 22, 9);

  Widget wrap(Widget child, {List<Override> overrides = const []}) =>
      ProviderScope(
        key: UniqueKey(),
        overrides: overrides,
        child: MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  group('Phase 10: Registration redesign & role isolation', () {
    testWidgets(
      'SignUpScreen switches cleanly between Join as Youth and Apply as Mentor and validates Mentor sections',
      (tester) async {
        await tester.pumpWidget(wrap(const SignUpScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Join UpBridge Rwanda'), findsOneWidget);
        expect(find.text('Join as Youth'), findsOneWidget);
        expect(find.text('Apply as Mentor'), findsOneWidget);
        expect(find.text('Create Youth Account'), findsOneWidget);
        expect(find.text('PROFESSIONAL INFORMATION'), findsNothing);

        // Switch dynamically to Apply as Mentor without navigating away.
        await tester.tap(find.text('Apply as Mentor'));
        await tester.pumpAndSettle();

        expect(find.text('Submit Mentor Application'), findsOneWidget);
        expect(find.text('PROFESSIONAL INFORMATION'), findsOneWidget);
        expect(find.text('MENTORSHIP INFORMATION'), findsOneWidget);
        expect(find.text('SUPPORTING INFORMATION'), findsOneWidget);
        expect(
          find.text('Admin approval required before mentor access'),
          findsOneWidget,
        );

        // Submitting empty mentor form surfaces inline field validations.
        await tester.tap(find.text('Submit Mentor Application'));
        await tester.pumpAndSettle();
        expect(find.text('Enter your full name.'), findsOneWidget);
        expect(
          find.text('Enter your professional headline (min 3 characters).'),
          findsOneWidget,
        );
        expect(
          find.text('Enter your current profession or job title.'),
          findsOneWidget,
        );

        // Switching back to Youth collapses Mentor-specific sections cleanly.
        await tester.ensureVisible(find.text('Join as Youth'));
        await tester.tap(find.text('Join as Youth'));
        await tester.pumpAndSettle();
        expect(find.text('Create Youth Account'), findsOneWidget);
        expect(find.text('PROFESSIONAL INFORMATION'), findsNothing);
      },
    );

    testWidgets(
      'VerifyEmailScreen keeps email verification separate from mentor approval and routes mentor draft to /mentor-apply when Firebase offline',
      (tester) async {
        final fakeAuth = _FakeAuthService(email: 'mentor@upbridge.rw');
        final destinations = <String>[];

        await tester.pumpWidget(
          wrap(
            VerifyEmailScreen(onNavigate: destinations.add),
            overrides: [
              authServiceProvider.overrideWithValue(fakeAuth),
              registrationDraftProvider.overrideWith(
                () => _PreloadedDraftNotifier(
                  const RegistrationDraft(
                    displayName: 'Kevine Mukiza',
                    phone: '+250 788 123 456',
                    wantsMentorApplication: true,
                    mentorApplication: MentorRegistrationPayload(
                      headline: 'Senior Mobile Engineer',
                      profession: 'Mobile Architect',
                      education: 'BSc Computer Science',
                      experienceYears: 6,
                      expertise: ['Mobile Development'],
                      skills: ['Flutter', 'Firebase'],
                      bio: 'Mentoring mobile builders across Rwanda for 6 years.',
                      availability: 'Tue & Thu 18:00 CAT',
                      mentoringInterests: 'Portfolio reviews',
                      maxMentees: 5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        expect(
          find.text('Mentor review follows verification'),
          findsOneWidget,
        );

        // Resending starts cooldown and disables rapid duplicate requests.
        await tester.tap(find.text('Send verification email'));
        await tester.pump();
        expect(fakeAuth.sendCalls, [true]);
        expect(find.textContaining('Resend available in'), findsOneWidget);

        // Simulates too-many-requests error mapping on expired link or throttle.
        fakeAuth.verified = true;
        await tester.tap(find.text('I verified my email'));
        await tester.pumpAndSettle();

        // Verification alone NEVER sends a mentor to /m/home; defaults to pending/apply flow.
        expect(destinations, isNot(contains(AppRoutes.mentorHome)));
        expect(destinations, [AppRoutes.mentorApply]);
      },
    );

    test('route guards enforce strict isolation across Youth, Pending/Rejected Mentor, Approved Mentor & Admin', () {
      const youth = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 's1',
        role: UserRole.student,
        onboarded: true,
        accountExists: true,
      );
      final pendingMentor = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'p1',
        role: UserRole.student,
        onboarded: false,
        accountExists: true,
        mentorApplication: MentorApplication(
          id: 'p1',
          ownerUid: 'p1',
          applicantName: 'Pending Mentor',
          applicantEmail: 'p1@upbridge.rw',
          headline: 'Engineer',
          bio: 'Experienced systems builder supporting learners.',
          expertise: const ['Web Development'],
          experienceYears: 5,
          status: MentorApplicationStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final rejectedMentor = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'r1',
        role: UserRole.student,
        onboarded: false,
        accountExists: true,
        mentorApplication: pendingMentor.mentorApplication!.copyWith(
          status: MentorApplicationStatus.rejected,
          rejectionReason: 'Add portfolio links and expand bio.',
        ),
      );
      const approvedMentor = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'p1',
        role: UserRole.mentor,
        onboarded: true,
        accountExists: true,
      );

      // Youth stays in Youth app, blocked from /m/ and /a/.
      expect(
        evaluateSessionRedirect(session: youth, location: AppRoutes.studentHome),
        isNull,
      );
      expect(
        evaluateSessionRedirect(session: youth, location: AppRoutes.mentorHome),
        AppRoutes.studentHome,
      );

      // Pending mentor is isolated to /mentor-pending & /mentor-apply; blocked from Youth /home, /m/, /a/.
      expect(
        evaluateSessionRedirect(
          session: pendingMentor,
          location: AppRoutes.mentorPending,
        ),
        isNull,
      );
      expect(
        evaluateSessionRedirect(
          session: pendingMentor,
          location: AppRoutes.studentHome,
        ),
        AppRoutes.mentorPending,
      );
      expect(
        evaluateSessionRedirect(
          session: pendingMentor,
          location: AppRoutes.mentorHome,
        ),
        AppRoutes.mentorPending,
      );
      expect(
        evaluateSessionRedirect(
          session: pendingMentor,
          location: '/m/courses',
        ),
        AppRoutes.mentorPending,
      );
      expect(
        evaluateSessionRedirect(
          session: pendingMentor,
          location: AppRoutes.adminOverview,
        ),
        AppRoutes.mentorPending,
      );

      // Rejected mentor is also isolated from Youth /home & /m/, kept on /mentor-pending / /mentor-apply.
      expect(
        evaluateSessionRedirect(
          session: rejectedMentor,
          location: AppRoutes.studentHome,
        ),
        AppRoutes.mentorPending,
      );
      expect(
        evaluateSessionRedirect(
          session: rejectedMentor,
          location: AppRoutes.mentorHome,
        ),
        AppRoutes.mentorPending,
      );

      // Once admin approves, session transitions from /mentor-pending -> /m/home reactively.
      expect(
        evaluateSessionRedirect(
          session: approvedMentor,
          location: AppRoutes.mentorPending,
        ),
        AppRoutes.mentorHome,
      );
      expect(
        evaluateSessionRedirect(
          session: approvedMentor,
          location: AppRoutes.studentHome,
        ),
        AppRoutes.mentorHome,
      );
      expect(
        evaluateSessionRedirect(
          session: approvedMentor,
          location: AppRoutes.mentorHome,
        ),
        isNull,
      );
    });

    testWidgets(
      'MentorPendingScreen renders required pending message, full summary, rejected feedback & reactive approval',
      (tester) async {
        final app = MentorApplication(
          id: 'm1',
          ownerUid: 'm1',
          applicantName: 'Claire Mukamana',
          applicantEmail: 'claire@upbridge.rw',
          headline: 'Principal Backend Architect',
          profession: 'Lead Cloud Engineer at PayPack',
          education: 'MSc Software Engineering, CMU Africa',
          bio: 'Mentoring engineers on distributed systems and APIs.',
          expertise: const ['Cloud & DevOps', 'Web Development'],
          skills: const ['System Design', 'Firebase'],
          experienceYears: 8,
          availability: 'Sat 09:00–13:00 CAT',
          mentoringInterests: 'Architecture reviews and mock interviews',
          maxMentees: 6,
          supportingLinks: const ['https://github.com/claire'],
          status: MentorApplicationStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        final pendingSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm1',
          email: 'claire@upbridge.rw',
          displayName: 'Claire Mukamana',
          role: UserRole.student,
          accountExists: true,
          mentorApplication: app,
        );

        await tester.pumpWidget(
          wrap(
            const MentorPendingScreen(),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(pendingSession),
              ),
              liveUnreadNotificationCountProvider('m1').overrideWith(
                (ref) => Stream.value(1),
              ),
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mentor Application Pending'), findsOneWidget);
        expect(find.text('Pending admin review'), findsOneWidget);
        expect(find.text('Email verified'), findsOneWidget);
        expect(
          find.text(
            'Your email has been verified successfully. Your mentor application is now awaiting review by the UpBridge Rwanda administration team. Verifying your email does not grant mentor access. You will receive an update once your application has been reviewed.',
          ),
          findsOneWidget,
        );
        expect(find.text('Lead Cloud Engineer at PayPack'), findsOneWidget);
        expect(find.text('MSc Software Engineering, CMU Africa'), findsOneWidget);
        expect(find.text('Up to 6 mentees'), findsOneWidget);
        expect(find.text('Check application status'), findsOneWidget);
        expect(find.text('Edit application details'), findsOneWidget);

        // Rejected state renders feedback & resubmit CTA.
        final rejectedSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm1',
          email: 'claire@upbridge.rw',
          displayName: 'Claire Mukamana',
          role: UserRole.student,
          accountExists: true,
          mentorApplication: app.copyWith(
            status: MentorApplicationStatus.rejected,
            rejectionReason: 'Please include your LinkedIn profile URL.',
          ),
        );
        await tester.pumpWidget(
          wrap(
            const MentorPendingScreen(),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(rejectedSession),
              ),
              liveUnreadNotificationCountProvider('m1').overrideWith(
                (ref) => Stream.value(0),
              ),
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rejected'), findsOneWidget);
        expect(
          find.text(
            'Administrator feedback: Please include your LinkedIn profile URL.',
          ),
          findsOneWidget,
        );
        expect(find.text('Update & resubmit application'), findsOneWidget);

        // Pending MentorApplyScreen preserves edit capability too.
        await tester.pumpWidget(
          wrap(
            const MentorApplyScreen(startInEditMode: true),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(pendingSession),
              ),
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Edit mentor application'), findsOneWidget);
        expect(find.text('Save changes'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminMentorReviewScreen displays full applicant credentials and enforces rejection reason validation',
      (tester) async {
        final spyAdmin = _SpyAdminOperations();
        final fullApp = MentorApplication(
          id: 'u1',
          ownerUid: 'u1',
          applicantName: 'Jean Bosco',
          applicantEmail: 'jean@upbridge.rw',
          headline: 'Senior Data Engineer',
          profession: 'Data Platform Lead',
          education: 'BSc Data Science',
          bio: 'Mentoring data analysts and cloud builders in Rwanda.',
          expertise: const ['Data Analysis', 'Cloud & DevOps'],
          skills: const ['Python', 'SQL'],
          experienceYears: 6,
          availability: 'Wed 18:00 CAT',
          mentoringInterests: 'Data pipelines & interview prep',
          maxMentees: 4,
          cvAsset: MediaAsset(
            url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/cv.jpg',
            publicId: 'upbridge/cv',
            resourceType: 'image',
            size: 204800,
            ownerUid: 'u1',
            createdAt: now,
          ),
          supportingLinks: const ['https://linkedin.com/in/jeanbosco'],
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const AdminMentorReviewScreen(applicantUid: 'u1'),
            overrides: [
              mentorApplicationDetailProvider('u1').overrideWith(
                (ref) => Stream.value(fullApp),
              ),
              adminOperationsClientProvider.overrideWithValue(spyAdmin),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Data Platform Lead'), findsOneWidget);
        expect(find.text('BSc Data Science'), findsOneWidget);
        expect(find.text('Up to 4 mentees'), findsOneWidget);
        expect(
          find.text('Data pipelines & interview prep'),
          findsOneWidget,
        );
        expect(find.text('Open uploaded CV'), findsOneWidget);
        expect(find.text('Approve mentor application'), findsOneWidget);
        expect(find.text('Reject with reason'), findsOneWidget);

        await tester.ensureVisible(find.text('Reject with reason'));
        await tester.tap(find.text('Reject with reason'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          'Need verifiable link',
        );
        await tester.tap(find.text('Confirm rejection'));
        await tester.pumpAndSettle();
        expect(spyAdmin.rejectedReason, 'Need verifiable link');
      },
    );

    testWidgets(
      'MentorDashboardScreen renders profile status, total/published courses, quick actions & stats',
      (tester) async {
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
        final mentorProfile = UserProfile(
          id: 'm1',
          ownerUid: 'm1',
          displayName: 'Claire Mukamana',
          headline: 'Principal Engineer',
          location: 'Kigali',
          about: 'Mentoring mobile builders.',
          isMentorPublic: true,
          mentorAvailability: 'Thu evenings',
          createdAt: now,
          updatedAt: now,
        );
        final courses = [
          Course(
            id: 'c1',
            ownerUid: 'm1',
            ownerName: 'Claire Mukamana',
            title: 'Flutter Navigation Mastery',
            summary: 'Build multi-role GoRouter apps safely.',
            status: CourseStatus.published,
            createdAt: now,
            updatedAt: now,
          ),
          Course(
            id: 'c2',
            ownerUid: 'm1',
            ownerName: 'Claire Mukamana',
            title: 'Firestore Security Workshop',
            summary: 'Write Spark-compatible rules tests.',
            status: CourseStatus.draft,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await tester.pumpWidget(
          wrap(
            const MentorDashboardScreen(),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(mentorSession),
              ),
              liveUnreadNotificationCountProvider('m1').overrideWith(
                (ref) => Stream.value(2),
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
                (ref) => Stream.value(courses),
              ),
              userProfileProvider('m1').overrideWith(
                (ref) => Stream.value(mentorProfile),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hello, Claire'), findsAtLeastNWidgets(1));
        expect(find.text('Mentor profile active & visible'), findsOneWidget);
        expect(find.text('Availability: Thu evenings'), findsOneWidget);
        expect(find.text('Courses (1 live)'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('My Courses'), findsOneWidget);
      },
    );

    testWidgets(
      'MentorPendingScreen displays credential upload failure warning & revoked notice',
      (tester) async {
        final app = MentorApplication(
          id: 'm1',
          ownerUid: 'm1',
          applicantName: 'Claire Mukamana',
          applicantEmail: 'claire@upbridge.rw',
          headline: 'Principal Backend Architect',
          bio: 'Mentoring engineers on distributed systems and APIs.',
          expertise: const ['Cloud & DevOps'],
          experienceYears: 8,
          status: MentorApplicationStatus.revoked,
          rejectionReason: 'Credentials expired.',
          createdAt: now,
          updatedAt: now,
        );

        final revokedSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm1',
          email: 'claire@upbridge.rw',
          displayName: 'Claire Mukamana',
          role: UserRole.student,
          accountExists: true,
          mentorApplication: app,
        );

        await tester.pumpWidget(
          wrap(
            const MentorPendingScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(revokedSession)),
              liveUnreadNotificationCountProvider('m1').overrideWith(
                (ref) => Stream.value(0),
              ),
              credentialUploadWarningProvider('m1').overrideWith(
                (ref) async => true,
              ),
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Revoked'), findsOneWidget);
        expect(find.text('Your mentor privileges were revoked'), findsOneWidget);
        expect(find.text('Reason: Credentials expired.'), findsOneWidget);
        expect(
          find.text('Supporting credential image not uploaded'),
          findsOneWidget,
        );
      },
    );

    test('en/rw/fr ARB translations provide non-empty auth, pending-mentor & admin review keys', () async {
      for (final code in ['en', 'rw', 'fr']) {
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        expect(l10n.createAccountTitle.isNotEmpty, isTrue);
        expect(l10n.joinAsYouthTitle.isNotEmpty, isTrue);
        expect(l10n.applyAsMentorTitle.isNotEmpty, isTrue);
        expect(l10n.adminApprovalNoticeTitle.isNotEmpty, isTrue);
        expect(l10n.verifyEmailTitle.isNotEmpty, isTrue);
        expect(l10n.mentorPendingVerifiedBody.isNotEmpty, isTrue);
        expect(l10n.credentialUploadWarningTitle.isNotEmpty, isTrue);
        expect(l10n.approveMentorApplicationCta.isNotEmpty, isTrue);
        expect(l10n.rejectWithReasonCta.isNotEmpty, isTrue);
        expect(l10n.languageSelectBody.isNotEmpty, isTrue);
      }
    });

    testWidgets(
      'EditProfileCvScreen rejects invalid phone format and ProjectEditorScreen validates URLs',
      (tester) async {
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
        final existingProfile = UserProfile(
          id: 's1',
          ownerUid: 's1',
          displayName: 'Aline Uwase',
          headline: 'Junior Developer',
          location: 'Kigali',
          about: 'Building apps.',
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const EditProfileCvScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
              userProfileProvider('s1').overrideWith((ref) => Stream.value(existingProfile)),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final phoneField = find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == 'Phone number',
          ),
          matching: find.byType(TextField),
        );
        await tester.enterText(phoneField, '123');
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a Rwandan mobile number, like 788 123 456.'),
          findsOneWidget,
        );

        await tester.pumpWidget(
          wrap(
            const ProjectEditorScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final titleField = find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == 'Project title',
          ),
          matching: find.byType(TextField),
        );
        final descField = find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == 'Description & impact',
          ),
          matching: find.byType(TextField),
        );
        final demoField = find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == 'Live demo URL',
          ),
          matching: find.byType(TextField),
        );
        await tester.enterText(titleField, 'Bus Finder');
        await tester.enterText(descField, 'Helps commuters find bus stops across Kigali.');
        await tester.tap(find.text('Flutter'));
        await tester.enterText(demoField, 'not-a-valid-url');
        await tester.tap(find.text('Publish project'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Demo / project link: Enter a valid URL starting with https:// or http://.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CourseDetailScreen preview back route & NotificationsScreen role-aware safe handling',
      (tester) async {
        const adminSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'a1',
          role: UserRole.admin,
          onboarded: true,
          accountExists: true,
        );
        final course = Course(
          id: 'c1',
          ownerUid: 'm1',
          ownerName: 'Claire Mukamana',
          title: 'Clean Dart Modules',
          summary: 'Modular Flutter patterns.',
          status: CourseStatus.published,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const CourseDetailScreen(courseId: 'c1', previewOnly: true),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(adminSession)),
              courseDetailProvider('c1').overrideWith((ref) => Stream.value(course)),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final previewPage = tester.widget<DetailPage>(find.byType(DetailPage));
        expect(previewPage.backFallback, '/a/catalog');

        final notifRepo = _FailingNotificationRepo();
        final notifications = [
          UserNotification(
            id: 'n1',
            ownerUid: 'a1',
            title: 'Pending Mentor',
            body: 'Review Claire Mukamana',
            type: 'mentorApplication',
            route: '/a/mentors',
            isRead: false,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final router = GoRouter(
          initialLocation: '/notifications',
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (_, _) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/a/mentors',
              builder: (_, _) => const Scaffold(body: Center(child: Text('Admin Mentors Target'))),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(adminSession)),
              liveNotificationsProvider('a1').overrideWith(
                (ref) => Stream.value(notifications),
              ),
              userNotificationRepositoryProvider.overrideWithValue(notifRepo),
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

        final notifPage = tester.widget<DetailPage>(find.byType(DetailPage));
        expect(notifPage.backFallback, '/a/overview');

        await tester.tap(find.text('Pending Mentor'));
        await tester.pumpAndSettle();
        expect(find.text('Admin Mentors Target'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _FailingNotificationRepo implements UserNotificationRepository {
  @override
  Future<void> markAllRead(String ownerUid) async {
    throw Exception('Offline error');
  }

  @override
  Future<void> markRead(String ownerUid, String notificationId) async {
    throw Exception('Offline error');
  }

  @override
  Stream<List<UserNotification>> watchNotifications(
    String ownerUid, {
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Stream<int> watchUnreadCount(String ownerUid) => Stream.value(0);
}

class _PreloadedDraftNotifier extends RegistrationDraftController {
  _PreloadedDraftNotifier(this._initial);
  final RegistrationDraft _initial;

  @override
  RegistrationDraft? build() => _initial;

  @override
  Future<RegistrationDraft?> loadForUid(String uid) async => _initial;

  @override
  Future<void> clearForUid(String uid) async {}
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({required this.email});
  final String email;
  bool verified = false;
  final List<bool> sendCalls = [];

  @override
  User? get currentUser => null;

  @override
  String? get currentEmail => email;

  @override
  bool get isEmailVerified => verified;

  @override
  Future<void> sendVerificationEmail({bool force = false}) async {
    sendCalls.add(force);
  }

  @override
  Future<bool> reloadAndCheckEmailVerification() async => verified;

  @override
  Future<String?> readRoleClaim({bool forceRefresh = false}) async => 'student';

  @override
  Future<void> signOut() async {}
}

class _NoopAuthService extends AuthService {}

class _SpyAdminOperations implements AdminOperationsClient {
  String? rejectedReason;

  @override
  Future<AdminActionResult> reviewMentorApplication({
    required String applicantUid,
    required MentorApplicationStatus decision,
    String reason = '',
  }) async {
    if (decision == MentorApplicationStatus.rejected) {
      rejectedReason = reason;
    }
    return const AdminActionResult(completed: true, message: 'Done');
  }

  @override
  Future<AdminActionResult> revokeMentorRole({
    required String targetUid,
    required String reason,
  }) async => const AdminActionResult(completed: true, message: 'Done');

  @override
  Future<AdminActionResult> setUserAccountStatus({
    required String targetUid,
    required AccountStatus status,
    String reason = '',
  }) async => const AdminActionResult(completed: true, message: 'Done');
}
