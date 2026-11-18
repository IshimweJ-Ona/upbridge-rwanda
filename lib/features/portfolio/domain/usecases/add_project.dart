// Owner: Student 2 · Learning, submissions & portfolio
// Holds: Checks title, summary and at least one skill, then saves. Projects from a task keep their review link.
//
// Saving still goes through the demo AppStore; this file holds the checks so
// the screen and a future Firestore repository apply the same rules.

/// Limits for a self-added portfolio project.
abstract final class ProjectRules {
  static const titleMin = 3;
  static const titleMax = 60;
  static const summaryMin = 20;
  static const summaryMax = 300;
  static const maxSkills = 8;
  static const skillMax = 24;
}

/// What the youth typed into the add-project form.
class ProjectDraft {
  const ProjectDraft({required this.title, required this.summary, required this.skills, this.link = ''});

  final String title;
  final String summary;
  final List<String> skills;
  final String link;
}

/// Field-level problems with a [ProjectDraft]; every field is null when valid.
class ProjectDraftErrors {
  const ProjectDraftErrors({this.title, this.summary, this.skills, this.link});

  final String? title;
  final String? summary;
  final String? skills;
  final String? link;

  bool get isValid => title == null && summary == null && skills == null && link == null;

  int get count => [title, summary, skills, link].where((e) => e != null).length;
}

ProjectDraftErrors validateProjectDraft(ProjectDraft d) {
  final title = d.title.trim();
  final summary = d.summary.trim();
  final link = d.link.trim();

  return ProjectDraftErrors(
    title: title.length < ProjectRules.titleMin ? 'Give your project a name.' : null,
    summary: summary.length < ProjectRules.summaryMin ? 'Describe what you built in a sentence or two.' : null,
    skills: d.skills.isEmpty ? 'Add at least one technology you used.' : null,
    link: link.isEmpty || isHttpsUrl(link) ? null : 'Use a full link that starts with https://',
  );
}

/// True for an absolute https URL with a host, e.g. https://github.com/me/site.
bool isHttpsUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.scheme == 'https' && uri.host.contains('.') && !value.contains(' ');
}

/// Adds [raw] to [skills] once, ignoring case, blank input and anything past the limits.
/// Returns the same list when nothing was added.
List<String> addSkillTag(List<String> skills, String raw) {
  final tag = raw.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(',', '');
  if (tag.isEmpty || tag.length > ProjectRules.skillMax) return skills;
  if (skills.length >= ProjectRules.maxSkills) return skills;
  if (skills.any((s) => s.toLowerCase() == tag.toLowerCase())) return skills;
  return [...skills, tag];
}
