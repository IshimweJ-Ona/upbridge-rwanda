import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentor_directory_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentor_profile_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/my_mentorship_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/request_sent_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/request_session_screen.dart';
import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';

import 'mentor_filter_test.dart' show mentor, session;

class _FakeDirectory implements MentorDirectoryRepository {
  _FakeDirectory(this.result);

  final Mentor? result;

  @override
  Stream<List<Mentor>> watchMentors() => const Stream.empty();

  @override
  Stream<Mentor?> watchMentor(String mentorId) => Stream.value(result);
}

class FakeSessions implements SessionRepository {
  FakeSessions({this.single, this.failure});

  final Session? single;
  final AppFailure? failure;
  final requests = <SessionRequest>[];
  final withdrawn = <String>[];
  final statusChanges = <String>[];

  @override
  Stream<Session?> watchSession(String sessionId) => Stream.value(single);

  @override
  Future<String> request(SessionRequest request) async {
    if (failure != null) throw failure!;
    requests.add(request);
    return 'new-session';
  }

  @override
  Future<void> withdraw(String sessionId, {required String youthId}) async {
    withdrawn.add('$sessionId:$youthId');
  }

  @override
  Future<void> changeStatus(
    String sessionId, {
    required String toStatus,
    required SessionActor by,
    required String actorId,
    String? meetingLink,
  }) async {
    statusChanges.add('$sessionId:$toStatus:${by.name}:$actorId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  Mentor? mentorResult,
  FakeSessions? sessions,
  List<Session> mine = const [],
  Size size = const Size(800, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => page),
      GoRoute(
        path: '/request-sent/:id',
        builder: (_, state) => Text('sent ${state.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        mentorDirectoryRepositoryProvider.overrideWithValue(
          _FakeDirectory(mentorResult),
        ),
        sessionRepositoryProvider.overrideWithValue(sessions ?? FakeSessions()),
        mySessionsProvider.overrideWith((ref) => Stream.value(mine)),
        currentUserIdProvider.overrideWithValue('youth-1'),
        currentUserNameProvider.overrideWithValue('Jean'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets the auto-dismissing toast finish so no timer outlives the test.
Future<void> settleToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  group('M2 mentor profile', () {
    testWidgets('shows the mentor and offers a request', (tester) async {
      await pumpPage(
        tester,
        const MentorProfileScreen(mentorId: 'alice'),
        mentorResult: mentor('alice', 'Alice Uwimana'),
      );
      expect(find.text('Alice Uwimana'), findsOneWidget);
      expect(find.text('Verified mentor'), findsOneWidget);
      expect(find.text('Request a session'), findsOneWidget);
    });

    testWidgets('blocks requests when the mentor is full', (tester) async {
      await pumpPage(
        tester,
        const MentorProfileScreen(mentorId: 'alice'),
        mentorResult: mentor('alice', 'Alice Uwimana', accepting: false),
      );
      expect(find.text('Request a session'), findsNothing);
      expect(find.text('Not taking requests right now'), findsOneWidget);
    });

    testWidgets('explains a missing mentor', (tester) async {
      await pumpPage(tester, const MentorProfileScreen(mentorId: 'gone'));
      expect(find.text('Mentor not found'), findsOneWidget);
    });
  });

  group('M3 request a session', () {
    final startsAt = DateTime.now().toUtc().add(const Duration(days: 3));
    final alice = mentor(
      'alice',
      'Alice Uwimana',
      slots: [SessionSlot('THU 22 OCT', '18:00', startsAt: startsAt)],
    );

    testWidgets('saves the request, then opens the sent screen', (
      tester,
    ) async {
      final sessions = FakeSessions();
      await pumpPage(
        tester,
        const RequestSessionScreen(mentorId: 'alice'),
        mentorResult: alice,
        sessions: sessions,
      );

      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(sessions.requests, isEmpty, reason: 'nothing is chosen yet');

      await tester.tap(find.text('Career advice'));
      await tester.tap(find.text('THU 22 OCT · 18:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      final sent = sessions.requests.single;
      expect(sent.requesterId, 'youth-1');
      expect(sent.mentorId, 'alice');
      expect(sent.topic, 'Career advice');
      expect(sent.startsAt, startsAt);
      expect(find.text('sent new-session'), findsOneWidget);
    });

    testWidgets('stays on the form and explains a failed save', (tester) async {
      await pumpPage(
        tester,
        const RequestSessionScreen(mentorId: 'alice'),
        mentorResult: alice,
        sessions: FakeSessions(failure: const PermissionFailure()),
      );
      await tester.tap(find.text('Career advice'));
      await tester.tap(find.text('THU 22 OCT · 18:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send request'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('You do not have access to this yet.'), findsOneWidget);
      expect(find.textContaining('sent '), findsNothing);
      await settleToast(tester);
    });

    testWidgets('says so when no times are open', (tester) async {
      await pumpPage(
        tester,
        const RequestSessionScreen(mentorId: 'alice'),
        mentorResult: mentor('alice', 'Alice Uwimana'),
      );
      expect(find.text('No open times right now'), findsOneWidget);
    });
  });

  group('M4 request sent', () {
    testWidgets('confirms using the saved session', (tester) async {
      await pumpPage(
        tester,
        const RequestSentScreen(sessionId: 's1'),
        sessions: FakeSessions(
          single: session('Alice Uwimana', SessionState.requested),
        ),
      );
      expect(find.text('Request sent to Alice'), findsOneWidget);
      expect(find.text('Career advice'), findsOneWidget);
    });

    testWidgets('does not claim success without a session', (tester) async {
      await pumpPage(tester, const RequestSentScreen(sessionId: 'gone'));
      expect(find.textContaining('Request sent'), findsNothing);
      expect(find.text('Request not found'), findsOneWidget);
    });
  });

  group('M5 my mentorship', () {
    final mine = [
      session('Alice Uwimana', SessionState.upcoming),
      session('Grace Mukamana', SessionState.requested),
      session('Eric Habimana', SessionState.declined),
      session('David Munyentwari', SessionState.done),
    ];

    testWidgets('groups sessions with their real statuses', (tester) async {
      await pumpPage(tester, const MyMentorshipScreen(), mine: mine);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Declined'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Join on Google Meet'), findsOneWidget);
    });

    testWidgets('withdraws a pending request after confirming', (tester) async {
      final sessions = FakeSessions();
      await pumpPage(
        tester,
        const MyMentorshipScreen(),
        mine: mine,
        sessions: sessions,
      );
      await tester.tap(
        find.textContaining(RegExp('tap to withdraw', caseSensitive: false)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();

      expect(sessions.withdrawn, [
        'Grace Mukamana-${SessionState.requested}:youth-1',
      ]);
      await settleToast(tester);
    });

    testWidgets('cancels a confirmed session as the youth', (tester) async {
      final sessions = FakeSessions();
      await pumpPage(
        tester,
        const MyMentorshipScreen(),
        mine: mine,
        sessions: sessions,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel session'));
      await tester.pumpAndSettle();

      expect(sessions.statusChanges, [
        'Alice Uwimana-${SessionState.upcoming}:cancelled:youth:youth-1',
      ]);
      await settleToast(tester);
    });

    testWidgets('shows an empty state with a way forward', (tester) async {
      await pumpPage(tester, const MyMentorshipScreen());
      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('Find a mentor'), findsOneWidget);
    });

    testWidgets('fits a small phone without overflow', (tester) async {
      await pumpPage(
        tester,
        const MyMentorshipScreen(),
        mine: mine,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
