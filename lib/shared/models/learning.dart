part of 'models.dart';

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
  const Resource({
    required this.title,
    required this.source,
    required this.url,
    required this.kind,
  });
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

  LearningTask copyWith({TaskStatus? status, String? statusNote}) =>
      LearningTask(
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
  const OtherPath({
    required this.title,
    required this.progress,
    required this.note,
    required this.icon,
  });
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
