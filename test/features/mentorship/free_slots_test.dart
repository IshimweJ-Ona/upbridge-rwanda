import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/domain/entities/session_slot.dart';
import 'package:upbridge/features/mentorship/domain/usecases/free_slots.dart';

void main() {
  final now = DateTime.utc(2026, 10, 20, 8);

  SessionSlot slot(DateTime startsAt) =>
      SessionSlot('DAY', 'TIME', startsAt: startsAt);

  Session session(DateTime startsAt, SessionState state) => Session(
    id: 's-$startsAt',
    mentorId: 'mentor-1',
    mentorName: 'Alice Uwimana',
    youthId: 'youth-1',
    youthName: 'Jean',
    day: 'DAY',
    time: 'TIME',
    topic: 'Career advice',
    state: state,
    startsAt: startsAt,
  );

  test('drops slots that are too soon, untimed, or already booked', () {
    final tooSoon = DateTime.utc(2026, 10, 20, 16); // 8 h away
    final booked = DateTime.utc(2026, 10, 22, 16);
    final free = DateTime.utc(2026, 10, 22, 17);
    final result = const FreeSlots()(
      offered: [
        slot(free),
        slot(booked),
        slot(tooSoon),
        const SessionSlot('TUE 20 OCT', '18:30'), // demo slot, no instant
      ],
      mySessions: [session(booked, SessionState.requested)],
      now: now,
    );
    expect(result.map((s) => s.startsAt), [free]);
  });

  test('declined or finished sessions free their slot again', () {
    final time = DateTime.utc(2026, 10, 22, 16);
    final result = const FreeSlots()(
      offered: [slot(time)],
      mySessions: [
        session(time, SessionState.declined),
        session(time, SessionState.done),
      ],
      now: now,
    );
    expect(result, hasLength(1));
  });

  test('sorts soonest first', () {
    final later = DateTime.utc(2026, 10, 24, 8);
    final sooner = DateTime.utc(2026, 10, 22, 8);
    final result = const FreeSlots()(
      offered: [slot(later), slot(sooner)],
      mySessions: const [],
      now: now,
    );
    expect(result.map((s) => s.startsAt), [sooner, later]);
  });
}
