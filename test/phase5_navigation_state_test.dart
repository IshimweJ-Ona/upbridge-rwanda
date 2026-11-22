import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/router/role_shell.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  testWidgets(
    'Phase 5 per-tab StatefulNavigationShell loads selected tab root, avoids stale nested routes, and pops to root on re-tap',
    (tester) async {
      const session = AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'student-1',
        displayName: 'Aline Uwase',
        role: UserRole.student,
        onboarded: true,
        accountExists: true,
      );

      final rootKey = GlobalKey<NavigatorState>();
      final branchKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

      final router = GoRouter(
        navigatorKey: rootKey,
        initialLocation: AppRoutes.studentHome,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) =>
                RoleShell(role: UserRole.student, navigationShell: shell),
            branches: [
              StatefulShellBranch(
                navigatorKey: branchKeys[0],
                routes: [
                  GoRoute(
                    path: AppRoutes.studentHome,
                    builder: (_, _) => const Center(child: Text('Home Root')),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: branchKeys[1],
                routes: [
                  GoRoute(
                    path: '/learn',
                    builder: (_, _) => const Center(child: Text('Learn Root')),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: branchKeys[2],
                routes: [
                  GoRoute(
                    path: '/mentors',
                    builder: (ctx, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Mentors Root'),
                          ElevatedButton(
                            onPressed: () => ctx.go('/mentors/sub'),
                            child: const Text('Open sub'),
                          ),
                        ],
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'sub',
                        builder: (_, _) =>
                            const Center(child: Text('Mentors Sub')),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: branchKeys[3],
                routes: [
                  GoRoute(
                    path: '/jobs',
                    builder: (_, _) => const Center(child: Text('Jobs Root')),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: branchKeys[4],
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (_, _) =>
                        const Center(child: Text('Profile Root')),
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
            liveUnreadNotificationCountProvider('student-1')
                .overrideWith((ref) => Stream.value(0)),
          ],
          child: MaterialApp.router(
            theme: buildAppTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Root'), findsOneWidget);

      // Navigate to Mentors tab, then into nested route.
      await tester.tap(find.text('Mentors'));
      await tester.pumpAndSettle();
      expect(find.text('Mentors Root'), findsOneWidget);

      await tester.tap(find.text('Open sub'));
      await tester.pumpAndSettle();
      expect(find.text('Mentors Sub'), findsOneWidget);

      // Visit Opportunities tab: shows Jobs Root (never Home or stale Mentors sub).
      await tester.tap(find.text('Opportunities'));
      await tester.pumpAndSettle();
      expect(find.text('Jobs Root'), findsOneWidget);

      // Return to Mentors tab preserves Mentors Sub, then re-tapping pops back to Mentors Root.
      await tester.tap(find.text('Mentors'));
      await tester.pumpAndSettle();
      expect(find.text('Mentors Sub'), findsOneWidget);

      await tester.tap(find.text('Mentors'));
      await tester.pumpAndSettle();
      expect(find.text('Mentors Root'), findsOneWidget);
    },
  );
}
