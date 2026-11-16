import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';

void main() {
  group('MentorSessionStatus.canTransition', () {
    const s = MentorSessionStatus.requested;
    const c = MentorSessionStatus.confirmed;

    test('mentor confirms or declines a pending request', () {
      expect(
        MentorSessionStatus.canTransition(
          from: s,
          to: c,
          by: SessionActor.mentor,
        ),
        isTrue,
      );
      expect(
        MentorSessionStatus.canTransition(
          from: s,
          to: MentorSessionStatus.declined,
          by: SessionActor.mentor,
        ),
        isTrue,
      );
    });

    test('mentor completes or cancels a confirmed session', () {
      for (final to in [
        MentorSessionStatus.completed,
        MentorSessionStatus.cancelled,
      ]) {
        expect(
          MentorSessionStatus.canTransition(
            from: c,
            to: to,
            by: SessionActor.mentor,
          ),
          isTrue,
          reason: to,
        );
      }
    });

    test('youth can only cancel pending or confirmed sessions', () {
      expect(
        MentorSessionStatus.canTransition(
          from: s,
          to: MentorSessionStatus.cancelled,
          by: SessionActor.youth,
        ),
        isTrue,
      );
      expect(
        MentorSessionStatus.canTransition(
          from: c,
          to: MentorSessionStatus.cancelled,
          by: SessionActor.youth,
        ),
        isTrue,
      );
      expect(
        MentorSessionStatus.canTransition(
          from: s,
          to: c,
          by: SessionActor.youth,
        ),
        isFalse,
        reason: 'a youth cannot confirm their own request',
      );
    });

    test('finished sessions cannot change', () {
      for (final from in [
        MentorSessionStatus.declined,
        MentorSessionStatus.cancelled,
        MentorSessionStatus.completed,
      ]) {
        for (final to in MentorSessionStatus.all) {
          for (final by in SessionActor.values) {
            expect(
              MentorSessionStatus.canTransition(from: from, to: to, by: by),
              isFalse,
              reason: '$by: $from -> $to',
            );
          }
        }
      }
    });
  });

  test('maps stored statuses to screen states and hides cancelled', () {
    expect(MentorSessionStatus.toState('requested'), SessionState.requested);
    expect(MentorSessionStatus.toState('confirmed'), SessionState.upcoming);
    expect(MentorSessionStatus.toState('completed'), SessionState.done);
    expect(MentorSessionStatus.toState('declined'), SessionState.declined);
    expect(MentorSessionStatus.toState('cancelled'), isNull);
    expect(MentorSessionStatus.toState('something-else'), isNull);
    expect(MentorSessionStatus.toState(null), isNull);
  });

  group('SessionRequest.validate', () {
    final now = DateTime.utc(2026, 10, 18, 12);

    SessionRequest request({
      String requesterId = 'youth-1',
      String mentorId = 'mentor-1',
      String topic = 'Feedback on a project',
      String note = '',
      DateTime? startsAt,
    }) => SessionRequest(
      requesterId: requesterId,
      requesterName: 'Jean Niyonzima',
      mentorId: mentorId,
      mentorName: 'Alice Uwimana',
      startsAt: startsAt ?? DateTime.utc(2026, 10, 22, 16),
      topic: topic,
      note: note,
    );

    test('accepts a complete future request', () {
      expect(request().validate(now: now), isNull);
    });

    test('rejects missing identity, topic and self-booking', () {
      expect(request(requesterId: '').validate(now: now), isNotNull);
      expect(request(mentorId: ' ').validate(now: now), isNotNull);
      expect(request(mentorId: 'youth-1').validate(now: now), isNotNull);
      expect(request(topic: '   ').validate(now: now), isNotNull);
    });

    test('rejects oversized text and past times', () {
      expect(request(topic: 'x' * 81).validate(now: now), isNotNull);
      expect(request(note: 'x' * 501).validate(now: now), isNotNull);
      expect(request(startsAt: now).validate(now: now), isNotNull);
    });
  });
}
