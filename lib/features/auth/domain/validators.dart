// Owner: Student 1 · Auth, onboarding & profile
abstract final class Validators {
  static String? email(String value) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Rwandan mobile numbers: 9 digits starting with 7 (78, 79, 72, 73).
  static String? phone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter your phone number.';
    final local = digits.startsWith('250')
        ? digits.substring(3)
        : (digits.startsWith('0') ? digits.substring(1) : digits);
    if (local.length != 9 || !local.startsWith('7')) {
      return 'Enter a Rwandan mobile number, like 788 123 456.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.length < 8) return 'Use at least 8 characters.';
    if (!value.contains(RegExp(r'\d'))) return 'Add at least one number.';
    return null;
  }

  static String? confirmPassword(String value, String password) {
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? fullName(String value) {
    if (value
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .length <
        2) {
      return 'Enter your full name.';
    }
    return null;
  }

  static String? url(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Enter a valid URL starting with https:// or http://.';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        !uri.host.contains('.')) {
      return 'Enter a valid URL starting with https:// or http://.';
    }
    return null;
  }

  static String? optionalUrl(String value) {
    if (value.trim().isEmpty) return null;
    return url(value);
  }

  static String? minLength(
    String value,
    int min, {
    String field = 'This field',
  }) {
    if (value.trim().length < min) {
      return '$field must be at least $min characters.';
    }
    return null;
  }
}
