// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';

enum Role { youth, mentor, admin }

extension RoleX on Role {
  String get label => switch (this) {
        Role.youth => 'Youth',
        Role.mentor => 'Mentor',
        Role.admin => 'Admin',
      };

  String get home => switch (this) {
        Role.youth => '/home',
        Role.mentor => '/m/home',
        Role.admin => '/a/overview',
      };
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.headline = '',
    this.location = 'Kigali',
    this.about = '',
    this.onboarded = true,
    this.isNewMentor = false,
  });

  final String id;
  final String name;
  final String phone;
  final Role role;
  final String headline;
  final String location;
  final String about;
  final bool onboarded;
  final bool isNewMentor;

  String get firstName => name.split(' ').first;
  String get initials => initialsOf(name);

  AppUser copyWith({String? name, String? headline, String? location, String? about, bool? onboarded}) => AppUser(
        id: id,
        name: name ?? this.name,
        phone: phone,
        role: role,
        headline: headline ?? this.headline,
        location: location ?? this.location,
        about: about ?? this.about,
        onboarded: onboarded ?? this.onboarded,
        isNewMentor: isNewMentor,
      );
}

class Account {
  const Account({required this.phone, required this.user});
  final String phone;
  final AppUser user;
}

// ───────────────────────────── Learning ─────────────────────────────

enum TaskStatus { approved, changesRequested, inReview, available, locked }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.approved => 'Approved',
        TaskStatus.changesRequested => '1 change requested',
        TaskStatus.inReview => 'In review',
        TaskStatus.available => 'Ready to start',
        TaskStatus.locked => 'Locked',
      };

  Tone get tone => switch (this) {
        TaskStatus.approved => Tone.success,
        TaskStatus.changesRequested => Tone.warning,
        TaskStatus.inReview => Tone.info,
        TaskStatus.available => Tone.accent,
        TaskStatus.locked => Tone.neutral,
      };

  IconData get icon => switch (this) {
        TaskStatus.approved => Icons.check_circle_rounded,
        TaskStatus.changesRequested => Icons.edit_note_rounded,
        TaskStatus.inReview => Icons.hourglass_top_rounded,
        TaskStatus.available => Icons.play_circle_outline_rounded,
        TaskStatus.locked => Icons.lock_outline_rounded,
      };
}

class Criterion {
  const Criterion(this.title, this.detail);
  final String title;
  final String detail;
}

class Resource {
  const Resource({required this.title, required this.source, required this.url, required this.kind});
  final String title;
  final String source;
  final String url;
  final String kind;
}

class LearningTask {
  const LearningTask({
    required this.id,
    required this.number,
    required this.stage,
    required this.title,
    required this.summary,
    required this.duration,
    required this.status,
    this.statusNote,
    this.brief = '',
    this.deliverables = const [],
    this.criteria = const [],
    this.resources = const [],
  });

  final String id;
  final int number;
  final int stage;
  final String title;
  final String summary;
  final String duration;
  final TaskStatus status;
  final String? statusNote;
  final String brief;
  final List<String> deliverables;
  final List<Criterion> criteria;
  final List<Resource> resources;

  LearningTask copyWith({TaskStatus? status, String? statusNote}) => LearningTask(
        id: id,
        number: number,
        stage: stage,
        title: title,
        summary: summary,
        duration: duration,
        status: status ?? this.status,
        statusNote: statusNote ?? this.statusNote,
        brief: brief,
        deliverables: deliverables,
        criteria: criteria,
        resources: resources,
      );
}

class PathStage {
  const PathStage(this.number, this.title, this.taskCount, this.summary);
  final int number;
  final String title;
  final int taskCount;
  final String summary;
}

class OtherPath {
  const OtherPath({required this.title, required this.progress, required this.note, required this.icon});
  final String title;
  final String progress;
  final String note;
  final IconData icon;
}

enum Verdict { met, partly, notYet }

extension VerdictX on Verdict {
  String get label => switch (this) {
        Verdict.met => 'Met',
        Verdict.partly => 'Partly met',
        Verdict.notYet => 'Not yet',
      };

  Tone get tone => switch (this) {
        Verdict.met => Tone.success,
        Verdict.partly => Tone.warning,
        Verdict.notYet => Tone.danger,
      };

  IconData get icon => switch (this) {
        Verdict.met => Icons.check_circle_rounded,
        Verdict.partly => Icons.change_circle_outlined,
        Verdict.notYet => Icons.cancel_outlined,
      };
}

class CriterionResult {
  const CriterionResult(this.criterion, this.verdict, this.note);
  final String criterion;
  final Verdict verdict;
  final String note;
}

class Review {
  const Review({
    required this.id,
    required this.taskId,
    required this.mentorName,
    required this.when,
    required this.approved,
    required this.summary,
    required this.results,
  });

  final String id;
  final String taskId;
  final String mentorName;
  final String when;
  final bool approved;
  final String summary;
  final List<CriterionResult> results;

  int get metCount => results.where((r) => r.verdict == Verdict.met).length;
}

/// A piece of work waiting in a mentor's queue.
class Submission {
  const Submission({
    required this.id,
    required this.youthId,
    required this.youthName,
    required this.taskId,
    required this.taskNumber,
    required this.taskTitle,
    required this.path,
    required this.attempt,
    required this.submittedAt,
    required this.dueLabel,
    required this.liveUrl,
    required this.repoUrl,
    required this.reflection,
    this.urgent = false,
    this.previousNote,
    this.reviewed = false,
  });

  final String id;
  final String youthId;
  final String youthName;
  final String taskId;
  final int taskNumber;
  final String taskTitle;
  final String path;
  final int attempt;
  final String submittedAt;
  final String dueLabel;
  final String liveUrl;
  final String repoUrl;
  final String reflection;
  final bool urgent;
  final String? previousNote;
  final bool reviewed;

  bool get isRecheck => attempt > 1;
  String get youthInitials => initialsOf(youthName);

  Submission copyWith({bool? reviewed}) => Submission(
        id: id,
        youthId: youthId,
        youthName: youthName,
        taskId: taskId,
        taskNumber: taskNumber,
        taskTitle: taskTitle,
        path: path,
        attempt: attempt,
        submittedAt: submittedAt,
        dueLabel: dueLabel,
        liveUrl: liveUrl,
        repoUrl: repoUrl,
        reflection: reflection,
        urgent: urgent,
        previousNote: previousNote,
        reviewed: reviewed ?? this.reviewed,
      );
}

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

  String get orgInitials => initialsOf(org.replaceAll(RegExp(r'[^A-Za-z ]'), ' '));
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

enum AppStatus { sent, underReview, forwarded, shortlisted, notSelected, withdrawn }

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

  bool get isActive => this != AppStatus.notSelected && this != AppStatus.withdrawn;
}

class TimelineEvent {
  const TimelineEvent(this.title, this.date, {this.detail, this.done = true, this.current = false});
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

  Application copyWith({AppStatus? status, List<TimelineEvent>? timeline, String? statusNote}) => Application(
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

// ───────────────────────────── Portfolio ─────────────────────────────

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.summary,
    required this.skills,
    required this.addedOn,
    this.taskId,
    this.liveUrl = '',
    this.repoUrl = '',
    this.approvedBy,
    this.approvedOn,
    this.criteria = '',
    this.whatIDid = const [],
    this.mentorQuote,
    this.icon = Icons.web_rounded,
    this.tone = Tone.info,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> skills;
  final String addedOn;
  final String? taskId;
  final String liveUrl;
  final String repoUrl;
  final String? approvedBy;
  final String? approvedOn;
  final String criteria;
  final List<String> whatIDid;
  final String? mentorQuote;
  final IconData icon;
  final Tone tone;

  bool get verified => approvedBy != null;
}

// ───────────────────────────── Notifications ─────────────────────────────

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.tone,
    this.route,
    this.unread = false,
    this.today = true,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Tone tone;
  final String? route;
  final bool unread;
  final bool today;

  AppNotification read() => AppNotification(id: id, title: title, body: body, time: time, icon: icon, tone: tone, route: route, today: today);
}

// ───────────────────────────── Admin ─────────────────────────────

class PlatformUser {
  const PlatformUser({required this.id, required this.name, required this.role, required this.phone, required this.district, required this.joined, this.status = 'Active', this.detail = ''});

  final String id;
  final String name;
  final Role role;
  final String phone;
  final String district;
  final String joined;
  final String status;
  final String detail;

  String get initials => initialsOf(name);
}

class Check {
  const Check(this.label, this.passed, this.detail);
  final String label;
  final bool passed;
  final String detail;
}

enum ApplicantState { pending, approved, declined }

class MentorApplicant {
  const MentorApplicant({
    required this.id,
    required this.name,
    required this.title,
    required this.employer,
    required this.city,
    required this.years,
    required this.appliedOn,
    required this.skills,
    required this.motivation,
    required this.checks,
    required this.availability,
    required this.phone,
    this.state = ApplicantState.pending,
  });

  final String id;
  final String name;
  final String title;
  final String employer;
  final String city;
  final int years;
  final String appliedOn;
  final List<String> skills;
  final String motivation;
  final List<Check> checks;
  final String availability;
  final String phone;
  final ApplicantState state;

  String get initials => initialsOf(name);
  int get passed => checks.where((c) => c.passed).length;

  MentorApplicant copyWith({ApplicantState? state}) => MentorApplicant(
        id: id,
        name: name,
        title: title,
        employer: employer,
        city: city,
        years: years,
        appliedOn: appliedOn,
        skills: skills,
        motivation: motivation,
        checks: checks,
        availability: availability,
        phone: phone,
        state: state ?? this.state,
      );
}

class Objective {
  const Objective({required this.label, required this.value, required this.target, required this.valueLabel, required this.targetLabel, required this.note, this.closed = false});

  final String label;
  final double value;
  final double target;
  final String valueLabel;
  final String targetLabel;
  final String note;
  final bool closed;

  bool get onTrack => value >= target * 0.8;
}

/// An application an admin checks before forwarding it to the employer.
class ForwardItem {
  const ForwardItem({
    required this.id,
    required this.youthName,
    required this.oppId,
    required this.sentOn,
    required this.evidence,
    required this.checks,
    this.applicationId,
    this.forwarded = false,
  });

  final String id;
  final String youthName;
  final String oppId;
  final String sentOn;
  final String evidence;
  final List<Check> checks;
  final String? applicationId;
  final bool forwarded;

  String get initials => initialsOf(youthName);

  ForwardItem copyWith({bool? forwarded}) => ForwardItem(
        id: id,
        youthName: youthName,
        oppId: oppId,
        sentOn: sentOn,
        evidence: evidence,
        checks: checks,
        applicationId: applicationId,
        forwarded: forwarded ?? this.forwarded,
      );
}
