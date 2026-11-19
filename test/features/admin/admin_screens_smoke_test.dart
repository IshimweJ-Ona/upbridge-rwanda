// Smoke and interaction tests for admin screens, demo notices, and live count banner.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/utils/kigali_time.dart';
import 'package:upbridge/features/admin/presentation/pages/add_user_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/admin_overview_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/check_application_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/new_listing_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/reported_listing_screen.dart';
import 'package:upbridge/features/admin/presentation/pages/verify_mentor_screen.dart';
import 'package:upbridge/features/admin/presentation/providers/admin_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

void main() {
  testWidgets('all admin detail screens label demonstration data', (
    tester,
  ) async {
    for (final screen in const <Widget>[
      AddUserScreen(),
      VerifyMentorScreen(applicantId: 'sylvestre'),
      ReportedListingScreen(listingId: 'irembo'),
      CheckApplicationScreen(forwardId: 'f-patrick'),
      NewListingScreen(),
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appStoreProvider.overrideWith(_AdminStore.new)],
          child: MaterialApp(home: screen),
        ),
      );
      expect(find.text('Demonstration data'), findsOneWidget);
    }
  });

  testWidgets('NewListingScreen Use example fills valid non-past dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWith(_AdminStore.new)],
        child: const MaterialApp(home: NewListingScreen()),
      ),
    );

    await tester.tap(find.text('Use example'));
    await tester.pump();
    expect(find.text('Excel reporting assistant'), findsOneWidget);

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String fmt(DateTime d) =>
        '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
    final today = KigaliTime.startOfDay(DateTime.now());
    expect(find.text(fmt(today.add(const Duration(days: 20)))), findsOneWidget);
    expect(find.text(fmt(today.add(const Duration(days: 34)))), findsOneWidget);
  });

  testWidgets(
    'AdminOverviewScreen shows live Firestore account count for signed-in admin',
    (tester) async {
      const adminSession = VerifiedSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: 'admin-uid',
        email: 'admin@upbridge.rw',
        displayName: 'Jonathan Ishimwe',
        role: Role.admin,
        onboarded: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verifiedSessionProvider.overrideWith(
              (ref) => Stream.value(adminSession),
            ),
            adminUserCountProvider.overrideWith((ref) async => 17),
          ],
          child: const MaterialApp(home: AdminOverviewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Firestore accounts'), findsOneWidget);
      expect(
        find.text('17 registered users currently stored in Firestore'),
        findsOneWidget,
      );
    },
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
