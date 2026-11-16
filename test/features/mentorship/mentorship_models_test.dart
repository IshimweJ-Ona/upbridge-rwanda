import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/mentorship/data/models/mentor_model.dart';
import 'package:upbridge/features/mentorship/data/models/session_model.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';

void main() {
  group('MentorModel', () {
    test('maps a full profile and shows slots in Kigali time', () {
      final mentor = MentorModel.fromFirestore('alice-uid', {
        'displayName': 'Alice Uwimana',
        'title': 'Frontend engineer',
        'employer': 'Payments company',
        'yearsExperience': 6,
        'city': 'Kigali',
        'skills': ['HTML & CSS', 'React', ''],
        'helpsWith': ['Code reviews'],
        'languages': ['Kinyarwanda', 'English'],
        'reviewsCount': 46,
        'medianReplyHours': 33.6,
        'menteeCount': 12,
        'accepting': true,
        'verified': true,
        'openSlots': [
          Timestamp.fromDate(DateTime.utc(2026, 10, 22, 17)),
          Timestamp.fromDate(DateTime.utc(2026, 10, 22, 16)),
        ],
      });

      expect(mentor.name, 'Alice Uwimana');
      expect(mentor.initials, 'AU');
      expect(mentor.years, 6);
      expect(mentor.skills, ['HTML & CSS', 'React']);
      expect(mentor.languages, 'Kinyarwanda, English');
      expect(mentor.replyTime, '1.4 d');
      expect(mentor.mentees, 12);
      expect(mentor.slots.map((s) => s.label), [
        'THU 22 OCT · 18:00',
        'THU 22 OCT · 19:00',
      ]);
      expect(mentor.slots.first.startsAt, DateTime.utc(2026, 10, 22, 16));
    });

    test('survives a nearly empty profile with safe defaults', () {
      final mentor = MentorModel.fromFirestore('m1', {
        'skills': 'not a list',
        'openSlots': ['not a timestamp'],
      });
      expect(mentor.name, 'UpBridge mentor');
      expect(mentor.skills, isEmpty);
      expect(mentor.slots, isEmpty);
      expect(mentor.replyTime, 'New');
      expect(mentor.accepting, isTrue);
    });

    test('formats reply time', () {
      expect(formatReplyTime(null), 'New');
      expect(formatReplyTime(5.4), '5 h');
      expect(formatReplyTime(48), '2.0 d');
    });
  });

  group('SessionModel', () {
    Map<String, dynamic> stored(String status) => {
      'requesterId': 'youth-1',
      'requesterName': 'Jean Niyonzima',
      'mentorId': 'alice-uid',
      'mentorName': 'Alice Uwimana',
      'topic': 'Feedback on a project',
      'note': 'I fixed the footer.',
      'startsAt': Timestamp.fromDate(DateTime.utc(2026, 10, 22, 16)),
      'status': status,
    };

    test('maps a confirmed session to an upcoming one', () {
      final session = SessionModel.fromFirestore('s1', stored('confirmed'))!;
      expect(session.state, SessionState.upcoming);
      expect(session.day, 'THU 22 OCT');
      expect(session.time, '18:00');
      expect(session.youthId, 'youth-1');
      expect(session.mode, 'Google Meet');
      expect(
        session.link,
        isEmpty,
        reason: 'no link until the mentor adds one',
      );
    });

    test('hides cancelled sessions', () {
      expect(SessionModel.fromFirestore('s1', stored('cancelled')), isNull);
    });

    test('writes only the documented request fields', () {
      final map = SessionModel.toCreateMap(
        SessionRequest(
          requesterId: 'youth-1',
          requesterName: ' Jean ',
          mentorId: 'alice-uid',
          mentorName: 'Alice Uwimana',
          startsAt: DateTime.utc(2026, 10, 22, 16),
          topic: ' Career advice ',
        ),
      );
      expect(map.keys.toSet(), {
        'requesterId',
        'requesterName',
        'mentorId',
        'mentorName',
        'topic',
        'note',
        'startsAt',
        'durationMinutes',
        'mode',
        'status',
        'createdAt',
        'updatedAt',
      });
      expect(map['status'], 'requested');
      expect(map['topic'], 'Career advice');
      expect(map['requesterName'], 'Jean');
    });
  });
}
