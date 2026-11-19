import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/mentor_workspace/presentation/providers/mentor_providers.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';

/// Records mentor status changes; [gate] holds a change open to test double taps.
class FakeMentorSessions implements SessionRepository {
  FakeMentorSessions({this.mine = const [], this.failure, this.gate});

  final List<Session> mine;
  final AppFailure? failure;
  final Completer<void>? gate;
  final changes = <String>[];

  @override
  Stream<List<Session>> watchForMentor(String mentorId) => Stream.value(mine);

  @override
  Future<void> changeStatus(
    String sessionId, {
    required String toStatus,
    required SessionActor by,
    required String actorId,
    String? meetingLink,
  }) async {
    changes.add('$sessionId:$toStatus:${by.name}:$actorId:${meetingLink ?? '-'}');
    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Session session(String id, SessionState state) => Session(
  id: id,
  mentorId: 'alice',
  mentorName: 'Alice',
  youthId: 'youth-$id',
  youthName: 'Jean $id',
  day: 'THU 19 NOV',
  time: '18:00',
  topic: 'Career advice',
  state: state,
);

ProviderContainer container(FakeMentorSessions repo, {String? userId = 'alice'}) {
  final c = ProviderContainer(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWithValue(userId),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('groups sessions into requests, upcoming and newest-first past', () {
    final g = MentorSessionGroups([
      session('1', SessionState.done),
      session('2', SessionState.requested),
      session('3', SessionState.upcoming),
      session('4', SessionState.declined),
      session('5', SessionState.done),
    ]);
    expect(g.requests.map((s) => s.id), ['2']);
    expect(g.upcoming.map((s) => s.id), ['3']);
    expect(g.past.map((s) => s.id), ['5', '1']);
    expect(g.isEmpty, isFalse);
    expect(MentorSessionGroups(const []).isEmpty, isTrue);
  });

  group('MentorSessionActionsNotifier', () {
    test('accept confirms as the mentor and attaches the meeting link', () async {
      final repo = FakeMentorSessions();
      final c = container(repo);
      await c.read(mentorSessionActionsProvider.notifier).accept('s1', meetingLink: ' https://meet.google.com/x ');
      expect(repo.changes, ['s1:confirmed:mentor:alice:https://meet.google.com/x']);
    });

    test('accept without a link sends no link', () async {
      final repo = FakeMentorSessions();
      await container(repo).read(mentorSessionActionsProvider.notifier).accept('s1');
      expect(repo.changes, ['s1:confirmed:mentor:alice:-']);
    });

    test('decline, complete and cancel use the mentor statuses', () async {
      final repo = FakeMentorSessions();
      final actions = container(repo).read(mentorSessionActionsProvider.notifier);
      await actions.decline('a');
      await actions.complete('b');
      await actions.cancel('c');
      expect(repo.changes, [
        'a:declined:mentor:alice:-',
        'b:completed:mentor:alice:-',
        'c:cancelled:mentor:alice:-',
      ]);
    });

    test('ignores a second tap while the first is saving', () async {
      final gate = Completer<void>();
      final repo = FakeMentorSessions(gate: gate);
      final c = container(repo);
      final actions = c.read(mentorSessionActionsProvider.notifier);
      final first = actions.accept('s1');
      expect(c.read(mentorSessionActionsProvider), {'s1'});
      await actions.accept('s1');
      gate.complete();
      await first;
      expect(repo.changes, hasLength(1));
      expect(c.read(mentorSessionActionsProvider), isEmpty);
    });

    test('signed out mentors cannot act', () async {
      final repo = FakeMentorSessions();
      await expectLater(
        container(repo, userId: null).read(mentorSessionActionsProvider.notifier).accept('s1'),
        throwsA(isA<PermissionFailure>()),
      );
      expect(repo.changes, isEmpty);
    });

    test('clears the busy flag when saving fails', () async {
      final repo = FakeMentorSessions(failure: const ConflictFailure('invalid-transition'));
      final c = container(repo);
      await expectLater(c.read(mentorSessionActionsProvider.notifier).decline('s1'), throwsA(isA<ConflictFailure>()));
      expect(c.read(mentorSessionActionsProvider), isEmpty);
    });
  });

  group('role rules the repository enforces', () {
    test('only mentors answer requests; youth can only cancel', () {
      bool can(String from, String to, SessionActor by) =>
          MentorSessionStatus.canTransition(from: from, to: to, by: by);
      expect(can('requested', 'confirmed', SessionActor.mentor), isTrue);
      expect(can('requested', 'declined', SessionActor.mentor), isTrue);
      expect(can('confirmed', 'completed', SessionActor.mentor), isTrue);
      expect(can('requested', 'confirmed', SessionActor.youth), isFalse);
      expect(can('confirmed', 'completed', SessionActor.youth), isFalse);
      expect(can('requested', 'completed', SessionActor.mentor), isFalse);
      expect(can('declined', 'confirmed', SessionActor.mentor), isFalse);
    });
  });
}
