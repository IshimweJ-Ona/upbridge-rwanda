// Validated monthly feedback submitted once by the authenticated youth.
class CheckIn {
  const CheckIn({
    required this.userId,
    required this.monthKey,
    required this.usefulness,
    required this.applied,
    this.changeNote = '',
    this.createdAt,
  });

  final String userId;
  final String monthKey;
  final int usefulness;
  final bool applied;
  final String changeNote;
  final DateTime? createdAt;

  String? validate() {
    if (userId.trim().isEmpty) {
      return 'Sign in before submitting a check-in.';
    }
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(monthKey)) {
      return 'Choose a valid month.';
    }
    if (usefulness < 1 || usefulness > 5) {
      return 'Choose a rating from 1 to 5.';
    }
    if (changeNote.length > 500) {
      return 'Keep the note under 500 characters.';
    }
    return null;
  }

  Map<String, Object?> toFirestore() => {
    'userId': userId,
    'monthKey': monthKey,
    'usefulness': usefulness,
    'applied': applied,
    'changeNote': changeNote.trim(),
  };
}
