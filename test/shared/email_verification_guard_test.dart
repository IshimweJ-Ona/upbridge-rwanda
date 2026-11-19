// Tests that Firebase users must verify their email and route to their workspace.
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/router/route_guards.dart';

void main() {
  test('unverified Firebase users are sent to the verification screen', () {
    expect(
      emailVerificationRedirect(
        signedIn: true,
        emailVerified: false,
        location: '/home',
      ),
      '/verify-email',
    );
  });

  test('unverified users can stay on the verification screen', () {
    expect(
      emailVerificationRedirect(
        signedIn: true,
        emailVerified: false,
        location: '/verify-email',
      ),
      isNull,
    );
  });

  test('verified users leave verification to their resolved workspace', () {
    expect(
      emailVerificationRedirect(
        signedIn: true,
        emailVerified: true,
        location: '/verify-email',
      ),
      '/home',
    );
    expect(
      emailVerificationRedirect(
        signedIn: true,
        emailVerified: true,
        location: '/verify-email',
        verifiedDestination: '/onboarding/goal',
      ),
      '/onboarding/goal',
    );
    expect(
      emailVerificationRedirect(
        signedIn: true,
        emailVerified: true,
        location: '/verify-email',
        verifiedDestination: '/a/overview',
      ),
      '/a/overview',
    );
  });
}
