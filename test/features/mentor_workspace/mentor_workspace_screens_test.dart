import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentee.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentor_profile.dart';
import 'package:upbridge/features/mentor_workspace/domain/repositories/mentor_profile_repository.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentee_detail_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentees_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_profile_settings_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_sessions_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/providers/mentor_providers.dart';
import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';

import 'mentees_test.dart' as m;
import 'mentor_profile_test.dart' show tue18to20;
import 'mentor_sessions_test.dart' show FakeMentorSessions, session;

class FakeProfiles implements MentorProfileRepository {
  final saved = <MentorProfile>[];

  @override
  Stream<MentorProfile?> watchProfile(String mentorId) => const Stream.empty();

  @override
  Future<void> save(MentorProfile profile) async {
    saved.add(profile);
  }
}

const _profile = MentorProfile(
  id: 'alice',
  name: 'Alice Uwimana',
  title: 'Data analyst',
  verified: true,
  windows: [tue18to20],
  skills: ['Excel', 'SQL'],
);

Future<void> pump(
  WidgetTester tester,
  Widget page, {
  FakeMentorSessions? sessions,
  Stream<List<Session>>? mentorSessions,
  Stream<List<MenteeRecord>>? mentees,
  Stream<MentorProfile?>? profile,
  FakeProfiles? profiles,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => page),
      GoRoute(path: '/m-mentee/:id', builder: (_, s) => Text('mentee ${s.pathParameters['id']}')),
      GoRoute(path: '/m/sessions', builder: (_, _) => const Text('sessions tab')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        currentUserIdProvider.overrideWithValue('alice'),
        mentorClockProvider.overrideWithValue(() => m.now),
        sessionRepositoryProvider.overrideWithValue(sessions ?? FakeMentorSessions()),
        mentorSessionsProvider.overrideWith((ref) => mentorSessions ?? Stream.value(const <Session>[])),
        menteesProvider.overrideWith((ref) => mentees ?? Stream.value(const <MenteeRecord>[])),
        myMentorProfileProvider.overrideWith((ref) => profile ?? Stream.value(_profile)),
        mentorProfileRepositoryProvider.overrideWithValue(profiles ?? FakeProfiles()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> settleToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  group('MS1 sessions', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      await pump(tester, const MentorSessionsScreen(), mentorSessions: StreamController<List<Session>>().stream, settle: false);
      expect(find.text('No sessions yet'), findsNothing);
      expect(find.text('REQUESTS · 1'), findsNothing);
    });

    testWidgets('shows an error with retry', (tester) async {
      await pump(tester, const MentorSessionsScreen(), mentorSessions: Stream.error(const NetworkFailure('offline')));
      expect(find.text('Could not load your sessions'), findsOneWidget);
      expect(find.text('You seem to be offline. Check your connection.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('shows the empty state', (tester) async {
      await pump(tester, const MentorSessionsScreen());
      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('TUESDAY · 18:00–20:00'), findsOneWidget);
    });

    testWidgets('accepting a request confirms it as the mentor', (tester) async {
      final repo = FakeMentorSessions();
      await pump(
        tester,
        const MentorSessionsScreen(),
        sessions: repo,
        mentorSessions: Stream.value([session('r1', SessionState.requested), session('u1', SessionState.upcoming)]),
      );
      expect(find.text('REQUESTS · 1'), findsOneWidget);
      expect(find.text('UPCOMING'), findsOneWidget);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(repo.changes, ['r1:confirmed:mentor:alice:-']);
      expect(find.textContaining('add a meeting link'), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('declining asks first, then declines', (tester) async {
      final repo = FakeMentorSessions();
      await pump(tester, const MentorSessionsScreen(), sessions: repo, mentorSessions: Stream.value([session('r1', SessionState.requested)]));
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      expect(repo.changes, isEmpty);
      await tester.tap(find.text('Decline').last);
      await tester.pumpAndSettle();
      expect(repo.changes, ['r1:declined:mentor:alice:-']);
      await settleToast(tester);
    });

    testWidgets('a failed save shows the real error', (tester) async {
      final repo = FakeMentorSessions(failure: const PermissionFailure('rules'));
      await pump(tester, const MentorSessionsScreen(), sessions: repo, mentorSessions: Stream.value([session('r1', SessionState.requested)]));
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(find.text('You do not have access to this yet.'), findsOneWidget);
      await settleToast(tester);
    });
  });

  group('MM1 mentees', () {
    testWidgets('shows the empty state', (tester) async {
      await pump(tester, const MenteesScreen());
      expect(find.text('No mentees yet'), findsOneWidget);
    });

    testWidgets('shows an error with retry', (tester) async {
      await pump(tester, const MenteesScreen(), mentees: Stream.error(const NetworkFailure('offline')));
      expect(find.text('Could not load your mentees'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('lists mentees and filters those needing attention', (tester) async {
      final records = MenteeRecord.fromSessions([
        m.s('jean', SessionState.done, name: 'Jean Niyonzima', daysFromNow: -30),
        m.s('grace', SessionState.upcoming, name: 'Grace Iradukunda', daysFromNow: 2),
      ]);
      await pump(tester, const MenteesScreen(), mentees: Stream.value(records));
      expect(find.text('Jean Niyonzima'), findsOneWidget);
      expect(find.text('Grace Iradukunda'), findsOneWidget);
      expect(find.text('Quiet'), findsOneWidget);

      await tester.tap(find.text('Needs attention'));
      await tester.pumpAndSettle();
      expect(find.text('Jean Niyonzima'), findsOneWidget);
      expect(find.text('Grace Iradukunda'), findsNothing);

      await tester.tap(find.text('Jean Niyonzima'));
      await tester.pumpAndSettle();
      expect(find.text('mentee jean'), findsOneWidget);
    });
  });

  group('MM2 mentee detail', () {
    testWidgets('shows sessions and a quiet notice', (tester) async {
      final record = MenteeRecord.fromSessions([m.s('jean', SessionState.done, name: 'Jean Niyonzima', daysFromNow: -30)]).single;
      await pumpDetail(tester, Stream.value(record));
      expect(find.text('Jean Niyonzima'), findsWidgets);
      expect(find.text('Jean has been quiet'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('handles a youth who is not a mentee', (tester) async {
      await pumpDetail(tester, Stream.value(null));
      expect(find.text('Mentee not found'), findsOneWidget);
    });
  });

  group('MP1 profile', () {
    testWidgets('shows the profile and availability', (tester) async {
      await pump(tester, const MentorProfileSettingsScreen());
      expect(find.text('Alice Uwimana'), findsOneWidget);
      expect(find.text('Verified mentor'), findsOneWidget);
      expect(find.text('Tuesday · 18:00–20:00'), findsOneWidget);
      expect(find.text('Save changes'), findsNothing);
    });

    testWidgets('shows a missing profile honestly', (tester) async {
      await pump(tester, const MentorProfileSettingsScreen(), profile: Stream.value(null));
      expect(find.text('No mentor profile yet'), findsOneWidget);
    });

    testWidgets('toggling accepting enables save, which saves the draft', (tester) async {
      final profiles = FakeProfiles();
      await pump(tester, const MentorProfileSettingsScreen(), profiles: profiles);
      await tester.tap(find.text('Accepting new mentees'));
      await tester.pumpAndSettle();
      expect(find.text('You have unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(profiles.saved.single.accepting, isTrue);
      expect(find.text('Save changes'), findsNothing);
      await settleToast(tester);
    });

    testWidgets('blocks saving when the change is invalid', (tester) async {
      final profiles = FakeProfiles();
      await pump(tester, const MentorProfileSettingsScreen(), profiles: profiles);
      await tester.tap(find.byTooltip('Remove Tuesday · 18:00–20:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accepting new mentees'));
      await tester.pumpAndSettle();
      expect(find.text('Add at least one time before accepting new mentees.'), findsOneWidget);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(profiles.saved, isEmpty);
    });
  });
}

Future<void> pumpDetail(WidgetTester tester, Stream<MenteeRecord?> record) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        currentUserIdProvider.overrideWithValue('alice'),
        mentorClockProvider.overrideWithValue(() => m.now),
        menteeProvider('jean').overrideWith((ref) => record),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const MenteeDetailScreen(menteeId: 'jean'))]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
