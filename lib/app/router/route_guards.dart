// Keeps email-verification redirect policy separate and easy to test.

String? emailVerificationRedirect({
  required bool signedIn,
  required bool emailVerified,
  required String location,
}) {
  if (!signedIn) return null;
  if (!emailVerified && location != '/verify-email') return '/verify-email';
  if (emailVerified && location == '/verify-email') return '/welcome';
  return null;
}
