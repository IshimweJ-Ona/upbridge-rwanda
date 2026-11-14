part of 'models.dart';

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
