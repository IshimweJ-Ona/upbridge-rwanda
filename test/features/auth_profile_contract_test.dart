import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';

void main() {
  group('auth validation', () {
    test('validates email and password confirmation', () {
      expect(Validators.email('person@example.com'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.confirmPassword('different', 'Password1'), isNotNull);
    });

    test('validates full name and Rwandan phone', () {
      expect(Validators.fullName('Jean Niyonzima'), isNull);
      expect(Validators.fullName('Jean'), isNotNull);
      expect(Validators.phone('788 123 456'), isNull);
      expect(Validators.phone('123'), isNotNull);
    });
  });

  test('AppUserAccount serializes and restricts safe self-profile updates', () {
    final now = DateTime.utc(2026, 11, 19);
    final account = AppUserAccount(
      id: 'uid-1',
      ownerUid: 'uid-1',
      email: 'jean@example.com',
      displayName: 'Jean Niyonzima',
      phone: '+250 788 123 456',
      role: UserRole.student,
      isApproved: false,
      status: AccountStatus.active,
      onboarded: true,
      preferredLocale: 'en',
      createdAt: now,
      updatedAt: now,
    );

    final safeJson = account.toSafeProfileUpdateJson();
    expect(safeJson.containsKey('role'), isFalse);
    expect(safeJson.containsKey('isApproved'), isFalse);
    expect(safeJson.containsKey('status'), isFalse);

    final restored = AppUserAccount.fromJson(account.toJson(), id: 'uid-1');
    expect(restored.displayName, 'Jean Niyonzima');
    expect(restored.role, UserRole.student);
    expect(restored.onboarded, isTrue);
  });

  test('UserProfile round-trips CV education, experience, and skills', () {
    final now = DateTime.utc(2026, 11, 19);
    final profile = UserProfile(
      id: 'uid-1',
      ownerUid: 'uid-1',
      displayName: 'Jean Niyonzima',
      headline: 'Junior Flutter Developer',
      location: 'Kigali, Rwanda',
      about: 'Building community software.',
      skills: const ['Dart', 'Flutter'],
      education: const [
        EducationEntry(
          id: 'ed-1',
          institution: 'University of Rwanda',
          program: 'BSc Computer Science',
          period: '2022–2026',
        ),
      ],
      experience: const [
        ExperienceEntry(
          id: 'ex-1',
          roleTitle: 'Mobile Intern',
          organization: 'Kigali Labs',
          period: '2025',
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    final restored = UserProfile.fromJson(profile.toJson(), id: 'uid-1');
    expect(restored.headline, 'Junior Flutter Developer');
    expect(restored.skills, ['Dart', 'Flutter']);
    expect(restored.education.single.institution, 'University of Rwanda');
    expect(restored.experience.single.roleTitle, 'Mobile Intern');
  });
}
