// Tests VerifyEmailScreen flows and RoleShell live/demo session header behavior.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/auth/verify_email_screen.dart';
import 'package:upbridge/app/router/role_shell.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

void main() {
  group('VerifyEmailScreen', () {
    testWidgets(
      'resends verification, verifies email, and routes admin to /a/overview',
      (tester) async {
        final auth = _FakeAuthService(
          email: 'admin@upbridge.rw',
          roleClaim: 'admin',
        );
        final destinations = <String>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(auth)],
            child: MaterialApp(
              home: VerifyEmailScreen(onNavigate: destinations.add),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('admin@upbridge.rw'), findsOneWidget);
        expect(auth.sendCalls, isEmpty);

        await tester.tap(find.text('Send verification email'));
        await tester.pump();
        expect(auth.sendCalls, [true]);

        auth.verified = true;
        await tester.tap(find.text('I verified my email'));
        await tester.pumpAndSettle();

        expect(destinations, ['/a/overview']);
      },
    );

    testWidgets(
      'shows error when confirmation is still pending and supports sign out',
      (tester) async {
        final auth = _FakeAuthService(email: 'youth@upbridge.rw');
        final destinations = <String>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(auth)],
            child: MaterialApp(
              home: VerifyEmailScreen(onNavigate: destinations.add),
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('I verified my email'));
        await tester.pump();
        expect(
          find.text('We have not received confirmation yet.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Sign out'));
        await tester.pump();
        expect(auth.signedOut, isTrue);
        expect(destinations, ['/welcome']);
      },
    );
  });

  group('RoleShell', () {
    testWidgets('displays live VerifiedSession identity in desktop SideNav', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const session = VerifiedSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'admin-uid',
        email: 'jonathan@upbridge.rw',
        displayName: 'Jonathan Ishimwe',
        role: Role.admin,
        onboarded: true,
      );

      final router = GoRouter(
        initialLocation: '/a/overview',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) =>
                RoleShell(shell: shell, role: Role.admin),
            branches: [
              for (var i = 0; i < 5; i++)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: [
                        '/a/overview',
                        '/a/users',
                        '/a/mentors',
                        '/a/jobs',
                        '/a/settings',
                      ][i],
                      builder: (_, _) => Center(child: Text('Tab $i')),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verifiedSessionProvider.overrideWith(
              (ref) => Stream.value(session),
            ),
            appStoreProvider.overrideWith(_EmptyAppStore.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jonathan Ishimwe'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Tab 0'), findsOneWidget);
    });
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({required this.email, this.roleClaim = 'youth'});

  final String email;
  final String roleClaim;
  bool verified = false;
  bool signedOut = false;
  final List<bool> sendCalls = [];

  @override
  String? get currentEmail => email;

  @override
  bool get isEmailVerified => verified;

  @override
  Future<void> sendVerificationEmail({bool force = false}) async {
    sendCalls.add(force);
  }

  @override
  Future<bool> reloadAndCheckEmailVerification() async => verified;

  @override
  Future<String?> readRoleClaim({bool forceRefresh = false}) async => roleClaim;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _EmptyAppStore extends AppStore {}
