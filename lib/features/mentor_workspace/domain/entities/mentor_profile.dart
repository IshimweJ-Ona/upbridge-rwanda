// Owner: Student 3 · Mentorship & mentor workspace
// Holds: The mentor's own profile: title, employer, bio, skills, languages, meeting link, accepting flag, mentee limit.
import 'package:upbridge/features/mentor_workspace/domain/entities/availability_window.dart';

class MentorProfile {
  const MentorProfile({
    required this.id,
    required this.name,
    this.title = '',
    this.employer = '',
    this.bio = '',
    this.skills = const [],
    this.languages = const [],
    this.meetingLink = '',
    this.accepting = false,
    this.menteeLimit = defaultMenteeLimit,
    this.windows = const [],
    this.verified = false,
    this.reviewsCount = 0,
    this.menteeCount = 0,
    this.replyTime = 'New',
  });

  static const defaultMenteeLimit = 5;
  static const maxMenteeLimit = 10;
  static const maxTitleLength = 80;
  static const maxBioLength = 600;
  static const maxSkills = 10;

  /// Doc ID in mentorProfiles = the mentor's Auth UID.
  final String id;
  final String name;
  final String title;
  final String employer;
  final String bio;
  final List<String> skills;
  final List<String> languages;
  final String meetingLink;
  final bool accepting;
  final int menteeLimit;
  final List<AvailabilityWindow> windows;

  // Read-only: set by admins or computed elsewhere.
  final bool verified;
  final int reviewsCount;
  final int menteeCount;
  final String replyTime;

  bool get hasAvailability => windows.isNotEmpty;

  /// Shown to youth in the directory, e.g. "Tuesday · 18:00–20:00, Thursday · …".
  String get availabilityLabel => windows.isEmpty
      ? 'Availability not set yet'
      : (sortedWindows.map((w) => w.label).join(', '));

  List<AvailabilityWindow> get sortedWindows => [...windows]
    ..sort(
      (a, b) => a.weekday != b.weekday
          ? a.weekday.compareTo(b.weekday)
          : a.startMinutes.compareTo(b.startMinutes),
    );

  /// First problem found, or null when the profile can be saved.
  String? validate() {
    if (title.trim().length > maxTitleLength) {
      return 'Keep your title under $maxTitleLength characters.';
    }
    if (bio.trim().length > maxBioLength) {
      return 'Keep your bio under $maxBioLength characters.';
    }
    if (skills.length > maxSkills) return 'Choose up to $maxSkills skills.';
    final link = meetingLink.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        return 'Use a full meeting link starting with https://';
      }
    }
    if (menteeLimit < 1 || menteeLimit > maxMenteeLimit) {
      return 'Take between 1 and $maxMenteeLimit mentees.';
    }
    for (final w in windows) {
      final problem = w.validate();
      if (problem != null) return problem;
    }
    for (var i = 0; i < windows.length; i++) {
      for (var j = i + 1; j < windows.length; j++) {
        if (windows[i].overlaps(windows[j])) {
          return '${windows[i].label} overlaps ${windows[j].label}.';
        }
      }
    }
    if (accepting && windows.isEmpty) {
      return 'Add at least one time before accepting new mentees.';
    }
    return null;
  }

  MentorProfile copyWith({
    String? meetingLink,
    bool? accepting,
    int? menteeLimit,
    List<AvailabilityWindow>? windows,
  }) => MentorProfile(
    id: id,
    name: name,
    title: title,
    employer: employer,
    bio: bio,
    skills: skills,
    languages: languages,
    meetingLink: meetingLink ?? this.meetingLink,
    accepting: accepting ?? this.accepting,
    menteeLimit: menteeLimit ?? this.menteeLimit,
    windows: windows ?? this.windows,
    verified: verified,
    reviewsCount: reviewsCount,
    menteeCount: menteeCount,
    replyTime: replyTime,
  );
}
