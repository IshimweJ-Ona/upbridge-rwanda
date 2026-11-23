import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/auth/verify_email_screen.dart';
import 'package:upbridge/app/router/role_shell.dart';
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
import 'package:upbridge/features/home/presentation/pages/student_dashboard_screen.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/presentation/pages/course_detail_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_dashboard_screen.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/notifications/domain/models/user_notification.dart';
import 'package:upbridge/features/notifications/domain/repositories/user_notification_repository.dart';
import 'package:upbridge/features/onboarding/presentation/pages/goal_screen.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/features/profile/presentation/pages/edit_profile_cv_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/profile_screen.dart';
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

    testWidgets(
      'SignUpScreen shows Mentor Registration copy with zero student questions and GoalScreen blocks mentors',
      (tester) async {
        await tester.pumpWidget(wrap(const SignUpScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply as Mentor'));
        await tester.pumpAndSettle();

        expect(
          find.text('Welcome to UpBridge — Mentor Registration'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Complete your mentor profile and submit it for review'),
          findsOneWidget,
        );
        expect(
          find.text('What do you want UpBridge to help with?'),
          findsNothing,
        );

        const pendingMentor = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm-pending',
          role: UserRole.mentor,
          approvalStatus: ApprovalStatus.pending,
          onboarded: true,
          accountExists: true,
        );
        await tester.pumpWidget(
          wrap(
            const GoalScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(pendingMentor)),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('What do you want UpBridge to help with?'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'MentorPendingScreen displays required welcome & status and MentorDashboardScreen connects real session data',
      (tester) async {
        final app = MentorApplication(
          id: 'm2',
          ownerUid: 'm2',
          applicantName: 'Claire Mukamana',
          applicantEmail: 'claire@upbridge.rw',
          headline: 'Principal Engineer',
          bio: 'Mentoring engineers.',
          expertise: const ['Web Development'],
          experienceYears: 7,
          status: MentorApplicationStatus.pending,
          createdAt: now,
          updatedAt: now,
        );
        final pendingSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm2',
          displayName: 'Claire Mukamana',
          role: UserRole.mentor,
          approvalStatus: ApprovalStatus.pending,
          accountExists: true,
          mentorApplication: app,
        );
        await tester.pumpWidget(
          wrap(
            const MentorPendingScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(pendingSession)),
              liveUnreadNotificationCountProvider('m2').overrideWith((ref) => Stream.value(0)),
              authServiceProvider.overrideWithValue(_NoopAuthService()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome to UpBridge as a Mentor.'), findsOneWidget);
        expect(find.text('Application Pending Review'), findsOneWidget);
        expect(find.text('Learn'), findsNothing);
        expect(find.text('Opportunities'), findsNothing);

        final approvedSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm2',
          displayName: 'Claire Mukamana',
          role: UserRole.mentor,
          approvalStatus: ApprovalStatus.approved,
          accountExists: true,
          onboarded: true,
        );
        final completedSession = MentorshipSession(
          id: 's-1',
          ownerUid: 'm2',
          mentorshipId: 'ms-1',
          studentUid: 'st-1',
          studentName: 'Eric Mugisha',
          mentorUid: 'm2',
          mentorName: 'Claire Mukamana',
          topic: 'API Design Review',
          meetingMode: 'Video',
          scheduledAt: now,
          status: SessionStatus.completed,
          completedAt: now,
          createdAt: now,
          updatedAt: now,
        );
        await tester.pumpWidget(
          wrap(
            const MentorDashboardScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(approvedSession)),
              liveUnreadNotificationCountProvider('m2').overrideWith((ref) => Stream.value(0)),
              mentorRequestsProvider('m2').overrideWith((ref) => Stream.value(const [])),
              mentorMentorshipsProvider('m2').overrideWith((ref) => Stream.value(const [])),
              mentorSessionsProvider('m2').overrideWith((ref) => Stream.value([completedSession])),
              mentorCoursesProvider('m2').overrideWith((ref) => Stream.value(const [])),
              userProfileProvider('m2').overrideWith(
                (ref) => Stream.value(
                  UserProfile(
                    id: 'm2',
                    ownerUid: 'm2',
                    displayName: 'Claire Mukamana',
                    headline: 'Principal Engineer',
                    location: 'Kigali',
                    about: 'Mentoring backend engineers',
                    mentorExpertise: const ['Backend'],
                    mentorAvailability: 'Thu 18:00 CAT',
                    mentorBio: 'Backend coaching',
                    skills: const ['Dart'],
                    isMentorPublic: true,
                    createdAt: now,
                    updatedAt: now,
                  ),
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome back, Claire Mukamana'), findsOneWidget);
        expect(
          find.text(
            'Share your experience, guide the next generation, and make a meaningful impact.',
          ),
          findsOneWidget,
        );
        expect(find.text('Completed sessions'), findsOneWidget);
        expect(find.text('Profile completion'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('RECENT MENTORSHIP ACTIVITY'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('RECENT MENTORSHIP ACTIVITY'), findsOneWidget);
        expect(find.text('Session: API Design Review'), findsOneWidget);
      },
    );

    testWidgets(
      'RoleShell hides student navigation shell while session metadata is still loading',
      (tester) async {
        const loadingSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u-load',
          role: UserRole.student,
          accountLoaded: false,
          applicationLoaded: false,
        );
        final router = GoRouter(
          initialLocation: AppRoutes.studentHome,
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, shell) =>
                  RoleShell(role: UserRole.student, navigationShell: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: AppRoutes.studentHome,
                      builder: (context, state) =>
                          const Scaffold(body: Text('STUDENT_BODY')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(loadingSession)),
            ],
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('STUDENT_BODY'), findsNothing);
        expect(find.text('Learn'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'Youth Profile, StudentDashboard, and MentorApplyScreen forbid Youth self-service mentor conversion',
      (tester) async {
        const youthSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'y1',
          displayName: 'Aline Uwase',
          role: UserRole.student,
          approvalStatus: ApprovalStatus.notRequired,
          onboarded: true,
          accountExists: true,
        );
        final youthProfile = UserProfile(
          id: 'y1',
          ownerUid: 'y1',
          displayName: 'Aline Uwase',
          headline: 'CS Student',
          location: 'Kigali',
          about: 'Building Dart & Flutter portfolio apps.',
          skills: const ['Flutter'],
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const ProfileScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(youthSession)),
              liveUnreadNotificationCountProvider('y1').overrideWith(
                (ref) => Stream.value(0),
              ),
              userProfileProvider('y1').overrideWith(
                (ref) => Stream.value(youthProfile),
              ),
              userProjectsProvider('y1').overrideWith(
                (ref) => Stream.value(const []),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Log out'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Apply to be a mentor'), findsNothing);
        expect(find.text('Mentor application (Pending review)'), findsNothing);

        await tester.pumpWidget(
          wrap(
            const StudentDashboardScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(youthSession)),
              liveUnreadNotificationCountProvider('y1').overrideWith(
                (ref) => Stream.value(0),
              ),
              userProfileProvider('y1').overrideWith(
                (ref) => Stream.value(youthProfile),
              ),
              studentMentorshipsProvider('y1').overrideWith(
                (ref) => Stream.value(const []),
              ),
              studentSessionsProvider('y1').overrideWith(
                (ref) => Stream.value(const []),
              ),
              publishedCoursesProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              userCourseProgressProvider('y1').overrideWith(
                (ref) => Stream.value(const []),
              ),
              approvedMentorsProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              publishedOpportunitiesProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Mentor application'), findsNothing);

        await tester.pumpWidget(
          wrap(
            const MentorApplyScreen(),
            overrides: [
              appSessionProvider.overrideWith((ref) => Stream.value(youthSession)),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Mentor access restricted'), findsOneWidget);
        expect(find.text('Submit mentor application'), findsNothing);
      },
    );

    testWidgets(
      'AdminMentorReviewScreen displays approval email delivery status and triggers retryApprovalEmail',
      (tester) async {
        final spyAdmin = _SpyAdminOperations();
        final approvedUnmailed = MentorApplication(
          id: 'u-email',
          ownerUid: 'u-email',
          applicantName: 'Jean Bosco',
          applicantEmail: 'jean@upbridge.rw',
          headline: 'Cloud Engineer',
          bio: 'Mentoring engineers.',
          expertise: const ['Cloud'],
          experienceYears: 5,
          status: MentorApplicationStatus.approved,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const AdminMentorReviewScreen(applicantUid: 'u-email'),
            overrides: [
              mentorApplicationDetailProvider('u-email').overrideWith(
                (ref) => Stream.value(approvedUnmailed),
              ),
              adminOperationsClientProvider.overrideWithValue(spyAdmin),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Retry approval email'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Approval email not sent yet'), findsOneWidget);
        await tester.tap(find.text('Retry approval email'));
        await tester.pumpAndSettle();
        expect(spyAdmin.retriedEmailUids, ['u-email']);

        final deliveredApp = approvedUnmailed.copyWith(
          approvalEmailStatus: 'sent',
          approvalEmailRecipient: 'jean@upbridge.rw',
        );
        await tester.pumpWidget(
          wrap(
            const AdminMentorReviewScreen(applicantUid: 'u-email'),
            overrides: [
              mentorApplicationDetailProvider('u-email').overrideWith(
                (ref) => Stream.value(deliveredApp),
              ),
              adminOperationsClientProvider.overrideWithValue(spyAdmin),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Approval email delivered'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Approval email delivered'), findsOneWidget);
        expect(find.text('Retry approval email'), findsNothing);
      },
    );

    testWidgets(
      'Active-session revocation immediately locks RoleShell and redirects signed-in mentor from Mentor Dashboard to /mentor-pending',
      (tester) async {
        final sessionController = StreamController<AppSession>.broadcast();
        addTearDown(sessionController.close);

        const initialApproved = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm-live',
          displayName: 'Live Mentor',
          role: UserRole.mentor,
          approvalStatus: ApprovalStatus.approved,
          onboarded: true,
          accountExists: true,
        );
        final revokedSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'm-live',
          displayName: 'Live Mentor',
          role: UserRole.mentor,
          approvalStatus: ApprovalStatus.revoked,
          onboarded: true,
          accountExists: true,
          mentorApplication: MentorApplication(
            id: 'm-live',
            ownerUid: 'm-live',
            applicantName: 'Live Mentor',
            applicantEmail: 'live@upbridge.rw',
            headline: 'Cloud Architect',
            bio: 'Mentoring youth on distributed systems.',
            expertise: const ['Cloud'],
            experienceYears: 6,
            status: MentorApplicationStatus.revoked,
            rejectionReason: 'Compliance hold',
            createdAt: now,
            updatedAt: now,
          ),
        );

        final routerProviderTest = Provider<GoRouter>((ref) {
          final notifier = _TestSessionNotifier(ref);
          ref.onDispose(notifier.dispose);
          final router = GoRouter(
            initialLocation: AppRoutes.mentorHome,
            refreshListenable: notifier,
            redirect: (context, state) {
              final s =
                  ref.read(appSessionProvider).asData?.value ?? initialApproved;
              return evaluateSessionRedirect(
                session: s,
                location: state.uri.path,
              );
            },
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (_, _, shell) =>
                    RoleShell(role: UserRole.mentor, navigationShell: shell),
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: AppRoutes.mentorHome,
                        builder: (_, _) =>
                            const Center(child: Text('Live Mentor Workspace')),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.mentorPending,
                builder: (_, _) =>
                    const Center(child: Text('Mentor Access Restricted Screen')),
              ),
            ],
          );
          ref.onDispose(router.dispose);
          return router;
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appSessionProvider.overrideWith((ref) async* {
                yield initialApproved;
                yield* sessionController.stream;
              }),
              mentorRequestsProvider('m-live').overrideWith(
                (ref) => Stream.value(const []),
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                final router = ref.watch(routerProviderTest);
                return MaterialApp.router(
                  theme: buildAppTheme(),
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  routerConfig: router,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Live Mentor Workspace'), findsOneWidget);

        // Simulate admin revoking mentor while actively viewing /m/home.
        sessionController.add(revokedSession);
        await tester.pumpAndSettle();

        expect(find.text('Live Mentor Workspace'), findsNothing);
        expect(find.text('Mentor Access Restricted Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminMentorReviewScreen shows hidden mentor directory status and publishes mentor profile',
      (tester) async {
        final spyAdmin = _SpyAdminOperations();
        final approvedApp = MentorApplication(
          id: 'u-vis',
          ownerUid: 'u-vis',
          applicantName: 'Jean Bosco',
          applicantEmail: 'jean@upbridge.rw',
          headline: 'Cloud Engineer',
          bio: 'Mentoring engineers.',
          expertise: const ['Cloud'],
          experienceYears: 5,
          status: MentorApplicationStatus.approved,
          createdAt: now,
          updatedAt: now,
        );
        final hiddenProfile = UserProfile(
          id: 'u-vis',
          ownerUid: 'u-vis',
          displayName: 'Jean Bosco',
          headline: 'Cloud Engineer',
          location: 'Kigali, Rwanda',
          about: 'Mentoring engineers.',
          isMentorPublic: false,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const AdminMentorReviewScreen(
              applicantUid: 'u-vis',
              showDirectoryVisibilityInTests: true,
            ),
            overrides: [
              mentorApplicationDetailProvider('u-vis').overrideWith(
                (ref) => Stream.value(approvedApp),
              ),
              userProfileProvider('u-vis').overrideWith(
                (ref) => Stream.value(hiddenProfile),
              ),
              adminOperationsClientProvider.overrideWithValue(spyAdmin),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Publish to mentor directory'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.text('Hidden from student mentor directory'),
          findsOneWidget,
        );
        await tester.tap(find.text('Publish to mentor directory'));
        await tester.pumpAndSettle();
        expect(spyAdmin.visibilityCalls, [(uid: 'u-vis', isPublic: true)]);
      },
    );

    testWidgets(
      'StudentDashboardScreen surfaces mentor directory load errors instead of empty state',
      (tester) async {
        const studentSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 's-err',
          displayName: 'Aline Uwase',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        await tester.pumpWidget(
          wrap(
            const StudentDashboardScreen(),
            overrides: [
              appSessionProvider.overrideWith(
                (ref) => Stream.value(studentSession),
              ),
              liveUnreadNotificationCountProvider('s-err').overrideWith(
                (ref) => Stream.value(0),
              ),
              userProfileProvider('s-err').overrideWith(
                (ref) => Stream.value(null),
              ),
              studentMentorshipsProvider('s-err').overrideWith(
                (ref) => Stream.value(const []),
              ),
              studentSessionsProvider('s-err').overrideWith(
                (ref) => Stream.value(const []),
              ),
              publishedCoursesProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              userCourseProgressProvider('s-err').overrideWith(
                (ref) => Stream.value(const []),
              ),
              approvedMentorsProvider.overrideWith(
                (ref) => Stream.error(
                  FirebaseException(
                    plugin: 'cloud_firestore',
                    code: 'failed-precondition',
                  ),
                ),
              ),
              publishedOpportunitiesProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Could not load mentors'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Could not load mentors'), findsOneWidget);
        expect(find.text('No verified mentors available yet'), findsNothing);
      },
    );
  });
}

class _TestSessionNotifier extends ChangeNotifier {
  _TestSessionNotifier(Ref ref) {
    _sub = ref.listen<AsyncValue<AppSession>>(
      appSessionProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AppSession>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
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
  final List<String> retriedEmailUids = [];
  final List<({String uid, bool isPublic})> visibilityCalls = [];

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
  Future<AdminActionResult> retryApprovalEmail({
    required String applicantUid,
  }) async {
    retriedEmailUids.add(applicantUid);
    return const AdminActionResult(completed: true, message: 'Done');
  }

  @override
  Future<AdminActionResult> setMentorDirectoryVisibility({
    required String mentorUid,
    required bool isPublic,
  }) async {
    visibilityCalls.add((uid: mentorUid, isPublic: isPublic));
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
