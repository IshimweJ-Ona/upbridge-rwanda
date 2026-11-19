import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/features/mentor_workspace/data/models/mentee_model.dart';
import 'package:upbridge/features/mentor_workspace/data/repositories/mentee_repository_impl.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentee.dart';
import 'package:upbridge/features/mentor_workspace/presentation/providers/mentor_providers.dart';
import 'package:upbridge/shared/models/models.dart';

import 'mentor_sessions_test.dart' show FakeMentorSessions;

final now = DateTime.utc(2026, 11, 19, 12);

Session s(
  String youthId,
  SessionState state, {
  String name = '',
  int daysFromNow = 0,
  String id = '',
}) => Session(
  id: id.isEmpty ? '$youthId-$state-$daysFromNow' : id,
  mentorId: 'alice',
  mentorName: 'Alice',
  youthId: youthId,
  youthName: name.isEmpty ? youthId : name,
  day: 'THU 19 NOV',
  time: '18:00',
  topic: 'Career advice',
  state: state,
  startsAt: now.add(Duration(days: daysFromNow)),
);

void main() {
  group('MenteeRecord.fromSessions', () {
    test('only youth with a confirmed or finished session are mentees', () {
      final mentees = MenteeRecord.fromSessions([
        s('jean', SessionState.done, name: 'Jean Niyonzima', daysFromNow: -3),
        s('emile', SessionState.requested, name: 'Emile Rwema', daysFromNow: 2),
        s('aline', SessionState.declined, name: 'Aline Uwase'),
        s('grace', SessionState.upcoming, name: 'Grace Iradukunda', daysFromNow: 4),
      ]);
      expect(mentees.map((m) => m.youthId), ['grace', 'jean']);
    });

    test('counts sessions and finds the last and next session', () {
      final m = MenteeRecord.fromSessions([
        s('jean', SessionState.done, daysFromNow: -10),
        s('jean', SessionState.done, daysFromNow: -3),
        s('jean', SessionState.upcoming, daysFromNow: 5),
        s('jean', SessionState.upcoming, daysFromNow: 2),
        s('jean', SessionState.requested, daysFromNow: 9),
      ]).single;
      expect(m.sessionsDone, 2);
      expect(m.upcoming, 2);
      expect(m.pendingRequests, 1);
      expect(m.lastSessionAt, now.subtract(const Duration(days: 3)));
      expect(m.nextSessionAt, now.add(const Duration(days: 2)));
      expect(m.sessions.first.startsAt, now.subtract(const Duration(days: 10)));
    });

    test('ignores sessions with no youth', () {
      expect(MenteeRecord.fromSessions([s('', SessionState.done)]), isEmpty);
    });
  });

  group('attention', () {
    MenteeRecord one(List<Session> list) => MenteeRecord.fromSessions(list).single;

    test('a pending request needs an answer first', () {
      final m = one([s('jean', SessionState.upcoming, daysFromNow: 1), s('jean', SessionState.requested, daysFromNow: 3)]);
      expect(m.attentionAt(now), MenteeAttention.wantsSession);
      expect(m.needsAttentionAt(now), isTrue);
    });

    test('a booked session is on track', () {
      expect(one([s('jean', SessionState.upcoming, daysFromNow: 1)]).attentionAt(now), MenteeAttention.onTrack);
    });

    test('quiet after 21 days with nothing booked', () {
      expect(one([s('jean', SessionState.done, daysFromNow: -5)]).attentionAt(now), MenteeAttention.onTrack);
      expect(one([s('jean', SessionState.done, daysFromNow: -22)]).attentionAt(now), MenteeAttention.quiet);
    });
  });

  group('MenteeModel', () {
    test('maps attention to status text and tone', () {
      expect(MenteeModel.statusOf(MenteeAttention.wantsSession), ('Wants a session', Tone.info));
      expect(MenteeModel.statusOf(MenteeAttention.quiet), ('Quiet', Tone.warning));
      expect(MenteeModel.statusOf(MenteeAttention.onTrack), ('On track', Tone.success));
    });

    test('does not invent progress or district', () {
      final m = MenteeModel.toMentee(
        MenteeRecord.fromSessions([s('jean', SessionState.done, name: 'Jean N', daysFromNow: -1)]).single,
        now,
      );
      expect(m.total, 0);
      expect(m.approved, 0);
      expect(m.district, '');
      expect(m.lastActive, 'Last session yesterday');
    });

    test('describes last activity', () {
      MenteeRecord rec(List<Session> l) => MenteeRecord.fromSessions(l).single;
      expect(MenteeModel.lastActiveLabel(rec([s('j', SessionState.done, daysFromNow: -6)]), now), 'Last session 6 days ago');
      expect(MenteeModel.lastActiveLabel(rec([s('j', SessionState.done)]), now), 'Last session today');
      expect(MenteeModel.lastActiveLabel(rec([s('j', SessionState.upcoming, daysFromNow: 2)]), now), startsWith('Next session'));
    });
  });

  group('MenteeFilter', () {
    final mentees = MenteeRecord.fromSessions([
      s('jean', SessionState.done, name: 'Jean Niyonzima', daysFromNow: -30),
      s('grace', SessionState.upcoming, name: 'Grace Iradukunda', daysFromNow: 2),
    ]);

    test('filters by chip and by name', () {
      expect(const MenteeFilter().apply(mentees, now), hasLength(2));
      expect(const MenteeFilter(chip: MenteeFilter.needsAttention).apply(mentees, now).single.youthId, 'jean');
      expect(const MenteeFilter(chip: MenteeFilter.onTrack).apply(mentees, now).single.youthId, 'grace');
      expect(const MenteeFilter(query: ' GRA ').apply(mentees, now).single.youthId, 'grace');
      expect(const MenteeFilter(query: 'zzz').apply(mentees, now), isEmpty);
    });
  });

  group('MenteeRepositoryImpl', () {
    test('builds mentees from the mentor sessions and finds one', () async {
      final repo = MenteeRepositoryImpl(
        FakeMentorSessions(mine: [s('jean', SessionState.done, daysFromNow: -1), s('grace', SessionState.requested)]),
      );
      expect((await repo.watchMentees('alice').first).map((m) => m.youthId), ['jean']);
      expect((await repo.watchMentee('alice', 'jean').first)?.youthId, 'jean');
      expect(await repo.watchMentee('alice', 'grace').first, isNull);
    });
  });
}
