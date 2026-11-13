import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_overview_screen.dart';
import 'package:upbridge/features/home/presentation/pages/home_screen.dart';
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

  testWidgets('admin overview clearly identifies its sample statistics', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWith(_AdminStore.new)],
        child: const MaterialApp(home: AdminOverviewScreen()),
      ),
    );

    expect(find.text('Demonstration data'), findsOneWidget);
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
