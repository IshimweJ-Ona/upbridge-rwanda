// Firestore collection names and statuses shared with firestore.rules and docs/firestore-schema.md.

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

/// Submission statuses currently written by the shared repository.
abstract final class SubmissionStatus {
  static const submitted = 'submitted';
  static const changesRequested = 'changesRequested';
  static const approved = 'approved';
}

/// Opportunity status values.
abstract final class OpportunityStatus {
  static const published = 'published';
}
