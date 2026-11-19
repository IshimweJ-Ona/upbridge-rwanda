// Verifies demo notices and non-blank rendering on youth home and admin screens.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_jobs_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_mentors_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_overview_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_settings_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_users_screen.dart';
import 'package:upbridge/features/home/presentation/pages/check_in_screen.dart';
import 'package:upbridge/features/home/presentation/pages/home_screen.dart';
import 'package:upbridge/features/home/presentation/pages/notifications_screen.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

void main() {
  testWidgets('youth home clearly identifies its demo data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWith(_YouthStore.new)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('Demo preview'), findsOneWidget);
    expect(find.text('Muraho, Aline'), findsNWidgets(2));
  });

  testWidgets('check-in and notifications clearly identify demo mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWith(_YouthStore.new)],
        child: const MaterialApp(home: CheckInScreen()),
      ),
    );
    expect(find.text('Demo preview'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWith(_YouthStore.new)],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    expect(find.text('Demo preview'), findsOneWidget);
  });

  testWidgets('admin screens clearly identify demonstration data', (
    tester,
  ) async {
    for (final screen in const <Widget>[
      AdminOverviewScreen(),
      AdminUsersScreen(),
      AdminMentorsScreen(),
      AdminJobsScreen(),
      AdminSettingsScreen(),
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appStoreProvider.overrideWith(_AdminStore.new)],
          child: MaterialApp(home: screen),
        ),
      );
      expect(find.text('Demonstration data'), findsOneWidget);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWith(_AdminStore.new)],
        child: const MaterialApp(home: AdminOverviewScreen()),
      ),
    );
    expect(find.text('Pilot overview'), findsNWidgets(2));
  });
}

class _YouthStore extends AppStore {
  @override
  AppData build() => super.build().copyWith(
    user: const AppUser(
      id: 'youth-test',
      name: 'Aline Uwase',
      phone: '0780000000',
      role: Role.youth,
    ),
  );
}

class _AdminStore extends AppStore {
  @override
  AppData build() => super.build().copyWith(
    user: const AppUser(
      id: 'admin-test',
      name: 'Jonathan Ishimwe',
      phone: '0780000001',
      role: Role.admin,
    ),
  );
}
