// Tests launch destination resolution across Firebase claims and demo fallback state.
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

  test(
    'verified Firebase session routes from trusted role and onboarding flag',
    () {
      expect(
        splashDestination(
          firebaseInitialized: true,
          firebaseSignedIn: true,
          emailVerified: true,
          firebaseRole: Role.youth,
          firebaseOnboarded: false,
          appUser: null,
        ),
        '/onboarding/goal',
      );
      expect(
        splashDestination(
          firebaseInitialized: true,
          firebaseSignedIn: true,
          emailVerified: true,
          firebaseRole: Role.youth,
          firebaseOnboarded: true,
          appUser: null,
        ),
        '/home',
      );
      expect(
        splashDestination(
          firebaseInitialized: true,
          firebaseSignedIn: true,
          emailVerified: true,
          firebaseRole: Role.mentor,
          firebaseOnboarded: false,
          appUser: null,
        ),
        '/m/home',
      );
      expect(
        splashDestination(
          firebaseInitialized: true,
          firebaseSignedIn: true,
          emailVerified: true,
          firebaseRole: Role.youth,
          firebaseOnboarded: false,
          firebaseProfileExists: false,
          appUser: null,
        ),
        '/verify-email',
      );
      expect(
        splashDestination(
          firebaseInitialized: true,
          firebaseSignedIn: true,
          emailVerified: true,
          firebaseRole: Role.admin,
          firebaseOnboarded: false,
          appUser: null,
        ),
        '/a/overview',
      );
    },
  );

  test('demo onboarding users return to their next onboarding step', () {
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

  test('verified users with fallback AppUser return to role home', () {
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
