// Tests that Firebase users must verify their email before opening app routes.
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

  test('verified users leave the verification screen', () {
    expect(
      emailVerificationRedirect(
        signedIn: true,
        emailVerified: true,
        location: '/verify-email',
      ),
      '/welcome',
    );
  });
}
