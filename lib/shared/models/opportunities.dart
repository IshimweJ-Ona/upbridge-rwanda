part of 'models.dart';

// ───────────────────────────── Opportunities ─────────────────────────────

enum ReqState { met, partial, unknown }

class Requirement {
  const Requirement(this.text, this.state, this.evidence);
  final String text;
  final ReqState state;
  final String evidence;
}

enum ListingState { open, draft, reported, removed, closed }

class Opportunity {
  const Opportunity({
    required this.id,
    required this.title,
    required this.org,
    required this.orgTone,
    required this.kind,
    required this.length,
    required this.pay,
    required this.place,
    required this.closes,
    required this.closesNote,
    required this.repliesBy,
    required this.starts,
    required this.about,
    required this.aboutOrg,
    required this.tasks,
    required this.requirements,
    required this.category,
    this.posted = 'Posted 12 Oct',
    this.applicants = 0,
    this.state = ListingState.open,
    this.reports = 0,
    this.reportReason = '',
    this.postedBy = '',
    this.matched = false,
  });

  final String id;
  final String title;
  final String org;
  final Tone orgTone;
  final String kind;
  final String length;
  final String pay;
  final String place;
  final String closes;
  final String closesNote;
  final String repliesBy;
  final String starts;
  final String about;
  final String aboutOrg;
  final List<String> tasks;
  final List<Requirement> requirements;
  final String category;
  final String posted;
  final int applicants;
  final ListingState state;
  final int reports;
  final String reportReason;
  final String postedBy;
  final bool matched;

  String get orgInitials =>
      initialsOf(org.replaceAll(RegExp(r'[^A-Za-z ]'), ' '));
  int get metCount => requirements.where((r) => r.state == ReqState.met).length;
  String get meta => [kind, if (length.isNotEmpty) length, pay].join(' · ');

  Opportunity copyWith({ListingState? state, int? applicants}) => Opportunity(
    id: id,
    title: title,
    org: org,
    orgTone: orgTone,
    kind: kind,
    length: length,
    pay: pay,
    place: place,
    closes: closes,
    closesNote: closesNote,
    repliesBy: repliesBy,
    starts: starts,
    about: about,
    aboutOrg: aboutOrg,
    tasks: tasks,
    requirements: requirements,
    category: category,
    posted: posted,
    applicants: applicants ?? this.applicants,
    state: state ?? this.state,
    reports: reports,
    reportReason: reportReason,
    postedBy: postedBy,
    matched: matched,
  );
}

enum AppStatus {
  sent,
  underReview,
  forwarded,
  shortlisted,
  notSelected,
  withdrawn,
}

extension AppStatusX on AppStatus {
  String get label => switch (this) {
    AppStatus.sent => 'Sent',
    AppStatus.underReview => 'Under review',
    AppStatus.forwarded => 'Forwarded to employer',
    AppStatus.shortlisted => 'Shortlisted',
    AppStatus.notSelected => 'Not selected',
    AppStatus.withdrawn => 'Withdrawn',
  };

  Tone get tone => switch (this) {
    AppStatus.sent => Tone.info,
    AppStatus.underReview => Tone.info,
    AppStatus.forwarded => Tone.info,
    AppStatus.shortlisted => Tone.success,
    AppStatus.notSelected => Tone.neutral,
    AppStatus.withdrawn => Tone.neutral,
  };

  bool get isActive =>
      this != AppStatus.notSelected && this != AppStatus.withdrawn;
}

class TimelineEvent {
  const TimelineEvent(
    this.title,
    this.date, {
    this.detail,
    this.done = true,
    this.current = false,
  });
  final String title;
  final String date;
  final String? detail;
  final bool done;
  final bool current;
}

class Application {
  const Application({
    required this.id,
    required this.ref,
    required this.oppId,
    required this.youthId,
    required this.youthName,
    required this.status,
    required this.sentOn,
    required this.projectIds,
    required this.note,
    required this.timeline,
    this.statusNote = '',
  });

  final String id;
  final String ref;
  final String oppId;
  final String youthId;
  final String youthName;
  final AppStatus status;
  final String sentOn;
  final List<String> projectIds;
  final String note;
  final List<TimelineEvent> timeline;
  final String statusNote;

  Application copyWith({
    AppStatus? status,
    List<TimelineEvent>? timeline,
    String? statusNote,
  }) => Application(
    id: id,
    ref: ref,
    oppId: oppId,
    youthId: youthId,
    youthName: youthName,
    status: status ?? this.status,
    sentOn: sentOn,
    projectIds: projectIds,
    note: note,
    timeline: timeline ?? this.timeline,
    statusNote: statusNote ?? this.statusNote,
  );
}
