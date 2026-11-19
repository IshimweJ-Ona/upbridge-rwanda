// Tests role claim mapping, verified session state, route guards, and uninitialized AuthService safety.
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

void main() {
  group('trustedRoleFromClaim', () {
    test(
      'maps only recognized custom claim strings and defaults safely to youth',
      () {
        expect(trustedRoleFromClaim('admin'), Role.admin);
        expect(trustedRoleFromClaim('mentor'), Role.mentor);
        expect(trustedRoleFromClaim('youth'), Role.youth);
        expect(trustedRoleFromClaim(null), Role.youth);
        expect(trustedRoleFromClaim('superadmin'), Role.youth);
        expect(trustedRoleFromClaim(123), Role.youth);
      },
    );
  });

  group('VerifiedSession', () {
    test(
      'formats firstName and displayLabel from displayName, email, or role',
      () {
        const named = VerifiedSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u1',
          email: 'aline@example.rw',
          displayName: 'Aline Uwase',
          role: Role.youth,
        );
        expect(named.firstName, 'Aline');
        expect(named.displayLabel, 'Aline Uwase');

        const emailOnly = VerifiedSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u2',
          email: 'jonathan@upbridge.rw',
          role: Role.admin,
        );
        expect(emailOnly.firstName, 'jonathan');
        expect(emailOnly.displayLabel, 'jonathan@upbridge.rw');

        const minimal = VerifiedSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'u3',
          role: Role.mentor,
        );
        expect(minimal.firstName, 'Friend');
        expect(minimal.displayLabel, 'Mentor');
      },
    );
  });

  group('route guards', () {
    test('verifiedUserDestination sends un-onboarded youth to onboarding', () {
      expect(
        verifiedUserDestination(role: Role.youth, onboarded: false),
        '/onboarding/goal',
      );
      expect(
        verifiedUserDestination(role: Role.youth, onboarded: true),
        '/home',
      );
      expect(
        verifiedUserDestination(role: Role.mentor, onboarded: false),
        '/m/home',
      );
      expect(
        verifiedUserDestination(role: Role.admin, onboarded: false),
        '/a/overview',
      );
    });

    test('roleAreaRedirect isolates mentor and admin workspaces while allowing /language', () {
      expect(
        roleAreaRedirect(role: Role.youth, location: '/a/overview'),
        '/home',
      );
      expect(roleAreaRedirect(role: Role.youth, location: '/m/home'), '/home');
      expect(roleAreaRedirect(role: Role.youth, location: '/language'), isNull);
      expect(roleAreaRedirect(role: Role.mentor, location: '/home'), '/m/home');
      expect(
        roleAreaRedirect(role: Role.mentor, location: '/m-review/1'),
        isNull,
      );
      expect(
        roleAreaRedirect(role: Role.admin, location: '/m/home'),
        '/a/overview',
      );
      expect(roleAreaRedirect(role: Role.admin, location: '/a/users'), isNull);
    });
  });

  group('AuthService without Firebase initialized', () {
    test(
      'fails cleanly instead of throwing native app initialization errors',
      () async {
        final service = AuthService();
        expect(service.currentUser, isNull);
        expect(service.currentEmail, isNull);
        expect(service.isEmailVerified, isFalse);
        expect(await service.authStateChanges.isEmpty, isTrue);
        expect(await service.userChanges.isEmpty, isTrue);
        expect(await service.readRoleClaim(), isNull);
        expect(await service.reloadAndCheckEmailVerification(), isFalse);
        await expectLater(service.signOut(), completes);
        await expectLater(
          () => service.sendVerificationEmail(),
          throwsStateError,
        );
        await expectLater(
          () => service.signIn('user@example.rw', 'Password123'),
          throwsStateError,
        );
        await expectLater(
          () => service.signUp('user@example.rw', 'Password123'),
          throwsStateError,
        );
        await expectLater(
          () => service.sendPasswordReset('user@example.rw'),
          throwsStateError,
        );
      },
    );
  });
}
