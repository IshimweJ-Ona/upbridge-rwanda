// Tests VerifyEmailScreen flows and RoleShell adaptive rendering.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/auth/verify_email_screen.dart';
import 'package:upbridge/app/router/role_shell.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

void main() {
  group('VerifyEmailScreen', () {
    testWidgets(
      'resends verification, verifies email, and routes admin to /a/overview',
      (tester) async {
        final auth = _FakeAuthService(
          email: 'authapp05@gmail.com',
          roleClaim: 'admin',
        );
        final destinations = <String>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(auth)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: VerifyEmailScreen(onNavigate: destinations.add),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('authapp05@gmail.com'), findsOneWidget);
        expect(auth.sendCalls, isEmpty);

        await tester.tap(find.text('Send verification email'));
        await tester.pump();
        expect(auth.sendCalls, [true]);

        auth.verified = true;
        await tester.tap(find.text('I verified my email'));
        await tester.pumpAndSettle();

        expect(destinations, [AppRoutes.adminOverview]);
      },
    );

    testWidgets(
      'shows error when confirmation is still pending and supports sign out',
      (tester) async {
        final auth = _FakeAuthService(email: 'student@upbridge.rw');
        final destinations = <String>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(auth)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
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
        expect(destinations, [AppRoutes.welcome]);
      },
    );
  });

  group('RoleShell', () {
    testWidgets(
      'displays live admin NavigationRail on wide desktop viewports',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const session = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'admin-uid',
          email: 'authapp05@gmail.com',
          displayName: 'Jonathan Ishimwe',
          role: UserRole.admin,
          onboarded: true,
        );

        final router = GoRouter(
          initialLocation: AppRoutes.adminOverview,
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, shell) =>
                  RoleShell(navigationShell: shell, role: UserRole.admin),
              branches: [
                for (var i = 0; i < 5; i++)
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: [
                          '/a/overview',
                          '/a/users',
                          '/a/mentors',
                          '/a/catalog',
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
              appSessionProvider.overrideWith((ref) => Stream.value(session)),
              pendingMentorApplicationsProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
            ],
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
        expect(find.text('Tab 0'), findsOneWidget);
      },
    );
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({required this.email, this.roleClaim = 'student'});

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
