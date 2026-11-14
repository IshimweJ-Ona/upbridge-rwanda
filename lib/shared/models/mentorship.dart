part of 'models.dart';

// ───────────────────────────── Mentorship ─────────────────────────────

class Mentor {
  const Mentor({
    required this.id,
    required this.name,
    required this.title,
    required this.employer,
    required this.years,
    required this.city,
    required this.bio,
    required this.skills,
    required this.helpsWith,
    required this.reviews,
    required this.replyTime,
    required this.mentees,
    required this.availability,
    required this.languages,
    required this.tone,
    this.slots = const [],
    this.accepting = true,
    this.isYours = false,
    this.area = 'Web development',
  });

  final String id;
  final String name;
  final String title;
  final String employer;
  final int years;
  final String city;
  final String bio;
  final List<String> skills;
  final List<String> helpsWith;
  final int reviews;
  final String replyTime;
  final int mentees;
  final String availability;
  final String languages;
  final Tone tone;
  final List<SessionSlot> slots;
  final bool accepting;
  final bool isYours;
  final String area;

  String get initials => initialsOf(name);
}

class SessionSlot {
  const SessionSlot(this.day, this.time);
  final String day;
  final String time;
  String get label => '$day · $time';
}

enum SessionState { requested, upcoming, done, declined }

class Session {
  const Session({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.youthId,
    required this.youthName,
    required this.day,
    required this.time,
    required this.topic,
    required this.state,
    this.mode = 'Google Meet',
    this.note = '',
    this.link = 'https://meet.google.com/',
  });

  final String id;
  final String mentorId;
  final String mentorName;
  final String youthId;
  final String youthName;
  final String day;
  final String time;
  final String topic;
  final SessionState state;
  final String mode;
  final String note;
  final String link;

  Session copyWith({SessionState? state, String? day, String? time}) => Session(
    id: id,
    mentorId: mentorId,
    mentorName: mentorName,
    youthId: youthId,
    youthName: youthName,
    day: day ?? this.day,
    time: time ?? this.time,
    topic: topic,
    state: state ?? this.state,
    mode: mode,
    note: note,
    link: link,
  );
}

class Mentee {
  const Mentee({
    required this.id,
    required this.name,
    required this.path,
    required this.approved,
    required this.total,
    required this.lastActive,
    required this.status,
    required this.tone,
    this.district = 'Kigali',
  });

  final String id;
  final String name;
  final String path;
  final int approved;
  final int total;
  final String lastActive;
  final String status;
  final Tone tone;
  final String district;

  String get initials => initialsOf(name);
  double get progress => total == 0 ? 0 : approved / total;
}
