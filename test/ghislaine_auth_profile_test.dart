import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/services/cloudinary_service.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/auth/domain/repositories/user_account_repository.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/features/learning/domain/repositories/course_repository.dart';
import 'package:upbridge/features/learning/presentation/pages/course_detail_screen.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:upbridge/features/profile/presentation/pages/edit_profile_cv_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/profile_screen.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  final now = DateTime.utc(2026, 11, 23, 10);

  Widget wrapWithScope(Widget child, List<dynamic> overrides) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('Ghislaine Contribution: CV Completeness Evaluation Unit Tests', () {
    test('reports 0% completeness when profile is blank', () {
      final blank = UserProfile(
        id: 'u-1',
        ownerUid: 'u-1',
        displayName: 'Aline Uwase',
        headline: '',
        location: '',
        about: '',
        createdAt: now,
        updatedAt: now,
      );

      final report = CvCompletenessReport.evaluate(blank);
      expect(report.completedCount, 0);
      expect(report.totalCount, 7);
      expect(report.percent, 0);
      expect(report.isComplete, isFalse);
    });

    test('reports correct percentage when partially complete', () {
      final partial = UserProfile(
        id: 'u-1',
        ownerUid: 'u-1',
        displayName: 'Aline Uwase',
        headline: 'Flutter Developer', // 1
        location: 'Kigali',
        about: 'Passionate mobile software engineering student.', // 2
        skills: const ['Flutter', 'Dart', 'Git'], // 3
        createdAt: now,
        updatedAt: now,
      );

      final report = CvCompletenessReport.evaluate(partial);
      expect(report.completedCount, 3);
      expect(report.totalCount, 7);
      expect(report.percent, 43); // 3/7 = 42.85% -> 43%
      expect(report.hasHeadline, isTrue);
      expect(report.hasBio, isTrue);
      expect(report.hasSkills, isTrue);
      expect(report.hasPhoto, isFalse);
      expect(report.hasEducation, isFalse);
      expect(report.hasExperience, isFalse);
      expect(report.hasCvAsset, isFalse);
      expect(report.isComplete, isFalse);
    });

    test('reports 100% completeness when all 7 dimensions are satisfied', () {
      final complete = UserProfile(
        id: 'u-1',
        ownerUid: 'u-1',
        displayName: 'Aline Uwase',
        headline: 'Junior Flutter & Cloud Developer', // 1
        location: 'Kigali, Rwanda',
        about: 'Building resilient offline-first mobile apps for Rwandan youth.', // 2
        photoAsset: MediaAsset( // 3
          url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/avatars/aline.jpg',
          publicId: 'avatars/aline',
          resourceType: 'image',
          size: 102400,
          ownerUid: 'u-1',
          createdAt: now,
        ),
        cvAsset: MediaAsset( // 4
          url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/cv/aline_cv.jpg',
          publicId: 'cv/aline_cv',
          resourceType: 'image',
          size: 204800,
          ownerUid: 'u-1',
          createdAt: now,
        ),
        skills: const ['Flutter', 'Dart', 'Firebase'], // 5
        education: const [ // 6
          EducationEntry(
            id: 'edu-1',
            institution: 'University of Rwanda',
            program: 'BSc Computer Science',
            period: '2022-2026',
          ),
        ],
        experience: const [ // 7
          ExperienceEntry(
            id: 'exp-1',
            roleTitle: 'Frontend Intern',
            organization: 'Kigali Tech Lab',
            period: '2025',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final report = CvCompletenessReport.evaluate(complete);
      expect(report.completedCount, 7);
      expect(report.totalCount, 7);
      expect(report.percent, 100);
      expect(report.isComplete, isTrue);
    });
  });

  group('Ghislaine Contribution: ProfileScreen CV Completeness Widget Tests', () {
    const studentSession = AppSession(
      firebaseInitialized: true,
      signedIn: true,
      emailVerified: true,
      uid: 'student-test-1',
      displayName: 'Aline Uwase',
      role: UserRole.student,
      onboarded: true,
      accountExists: true,
    );

    testWidgets('renders incomplete CV card with progress bar and missing item chips', (tester) async {
      final incompleteProfile = UserProfile(
        id: 'student-test-1',
        ownerUid: 'student-test-1',
        displayName: 'Aline Uwase',
        headline: 'Aspiring Developer',
        location: 'Kigali',
        about: '', // missing
        skills: const ['Flutter'], // < 3 skills (missing)
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        wrapWithScope(
          const ProfileScreen(),
          [
            appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
            userProfileProvider('student-test-1').overrideWith((ref) => Stream.value(incompleteProfile)),
            userProjectsProvider('student-test-1').overrideWith((ref) => Stream.value(const <PortfolioProject>[])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Card title & progress
      expect(find.text('CV Completeness'), findsOneWidget);
      expect(find.byType(CvCompletenessCard), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Should identify missing items
      expect(find.text('+ Profile photo'), findsOneWidget);
      expect(find.text('+ About / Bio'), findsOneWidget);
      expect(find.text('+ Education'), findsOneWidget);
      expect(find.text('+ Experience'), findsOneWidget);
      expect(find.text('+ Attached CV file'), findsOneWidget);
    });

    testWidgets('renders 100% completed badge and success message when all sections filled', (tester) async {
      final fullProfile = UserProfile(
        id: 'student-test-1',
        ownerUid: 'student-test-1',
        displayName: 'Aline Uwase',
        headline: 'Junior Mobile Developer',
        location: 'Kigali, Rwanda',
        about: 'Focused on high quality mobile development with Flutter.',
        photoAsset: MediaAsset(
          url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/avatars/aline.jpg',
          publicId: 'avatars/aline',
          resourceType: 'image',
          size: 102400,
          ownerUid: 'student-test-1',
          createdAt: now,
        ),
        cvAsset: MediaAsset(
          url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/cv/cv.jpg',
          publicId: 'cv/cv',
          resourceType: 'image',
          size: 204800,
          ownerUid: 'student-test-1',
          createdAt: now,
        ),
        skills: const ['Flutter', 'Dart', 'Clean Architecture'],
        education: const [
          EducationEntry(
            id: 'ed-1',
            institution: 'University of Rwanda',
            program: 'Software Engineering',
            period: '2023-2026',
          ),
        ],
        experience: const [
          ExperienceEntry(
            id: 'ex-1',
            roleTitle: 'Junior Developer',
            organization: 'UpBridge Team',
            period: '2026',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        wrapWithScope(
          const ProfileScreen(),
          [
            appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
            userProfileProvider('student-test-1').overrideWith((ref) => Stream.value(fullProfile)),
            userProjectsProvider('student-test-1').overrideWith((ref) => Stream.value(const <PortfolioProject>[])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CV Completeness'), findsOneWidget);
      expect(find.text('100% completed'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Your CV is complete and ready to share!'), findsOneWidget);
    });
  });

  group('Ghislaine Contribution: EditProfileCvScreen Form Validation Widget Tests', () {
    const studentSession = AppSession(
      firebaseInitialized: true,
      signedIn: true,
      emailVerified: true,
      uid: 'student-test-1',
      displayName: 'Aline Uwase',
      role: UserRole.student,
      onboarded: true,
      accountExists: true,
    );

    testWidgets('shows validation error when full name is less than two words', (tester) async {
      final profile = UserProfile(
        id: 'student-test-1',
        ownerUid: 'student-test-1',
        displayName: 'Aline',
        headline: 'Developer',
        location: 'Kigali',
        about: 'About student',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        wrapWithScope(
          const EditProfileCvScreen(),
          [
            appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
            userProfileProvider('student-test-1').overrideWith((ref) => Stream.value(profile)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.descendant(
        of: find.byWidgetPredicate((w) => w is AppTextField && w.label == 'Full name'),
        matching: find.byType(TextField),
      );
      await tester.enterText(nameField, 'Aline');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your full name.'), findsOneWidget);
    });

    testWidgets('shows validation error when invalid Rwandan phone number is entered', (tester) async {
      final profile = UserProfile(
        id: 'student-test-1',
        ownerUid: 'student-test-1',
        displayName: 'Aline Uwase',
        headline: 'Developer',
        location: 'Kigali',
        about: 'About student',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        wrapWithScope(
          const EditProfileCvScreen(),
          [
            appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
            userProfileProvider('student-test-1').overrideWith((ref) => Stream.value(profile)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final phoneField = find.descendant(
        of: find.byWidgetPredicate((w) => w is AppTextField && w.label == 'Phone number'),
        matching: find.byType(TextField),
      );
      await tester.enterText(phoneField, '12345');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a Rwandan mobile number, like 788 123 456.'), findsOneWidget);
    });

    testWidgets('shows validation error when link is not a valid URL', (tester) async {
      final profile = UserProfile(
        id: 'student-test-1',
        ownerUid: 'student-test-1',
        displayName: 'Aline Uwase',
        headline: 'Developer',
        location: 'Kigali',
        about: 'About student',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        wrapWithScope(
          const EditProfileCvScreen(),
          [
            appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
            userProfileProvider('student-test-1').overrideWith((ref) => Stream.value(profile)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final linkField = find.descendant(
        of: find.byWidgetPredicate((w) => w is AppTextField && w.label.startsWith('Professional links')),
        matching: find.byType(TextField),
      );
      await tester.enterText(linkField, 'not-a-valid-url');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.byType(NoticeCard), findsOneWidget);
      expect(find.text('Could not save'), findsOneWidget);
      expect(find.textContaining('Enter a valid URL starting with https://'), findsOneWidget);
    });
  });

  group('Regression fixes: error messages, delayed hydration, and course evidence', () {
    const studentSession = AppSession(
      firebaseInitialized: true,
      signedIn: true,
      emailVerified: true,
      uid: 'student-test-1',
      displayName: 'Aline Uwase',
      role: UserRole.student,
      onboarded: true,
      accountExists: true,
    );

    test('errorMessage surfaces domain validation and Cloudinary upload errors', () {
      expect(
        errorMessage(const CloudinaryServiceException('Upload exceeds 10 MB limit.')),
        'Upload exceeds 10 MB limit.',
      );
      expect(
        errorMessage(const UploadCancelledException()),
        'Upload cancelled.',
      );
      expect(
        errorMessage(StateError('Mentorship already active.')),
        'Mentorship already active.',
      );
      expect(
        errorMessage(ArgumentError('Invalid course status transition.')),
        'Invalid course status transition.',
      );
    });

    testWidgets('EditProfileCvScreen hydrates delayed async streams and persists cleared phone', (tester) async {
      final profileController = StreamController<UserProfile?>.broadcast();
      final accountController = StreamController<AppUserAccount?>.broadcast();
      addTearDown(profileController.close);
      addTearDown(accountController.close);

      final accountRepo = _TestAccountRepository(accountController.stream);
      final profileRepo = _TestProfileRepository(profileController.stream);

      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(path: '/edit', builder: (_, _) => const EditProfileCvScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const Scaffold(body: Text('Profile Destination'))),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
            userAccountRepositoryProvider.overrideWithValue(accountRepo),
            userProfileRepositoryProvider.overrideWithValue(profileRepo),
            userProfileProvider('student-test-1').overrideWith((ref) => profileController.stream),
          ],
          child: MaterialApp.router(
            theme: buildAppTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      profileController.add(
        UserProfile(
          id: 'student-test-1',
          ownerUid: 'student-test-1',
          displayName: 'Aline Uwase',
          headline: 'Backend Developer',
          location: 'Kigali, Rwanda',
          about: 'Builds resilient APIs',
          professionalLinks: const ['https://github.com/aline'],
          skills: const ['Flutter', 'Dart'],
          createdAt: now,
          updatedAt: now,
        ),
      );
      accountController.add(
        AppUserAccount(
          id: 'student-test-1',
          ownerUid: 'student-test-1',
          email: 'aline@example.com',
          displayName: 'Aline Uwase',
          phone: '+250 788 111 222',
          role: UserRole.student,
          isApproved: true,
          status: AccountStatus.active,
          onboarded: true,
          preferredLocale: 'en',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Backend Developer'), findsOneWidget);
      expect(find.text('Builds resilient APIs'), findsOneWidget);
      expect(find.text('788 111 222'), findsOneWidget);
      expect(find.text('https://github.com/aline'), findsOneWidget);

      final phoneField = find.descendant(
        of: find.byWidgetPredicate((w) => w is AppTextField && w.label == 'Phone number'),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, '');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(accountRepo.lastUpdatedPhone, '');
      expect(profileRepo.lastSavedProfile?.headline, 'Backend Developer');
      expect(profileRepo.lastSavedProfile?.about, 'Builds resilient APIs');
      expect(find.text('Profile Destination'), findsOneWidget);
    });

    testWidgets('CourseDetailScreen hydrates existing progress and preserves evidenceAsset on link update', (tester) async {
      final progressController = StreamController<CourseProgress?>.broadcast();
      addTearDown(progressController.close);
      final courseRepo = _TestCourseRepository(progressController.stream);

      final course = Course(
        id: 'course-1',
        ownerUid: 'mentor-1',
        ownerName: 'Jean Mentor',
        title: 'Flutter Architecture',
        summary: 'Learn clean app structure.',
        status: CourseStatus.published,
        createdAt: now,
        updatedAt: now,
      );
      final existingAsset = MediaAsset(
        url: 'https://res.cloudinary.com/vbzq5ssu/raw/upload/v1/course-evidence/cert.pdf',
        publicId: 'course-evidence/cert',
        resourceType: 'raw',
        size: 4096,
        ownerUid: 'student-test-1',
        createdAt: now,
      );

      await tester.pumpWidget(
        wrapWithScope(
          const CourseDetailScreen(courseId: 'course-1'),
          [
            appSessionProvider.overrideWith((ref) => Stream.value(studentSession)),
            courseRepositoryProvider.overrideWithValue(courseRepo),
            courseDetailProvider('course-1').overrideWith((ref) => Stream.value(course)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      progressController.add(
        CourseProgress(
          id: 'student-test-1_course-1',
          ownerUid: 'student-test-1',
          courseId: 'course-1',
          courseTitle: 'Flutter Architecture',
          evidenceUrl: 'https://github.com/aline/initial',
          evidenceAsset: existingAsset,
          status: CourseProgressStatus.completed,
          progressPercent: 100,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('https://github.com/aline/initial'), findsOneWidget);
      expect(find.text('Update completion proof'), findsOneWidget);

      final evidenceField = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is AppTextField && w.label == 'Project or repository link',
        ),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(evidenceField);
      await tester.enterText(evidenceField, 'https://github.com/aline/updated');
      await tester.ensureVisible(find.text('Update completion proof'));
      await tester.tap(find.text('Update completion proof'));
      await tester.pumpAndSettle();

      expect(courseRepo.lastSubmittedEvidenceUrl, 'https://github.com/aline/updated');
      expect(courseRepo.lastSubmittedEvidenceAsset?.publicId, existingAsset.publicId);
    });
  });
}

class _TestAccountRepository implements UserAccountRepository {
  _TestAccountRepository(this._stream);

  final Stream<AppUserAccount?> _stream;
  String? lastUpdatedPhone;

  @override
  Stream<AppUserAccount?> watchAccount(String uid) => _stream;

  @override
  Future<AppUserAccount?> getAccount(String uid) async => null;

  @override
  Future<void> ensureStudentAccount({
    required String uid,
    required String email,
    required String displayName,
    String phone = '',
  }) async {}

  @override
  Future<void> updateSafeAccount({
    required String uid,
    String? displayName,
    String? phone,
    bool? onboarded,
    String? preferredLocale,
    MediaAsset? photoAsset,
    bool clearPhotoAsset = false,
  }) async {
    lastUpdatedPhone = phone;
  }
}

class _TestProfileRepository implements UserProfileRepository {
  _TestProfileRepository(this._stream);

  final Stream<UserProfile?> _stream;
  UserProfile? lastSavedProfile;

  @override
  Stream<UserProfile?> watchProfile(String uid) => _stream;

  @override
  Future<UserProfile?> getProfile(String uid) async => null;

  @override
  Stream<List<UserProfile>> watchApprovedMentors({int limit = 50}) =>
      Stream.value(const []);

  @override
  Future<void> upsertOwnProfile(UserProfile profile) async {
    lastSavedProfile = profile;
  }

  @override
  Future<void> updateMentorProfileSettings({
    required String uid,
    required List<String> expertise,
    required int experienceYears,
    required String availability,
    required int maxMentees,
    required String bio,
    required bool isMentorPublic,
    String? displayName,
    String? headline,
    List<String>? professionalLinks,
    MediaAsset? photoAsset,
    bool clearPhotoAsset = false,
  }) async {}
}

class _TestCourseRepository implements CourseRepository {
  _TestCourseRepository(this._progressStream);

  final Stream<CourseProgress?> _progressStream;
  String? lastSubmittedEvidenceUrl;
  MediaAsset? lastSubmittedEvidenceAsset;

  @override
  Stream<CourseProgress?> watchCourseProgress(String uid, String courseId) =>
      _progressStream;

  @override
  Future<void> submitCourseEvidence({
    required String uid,
    required Course course,
    required String evidenceUrl,
    MediaAsset? evidenceAsset,
  }) async {
    lastSubmittedEvidenceUrl = evidenceUrl;
    lastSubmittedEvidenceAsset = evidenceAsset;
  }

  @override
  Stream<List<Course>> watchPublishedCourses({int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<List<Course>> watchAllCourses({int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<List<Course>> watchMentorCourses(String mentorUid, {int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<Course?> watchCourse(String courseId) => Stream.value(null);

  @override
  Future<Course?> getCourse(String courseId) async => null;

  @override
  Stream<List<CourseProgress>> watchUserProgress(String uid, {int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<List<CourseProgress>> watchCourseEngagement(
    String courseId, {
    String? courseOwnerUid,
    int limit = 100,
  }) =>
      Stream.value(const []);

  @override
  Future<void> toggleModuleCompletion({
    required String uid,
    required Course course,
    required String moduleId,
  }) async {}

  @override
  Future<String> saveCourse(Course course) async => course.id;

  @override
  Future<void> transitionCourseStatus({
    required String courseId,
    required CourseStatus nextStatus,
  }) async {}

  @override
  Future<void> deleteCourse(String courseId) async {}
}
