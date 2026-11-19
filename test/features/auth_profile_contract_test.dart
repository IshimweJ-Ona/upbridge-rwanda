import 'package:flutter_test/flutter_test.dart';

import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:upbridge/features/profile/domain/entities/profile.dart';

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

  test('profile serializes and deserializes the ERD fields', () {
    const profile = Profile(
      uid: 'uid-1',
      role: 'youth',
      accountStatus: 'active',
      displayName: 'Jean Niyonzima',
      phone: '+250 788 123 456',
      interests: ['Web development'],
      learningGoal: 'job',
      onboarded: true,
    );
    final restored = Profile.fromMap(profile.toMap(), uid: profile.uid);
    expect(restored.uid, profile.uid);
    expect(restored.role, 'youth');
    expect(restored.accountStatus, 'active');
    expect(restored.interests, profile.interests);
    expect(restored.learningGoal, profile.learningGoal);
    expect(restored.onboarded, isTrue);
  });

  test('onboarding validation rejects missing selections', () {
    expect(
      OnboardingRepositoryImpl.validationError(
        learningGoal: '',
        interests: const [],
      ),
      isNotNull,
    );
  });

  test('profile update payload excludes role and account status', () {
    const profile = Profile(
      uid: 'uid-1',
      role: 'youth',
      accountStatus: 'active',
      displayName: 'Jean Niyonzima',
      phone: '+250 788 123 456',
    );
    expect(profile.toUpdateMap().keys, isNot(contains('role')));
    expect(profile.toUpdateMap().keys, isNot(contains('accountStatus')));
  });
}
