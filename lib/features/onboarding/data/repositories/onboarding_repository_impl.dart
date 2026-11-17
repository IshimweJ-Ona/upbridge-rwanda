import 'package:upbridge/shared/services/firebase/upbridge_repository.dart';

class OnboardingRepositoryImpl {
  OnboardingRepositoryImpl(this._repository);
  final UpBridgeRepository _repository;

  static String? validationError({
    required String learningGoal,
    required List<String> interests,
  }) {
    if (learningGoal.trim().isEmpty) return 'Choose a learning goal.';
    if (interests.isEmpty) return 'Choose at least one interest.';
    return null;
  }

  Future<void> complete({
    required String uid,
    required String learningGoal,
    required List<String> interests,
  }) {
    final error = validationError(
      learningGoal: learningGoal,
      interests: interests,
    );
    if (error != null) throw FormatException(error);
    return _repository.saveProfile(uid, {
      'learningGoal': learningGoal,
      'interests': interests,
      'onboarded': true,
    });
  }
}
