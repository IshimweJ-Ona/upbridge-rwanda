// Owner: Student 1 · Auth, onboarding & profile
abstract final class Validators {
  /// Rwandan mobile numbers: 9 digits starting with 7 (78, 79, 72, 73).
  static String? phone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter your phone number.';
    final local = digits.startsWith('250') ? digits.substring(3) : (digits.startsWith('0') ? digits.substring(1) : digits);
    if (local.length != 9 || !local.startsWith('7')) return 'Enter a Rwandan mobile number, like 788 123 456.';
    return null;
  }

  static String? password(String value) {
    if (value.length < 8) return 'Use at least 8 characters.';
    if (!value.contains(RegExp(r'\d'))) return 'Add at least one number.';
    return null;
  }
}
