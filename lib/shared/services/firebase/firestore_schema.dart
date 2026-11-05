// Owner: Student 5 · Core, shared, app shell, home & admin
// Holds: collection names and status values. Must match docs/SCHEMA.md and firestore.rules.

/// Collection names (one place only). Keep in sync with firestore.rules.
abstract final class Fs {
  static const users = 'users';
  static const mentorProfiles = 'mentorProfiles';
  static const learningPaths = 'learningPaths';
  static const learningTasks = 'learningTasks';
  static const taskProgress = 'taskProgress';
  static const submissions = 'submissions';
  static const reviews = 'reviews';
  static const projects = 'projects';
  static const mentorshipRequests = 'mentorshipRequests';
  static const mentorSessions = 'mentorSessions';
  static const opportunities = 'opportunities';
  static const applications = 'applications';
  static const notifications = 'notifications';
  static const checkIns = 'checkIns';
  static const auditLogs = 'auditLogs';
  static const appSettings = 'appSettings';
}

/// Submission status values (proposed in docs/SCHEMA.md, confirm at the Friday meeting).
abstract final class SubmissionStatus {
  static const submitted = 'submitted';
  static const changesRequested = 'changesRequested';
  static const approved = 'approved';
}

/// Opportunity status values.
abstract final class OpportunityStatus {
  static const published = 'published';
}
