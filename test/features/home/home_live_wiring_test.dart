// Verifies HomeScreen, CheckInScreen, and NotificationsScreen work directly with live providers without AppStore.user.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/features/home/domain/entities/check_in.dart';
import 'package:upbridge/features/home/domain/entities/home_summary.dart';
import 'package:upbridge/features/home/domain/entities/next_step.dart';
import 'package:upbridge/features/home/domain/repositories/check_in_repository.dart';
import 'package:upbridge/features/home/domain/repositories/notification_repository.dart';
import 'package:upbridge/features/home/presentation/pages/check_in_screen.dart';
import 'package:upbridge/features/home/presentation/pages/home_screen.dart';
import 'package:upbridge/features/home/presentation/pages/notifications_screen.dart';
import 'package:upbridge/features/home/presentation/providers/home_providers.dart';
import 'package:upbridge/features/home/presentation/providers/notification_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

void main() {
  const liveSession = VerifiedSession(
    firebaseInitialized: true,
    signedIn: true,
    emailVerified: true,
    uid: 'live-uid-1',
    email: 'jean@upbridge.rw',
    displayName: 'Jean Mugabo',
    role: Role.youth,
    onboarded: true,
  );

  testWidgets('HomeScreen renders live summary without AppStore user', (
    tester,
  ) async {
    const summary = HomeSummary(
      approvedTasks: 2,
      pendingReviews: 1,
      projectCount: 3,
      publishedOpportunityCount: 5,
      nextStep: NextStep(
        kind: NextStepKind.reviseTask,
        title: 'Revise HTML card layout',
        message: 'Check mentor notes on semantic tags.',
        route: '/learn',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          verifiedSessionProvider.overrideWith(
            (ref) => Stream.value(liveSession),
          ),
          homeSummaryProvider('live-uid-1')
              .overrideWith((ref) async => summary),
          monthlyCheckInProvider((
            userId: 'live-uid-1',
            monthKey: currentKigaliMonthKey(),
          )).overrideWith((ref) async => null),
          unreadNotificationCountProvider('live-uid-1')
              .overrideWith((ref) => Stream.value(2)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Muraho, Jean'), findsNWidgets(2));
    expect(find.text('Demo preview'), findsNothing);
    expect(find.text('Live Firebase summary'), findsOneWidget);
    expect(find.text('Revise HTML card layout'), findsOneWidget);
  });

  testWidgets('CheckInScreen submits via live CheckInRepository', (
    tester,
  ) async {
    final repo = _FakeCheckInRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          verifiedSessionProvider.overrideWith(
            (ref) => Stream.value(liveSession),
          ),
          checkInRepositoryProvider.overrideWithValue(repo),
          monthlyCheckInProvider((
            userId: 'live-uid-1',
            monthKey: currentKigaliMonthKey(),
          )).overrideWith((ref) async => null),
          homeSummaryProvider('live-uid-1').overrideWith(
            (ref) async => const HomeSummary(
              approvedTasks: 0,
              pendingReviews: 0,
              projectCount: 0,
              publishedOpportunityCount: 0,
            ),
          ),
        ],
        child: const MaterialApp(home: CheckInScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demo preview'), findsNothing);
    await tester.tap(find.text('5'));
    await tester.pump();
    final appliedOption = find.text('Yes, through UpBridge');
    await tester.ensureVisible(appliedOption);
    await tester.tap(appliedOption);
    await tester.pump();

    final noteField = find.byType(TextField).last;
    await tester.ensureVisible(noteField);
    await tester.enterText(noteField, 'Completed my responsive grid task.');
    await tester.pump();

    final submitButton = find.text('Submit check-in');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repo.submitted, hasLength(1));
    expect(repo.submitted.single.userId, 'live-uid-1');
    expect(repo.submitted.single.usefulness, 5);
    expect(repo.submitted.single.applied, isTrue);
  });

  testWidgets('NotificationsScreen triggers live markRead and markAllRead', (
    tester,
  ) async {
    final repo = _FakeNotificationRepo();
    const items = [
      AppNotification(
        id: 'notif-1',
        title: 'Task 2 approved',
        body: 'Your CSS project passed review.',
        time: 'Just now',
        icon: Icons.verified_outlined,
        tone: Tone.success,
        unread: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          verifiedSessionProvider.overrideWith(
            (ref) => Stream.value(liveSession),
          ),
          notificationRepositoryProvider.overrideWithValue(repo),
          userNotificationsProvider('live-uid-1')
              .overrideWith((ref) => Stream.value(items)),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demo preview'), findsNothing);
    await tester.tap(find.text('Mark all read'));
    await tester.pump();
    expect(repo.markedAllFor, ['live-uid-1']);

    await tester.tap(find.text('Task 2 approved'));
    await tester.pump();
    expect(repo.markedRead, [('live-uid-1', 'notif-1')]);
  });
}

class _FakeCheckInRepo implements CheckInRepository {
  final List<CheckIn> submitted = [];

  @override
  Future<CheckIn?> getForMonth(String userId, String monthKey) async => null;

  @override
  Future<void> submit(CheckIn checkIn) async {
    submitted.add(checkIn);
  }
}

class _FakeNotificationRepo implements NotificationRepository {
  final List<(String, String)> markedRead = [];
  final List<String> markedAllFor = [];

  @override
  Stream<List<AppNotification>> watch(String userId) => const Stream.empty();

  @override
  Stream<int> watchUnreadCount(String userId) => const Stream.empty();

  @override
  Future<void> markAllRead(String userId) async {
    markedAllFor.add(userId);
  }

  @override
  Future<void> markRead(String userId, String notificationId) async {
    markedRead.add((userId, notificationId));
  }
}
