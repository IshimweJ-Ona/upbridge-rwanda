import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/shared/models/models.dart';

void main() {
  const youth = AppUser(
    id: 'youth-1',
    name: 'Aline Uwase',
    phone: '0780000000',
    role: Role.youth,
  );

  test('signed-out Firebase session returns to the welcome route', () {
    expect(
      splashDestination(
        firebaseInitialized: true,
        firebaseSignedIn: false,
        emailVerified: false,
        appUser: youth,
      ),
      '/welcome',
    );
  });

  test('unverified Firebase session opens the verification gate', () {
    expect(
      splashDestination(
        firebaseInitialized: true,
        firebaseSignedIn: true,
        emailVerified: false,
        appUser: null,
      ),
      '/verify-email',
    );
  });

  test('onboarding users return to their next onboarding step', () {
    expect(
      splashDestination(
        firebaseInitialized: false,
        firebaseSignedIn: false,
        emailVerified: false,
        appUser: youth.copyWith(onboarded: false),
      ),
      '/onboarding/goal',
    );
  });

  test('verified users with a role return to the role home', () {
    expect(
      splashDestination(
        firebaseInitialized: true,
        firebaseSignedIn: true,
        emailVerified: true,
        appUser: youth,
      ),
      '/home',
    );
  });
}
