import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/features/profile/presentation/pages/edit_profile_cv_screen.dart';
import 'package:upbridge/features/profile/presentation/pages/profile_screen.dart';
import 'package:upbridge/l10n/app_localizations.dart';
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
}
