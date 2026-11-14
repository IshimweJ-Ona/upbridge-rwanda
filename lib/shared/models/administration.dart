part of 'models.dart';

// ───────────────────────────── Admin ─────────────────────────────

class PlatformUser {
  const PlatformUser({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.district,
    required this.joined,
    this.status = 'Active',
    this.detail = '',
  });

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
  const Objective({
    required this.label,
    required this.value,
    required this.target,
    required this.valueLabel,
    required this.targetLabel,
    required this.note,
    this.closed = false,
  });

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
