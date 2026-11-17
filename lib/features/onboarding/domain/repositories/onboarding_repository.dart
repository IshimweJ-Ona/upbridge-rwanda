abstract interface class OnboardingRepository {
  Future<void> complete({
    required String uid,
    required String learningGoal,
    required List<String> interests,
  });
}
