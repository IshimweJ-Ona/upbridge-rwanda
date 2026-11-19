import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';

Mentor mentor(
  String id,
  String name, {
  String area = 'Web development',
  List<SessionSlot> slots = const [],
  bool accepting = true,
}) => Mentor(
  slots: slots,
  accepting: accepting,
  id: id,
  name: name,
  title: 'Engineer',
  employer: '',
  years: 3,
  city: id == 'grace' ? 'Huye' : 'Kigali',
  bio: '',
  skills: id == 'alice' ? const ['React'] : const ['CVs'],
  helpsWith: const [],
  reviews: 0,
  replyTime: 'New',
  mentees: 0,
  availability: '',
  languages: '',
  tone: Tone.info,
  area: area,
);

Session session(String mentorId, SessionState state) => Session(
  id: '$mentorId-$state',
  mentorId: mentorId,
  mentorName: mentorId,
  youthId: 'youth-1',
  youthName: 'Jean',
  day: 'THU 22 OCT',
  time: '18:00',
  topic: 'Career advice',
  state: state,
);

void main() {
  final mentors = [
    mentor('alice', 'Alice Uwimana'),
    mentor('grace', 'Grace Mukamana', area: 'Career skills'),
  ];

  test('filters by area and by name, skill or city', () {
    const all = MentorFilter();
    expect(all.apply(mentors), hasLength(2));
    expect(all.isActive, isFalse);

    final career = const MentorFilter(area: 'Career skills').apply(mentors);
    expect(career.single.id, 'grace');

    expect(
      const MentorFilter(query: 'react').apply(mentors).single.id,
      'alice',
    );
    expect(const MentorFilter(query: 'HUYE').apply(mentors).single.id, 'grace');
    expect(const MentorFilter(query: 'nobody').apply(mentors), isEmpty);
  });

  test('area chips come from the mentors themselves', () {
    expect(MentorFilter.areasOf(mentors), [
      'All',
      'Career skills',
      'Web development',
    ]);
    expect(MentorFilter.areasOf(const []), ['All']);
  });

  test('your mentor is from an upcoming session, then a finished one', () {
    expect(yourMentorId(const []), isNull);
    expect(yourMentorId([session('grace', SessionState.requested)]), isNull);
    expect(
      yourMentorId([
        session('grace', SessionState.done),
        session('alice', SessionState.upcoming),
      ]),
      'alice',
    );
    expect(yourMentorId([session('grace', SessionState.done)]), 'grace');
  });
}
