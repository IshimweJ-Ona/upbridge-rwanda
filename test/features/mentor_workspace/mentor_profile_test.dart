import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/mentor_workspace/data/repositories/mentor_profile_repository_impl.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/availability_window.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentor_profile.dart';
import 'package:upbridge/features/mentorship/data/models/mentor_model.dart';

const tue18to20 = AvailabilityWindow(weekday: 2, startMinutes: 18 * 60, endMinutes: 20 * 60);
const thu18to20 = AvailabilityWindow(weekday: 4, startMinutes: 18 * 60, endMinutes: 20 * 60);

void main() {
  group('AvailabilityWindow', () {
    test('labels the window in Kigali time', () {
      expect(tue18to20.label, 'Tuesday · 18:00–20:00');
      expect(AvailabilityWindow.formatMinutes(9 * 60 + 5), '09:05');
    });

    test('rejects bad days, reversed or too short times', () {
      expect(tue18to20.validate(), isNull);
      expect(const AvailabilityWindow(weekday: 0, startMinutes: 60, endMinutes: 120).validate(), contains('day'));
      expect(const AvailabilityWindow(weekday: 2, startMinutes: 120, endMinutes: 60).validate(), contains('after the start'));
      expect(const AvailabilityWindow(weekday: 2, startMinutes: 60, endMinutes: 80).validate(), contains('at least 30'));
      expect(const AvailabilityWindow(weekday: 2, startMinutes: 60, endMinutes: 25 * 60).validate(), contains('within one day'));
    });

    test('detects overlaps on the same day only', () {
      const tue19to21 = AvailabilityWindow(weekday: 2, startMinutes: 19 * 60, endMinutes: 21 * 60);
      const tue20to21 = AvailabilityWindow(weekday: 2, startMinutes: 20 * 60, endMinutes: 21 * 60);
      expect(tue18to20.overlaps(tue19to21), isTrue);
      expect(tue18to20.overlaps(tue20to21), isFalse);
      expect(tue18to20.overlaps(thu18to20), isFalse);
    });

    test('turns weekly windows into future 30-minute starts in UTC', () {
      // Monday 19 Oct 2026, 12:00 in Kigali (10:00 UTC).
      final from = DateTime.utc(2026, 10, 19, 10);
      final starts = AvailabilityWindow.upcomingStarts([tue18to20], from: from, days: 7);
      // Tue 20 Oct 18:00, 18:30, 19:00, 19:30 Kigali = 16:00… UTC.
      expect(starts, [
        DateTime.utc(2026, 10, 20, 16),
        DateTime.utc(2026, 10, 20, 16, 30),
        DateTime.utc(2026, 10, 20, 17),
        DateTime.utc(2026, 10, 20, 17, 30),
      ]);
    });

    test('skips starts that already passed today', () {
      // Tuesday 20 Oct 2026, 18:45 Kigali.
      final from = DateTime.utc(2026, 10, 20, 16, 45);
      final starts = AvailabilityWindow.upcomingStarts([tue18to20], from: from, days: 1);
      expect(starts, [DateTime.utc(2026, 10, 20, 17), DateTime.utc(2026, 10, 20, 17, 30)]);
    });
  });

  group('MentorProfile.validate', () {
    const base = MentorProfile(id: 'alice', name: 'Alice', windows: [tue18to20]);

    test('accepts a normal profile', () {
      expect(base.copyWith(accepting: true, meetingLink: 'https://meet.google.com/abc').validate(), isNull);
    });

    test('needs an https meeting link', () {
      expect(base.copyWith(meetingLink: 'meet.google.com/abc').validate(), contains('https://'));
      expect(base.copyWith(meetingLink: 'http://meet.google.com/abc').validate(), contains('https://'));
      expect(base.copyWith(meetingLink: '').validate(), isNull);
    });

    test('cannot accept mentees without availability', () {
      expect(base.copyWith(windows: const [], accepting: true).validate(), contains('Add at least one time'));
      expect(base.copyWith(windows: const [], accepting: false).validate(), isNull);
    });

    test('rejects overlapping windows and bad mentee limits', () {
      const overlap = AvailabilityWindow(weekday: 2, startMinutes: 19 * 60, endMinutes: 21 * 60);
      expect(base.copyWith(windows: [tue18to20, overlap]).validate(), contains('overlaps'));
      expect(base.copyWith(menteeLimit: 0).validate(), contains('between 1 and 10'));
      expect(base.copyWith(menteeLimit: 11).validate(), contains('between 1 and 10'));
    });

    test('lists availability in weekday order', () {
      final p = base.copyWith(windows: [thu18to20, tue18to20]);
      expect(p.availabilityLabel, 'Tuesday · 18:00–20:00, Thursday · 18:00–20:00');
      expect(const MentorProfile(id: 'x', name: 'X').availabilityLabel, 'Availability not set yet');
    });
  });

  group('MentorProfileRepositoryImpl mapping', () {
    test('reads a full profile document', () {
      final p = MentorProfileRepositoryImpl.fromFirestore('alice', {
        MentorFields.displayName: 'Alice Uwimana',
        MentorFields.title: 'Data analyst',
        MentorFields.skills: ['Excel', 'SQL'],
        MentorFields.languages: ['English', 'Kinyarwanda'],
        MentorFields.accepting: true,
        MentorFields.verified: true,
        MentorFields.reviewsCount: 46,
        MentorProfileFields.meetingLink: ' https://meet.google.com/abc ',
        MentorProfileFields.menteeLimit: 4,
        MentorProfileFields.availabilityWindows: [
          {'weekday': 2, 'startMinutes': 1080, 'endMinutes': 1200},
        ],
      });
      expect(p.name, 'Alice Uwimana');
      expect(p.languages, ['English', 'Kinyarwanda']);
      expect(p.meetingLink, 'https://meet.google.com/abc');
      expect(p.menteeLimit, 4);
      expect(p.windows, [tue18to20]);
      expect(p.accepting, isTrue);
      expect(p.verified, isTrue);
      expect(p.reviewsCount, 46);
    });

    test('uses safe defaults for missing or broken fields', () {
      final p = MentorProfileRepositoryImpl.fromFirestore('bob', {
        MentorProfileFields.availabilityWindows: [
          {'weekday': 'Tuesday'},
          'junk',
          {'weekday': 4, 'startMinutes': 1080, 'endMinutes': 1200},
        ],
      });
      expect(p.name, 'UpBridge mentor');
      expect(p.accepting, isFalse);
      expect(p.verified, isFalse);
      expect(p.menteeLimit, MentorProfile.defaultMenteeLimit);
      expect(p.meetingLink, '');
      expect(p.windows, [thu18to20]);
    });

    test('writes only editable fields and rebuilds open slots', () {
      final map = MentorProfileRepositoryImpl.toUpdateMap(
        const MentorProfile(
          id: 'alice',
          name: 'Alice',
          title: 'Should not be written',
          accepting: true,
          windows: [tue18to20],
        ),
        now: DateTime.utc(2026, 10, 19, 10),
      );
      expect(map.keys.toSet(), MentorProfileFields.editable);
      expect(map[MentorFields.availability], 'Tuesday · 18:00–20:00');
      final slots = map[MentorFields.openSlots]! as List;
      expect(slots, hasLength(8)); // 4 per Tuesday, two Tuesdays in 14 days.
      expect((slots.first as Timestamp).toDate().toUtc(), DateTime.utc(2026, 10, 20, 16));
    });

    test('caps open slots at the limit firestore.rules allows', () {
      final everyDay = [
        for (var d = 1; d <= 7; d++)
          AvailabilityWindow(weekday: d, startMinutes: 6 * 60, endMinutes: 22 * 60),
      ];
      final map = MentorProfileRepositoryImpl.toUpdateMap(
        MentorProfile(id: 'a', name: 'A', windows: everyDay),
        now: DateTime.utc(2026, 10, 19, 0),
      );
      expect(map[MentorFields.openSlots]! as List, hasLength(MentorProfileFields.maxOpenSlots));
    });

    test('save rejects an invalid profile before touching Firestore', () async {
      final repo = MentorProfileRepositoryImpl(_NoFirestore());
      await expectLater(
        repo.save(const MentorProfile(id: 'a', name: 'A', accepting: true)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

class _NoFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Firestore must not be called');
}
