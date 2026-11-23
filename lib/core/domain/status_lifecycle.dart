/// Canonical roles, document status enums, and allowed status transition rules.
library;

enum UserRole {
  student('student'),
  mentor('mentor'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  /// Parses an explicit role value without silently defaulting invalid values.
  static UserRole? tryFromValue(Object? raw) => switch (raw) {
    'student' || 'youth' => UserRole.student,
    'mentor' => UserRole.mentor,
    'admin' => UserRole.admin,
    _ => null,
  };

  static UserRole fromValue(Object? raw) => tryFromValue(raw) ?? UserRole.student;

  String get displayLabel => switch (this) {
    UserRole.student => 'Student',
    UserRole.mentor => 'Mentor',
    UserRole.admin => 'Admin',
  };
}

enum ApprovalStatus {
  notRequired('notRequired'),
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  revoked('revoked');

  const ApprovalStatus(this.value);
  final String value;

  static ApprovalStatus? tryFromValue(Object? raw) => switch (raw) {
    'notRequired' || 'none' || 'na' => ApprovalStatus.notRequired,
    'pending' => ApprovalStatus.pending,
    'approved' => ApprovalStatus.approved,
    'rejected' => ApprovalStatus.rejected,
    'revoked' => ApprovalStatus.revoked,
    _ => null,
  };

  String get label => switch (this) {
    ApprovalStatus.notRequired => 'Not required',
    ApprovalStatus.pending => 'Pending',
    ApprovalStatus.approved => 'Approved',
    ApprovalStatus.rejected => 'Rejected',
    ApprovalStatus.revoked => 'Revoked',
  };
}

enum AccountStatus {
  active('active'),
  deactivated('deactivated');

  const AccountStatus(this.value);
  final String value;

  static AccountStatus fromValue(Object? raw) => switch (raw) {
    'deactivated' => AccountStatus.deactivated,
    _ => AccountStatus.active,
  };
}

enum ProfileStatus {
  active('active'),
  archived('archived');

  const ProfileStatus(this.value);
  final String value;

  static ProfileStatus fromValue(Object? raw) => switch (raw) {
    'archived' => ProfileStatus.archived,
    _ => ProfileStatus.active,
  };
}

enum ProjectStatus {
  draft('draft'),
  published('published'),
  archived('archived');

  const ProjectStatus(this.value);
  final String value;

  static ProjectStatus fromValue(Object? raw) => switch (raw) {
    'draft' => ProjectStatus.draft,
    'archived' => ProjectStatus.archived,
    _ => ProjectStatus.published,
  };
}

enum MentorApplicationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  revoked('revoked');

  const MentorApplicationStatus(this.value);
  final String value;

  static MentorApplicationStatus fromValue(Object? raw) => switch (raw) {
    'approved' => MentorApplicationStatus.approved,
    'rejected' => MentorApplicationStatus.rejected,
    'revoked' => MentorApplicationStatus.revoked,
    _ => MentorApplicationStatus.pending,
  };
}

enum MentorRequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled');

  const MentorRequestStatus(this.value);
  final String value;

  static MentorRequestStatus fromValue(Object? raw) => switch (raw) {
    'accepted' => MentorRequestStatus.accepted,
    'declined' => MentorRequestStatus.declined,
    'cancelled' => MentorRequestStatus.cancelled,
    _ => MentorRequestStatus.pending,
  };
}

enum MentorshipStatus {
  active('active'),
  completed('completed'),
  ended('ended');

  const MentorshipStatus(this.value);
  final String value;

  static MentorshipStatus fromValue(Object? raw) => switch (raw) {
    'completed' => MentorshipStatus.completed,
    'ended' => MentorshipStatus.ended,
    _ => MentorshipStatus.active,
  };
}

enum SessionStatus {
  scheduled('scheduled'),
  completed('completed'),
  cancelled('cancelled');

  const SessionStatus(this.value);
  final String value;

  static SessionStatus fromValue(Object? raw) => switch (raw) {
    'completed' => SessionStatus.completed,
    'cancelled' => SessionStatus.cancelled,
    _ => SessionStatus.scheduled,
  };
}

enum CourseStatus {
  draft('draft'),
  published('published'),
  archived('archived');

  const CourseStatus(this.value);
  final String value;

  static CourseStatus fromValue(Object? raw) => switch (raw) {
    'published' => CourseStatus.published,
    'archived' => CourseStatus.archived,
    _ => CourseStatus.draft,
  };
}

enum CourseProgressStatus {
  notStarted('notStarted'),
  inProgress('inProgress'),
  completed('completed');

  const CourseProgressStatus(this.value);
  final String value;

  static CourseProgressStatus fromValue(Object? raw) => switch (raw) {
    'inProgress' => CourseProgressStatus.inProgress,
    'completed' => CourseProgressStatus.completed,
    _ => CourseProgressStatus.notStarted,
  };
}

enum OpportunityStatus {
  draft('draft'),
  published('published'),
  closed('closed'),
  archived('archived');

  const OpportunityStatus(this.value);
  final String value;

  static OpportunityStatus fromValue(Object? raw) => switch (raw) {
    'published' => OpportunityStatus.published,
    'closed' => OpportunityStatus.closed,
    'archived' => OpportunityStatus.archived,
    _ => OpportunityStatus.draft,
  };
}

enum OpportunityApplicationStatus {
  submitted('submitted'),
  underReview('underReview'),
  accepted('accepted'),
  rejected('rejected'),
  withdrawn('withdrawn');

  const OpportunityApplicationStatus(this.value);
  final String value;

  static OpportunityApplicationStatus fromValue(Object? raw) => switch (raw) {
    'underReview' => OpportunityApplicationStatus.underReview,
    'accepted' => OpportunityApplicationStatus.accepted,
    'rejected' => OpportunityApplicationStatus.rejected,
    'withdrawn' => OpportunityApplicationStatus.withdrawn,
    _ => OpportunityApplicationStatus.submitted,
  };
}

enum NotificationStatus {
  unread('unread'),
  read('read');

  const NotificationStatus(this.value);
  final String value;

  static NotificationStatus fromValue(Object? raw) => switch (raw) {
    'read' => NotificationStatus.read,
    _ => NotificationStatus.unread,
  };
}

enum AuditLogStatus {
  recorded('recorded');

  const AuditLogStatus(this.value);
  final String value;

  static AuditLogStatus fromValue(Object? raw) => AuditLogStatus.recorded;
}

/// Centralized state-transition guardrails shared by domain/repository layers and mirrored in firestore.rules.
abstract final class StatusTransitions {
  static const Map<MentorApplicationStatus, Set<MentorApplicationStatus>>
  mentorApplication = {
    MentorApplicationStatus.pending: {
      MentorApplicationStatus.pending,
      MentorApplicationStatus.approved,
      MentorApplicationStatus.rejected,
    },
    MentorApplicationStatus.approved: {MentorApplicationStatus.revoked},
    MentorApplicationStatus.rejected: {MentorApplicationStatus.pending},
    MentorApplicationStatus.revoked: {MentorApplicationStatus.pending},
  };

  static const Map<MentorRequestStatus, Set<MentorRequestStatus>>
  mentorRequest = {
    MentorRequestStatus.pending: {
      MentorRequestStatus.accepted,
      MentorRequestStatus.declined,
      MentorRequestStatus.cancelled,
    },
    MentorRequestStatus.accepted: <MentorRequestStatus>{},
    MentorRequestStatus.declined: <MentorRequestStatus>{},
    MentorRequestStatus.cancelled: <MentorRequestStatus>{},
  };

  static const Map<MentorshipStatus, Set<MentorshipStatus>> mentorship = {
    MentorshipStatus.active: {
      MentorshipStatus.completed,
      MentorshipStatus.ended,
    },
    MentorshipStatus.completed: <MentorshipStatus>{},
    MentorshipStatus.ended: <MentorshipStatus>{},
  };

  static const Map<SessionStatus, Set<SessionStatus>> session = {
    SessionStatus.scheduled: {SessionStatus.completed, SessionStatus.cancelled},
    SessionStatus.completed: <SessionStatus>{},
    SessionStatus.cancelled: <SessionStatus>{},
  };

  static const Map<CourseStatus, Set<CourseStatus>> course = {
    CourseStatus.draft: {CourseStatus.published, CourseStatus.archived},
    CourseStatus.published: {CourseStatus.draft, CourseStatus.archived},
    CourseStatus.archived: {CourseStatus.draft},
  };

  static const Map<CourseProgressStatus, Set<CourseProgressStatus>>
  courseProgress = {
    CourseProgressStatus.notStarted: {
      CourseProgressStatus.inProgress,
      CourseProgressStatus.completed,
    },
    CourseProgressStatus.inProgress: {CourseProgressStatus.completed},
    CourseProgressStatus.completed: <CourseProgressStatus>{},
  };

  static const Map<OpportunityStatus, Set<OpportunityStatus>> opportunity = {
    OpportunityStatus.draft: {
      OpportunityStatus.published,
      OpportunityStatus.archived,
    },
    OpportunityStatus.published: {
      OpportunityStatus.closed,
      OpportunityStatus.archived,
    },
    OpportunityStatus.closed: {
      OpportunityStatus.published,
      OpportunityStatus.archived,
    },
    OpportunityStatus.archived: {OpportunityStatus.draft},
  };

  static const Map<
    OpportunityApplicationStatus,
    Set<OpportunityApplicationStatus>
  >
  opportunityApplication = {
    OpportunityApplicationStatus.submitted: {
      OpportunityApplicationStatus.underReview,
      OpportunityApplicationStatus.withdrawn,
    },
    OpportunityApplicationStatus.underReview: {
      OpportunityApplicationStatus.accepted,
      OpportunityApplicationStatus.rejected,
      OpportunityApplicationStatus.withdrawn,
    },
    OpportunityApplicationStatus.accepted: <OpportunityApplicationStatus>{},
    OpportunityApplicationStatus.rejected: <OpportunityApplicationStatus>{},
    OpportunityApplicationStatus.withdrawn: {
      OpportunityApplicationStatus.submitted,
    },
  };

  static const Map<ProjectStatus, Set<ProjectStatus>> project = {
    ProjectStatus.draft: {ProjectStatus.published, ProjectStatus.archived},
    ProjectStatus.published: {ProjectStatus.draft, ProjectStatus.archived},
    ProjectStatus.archived: {ProjectStatus.draft, ProjectStatus.published},
  };

  static const Map<AccountStatus, Set<AccountStatus>> account = {
    AccountStatus.active: {AccountStatus.deactivated},
    AccountStatus.deactivated: {AccountStatus.active},
  };

  static bool canTransition<T extends Enum>(
    Map<T, Set<T>> table,
    T from,
    T to,
  ) {
    if (from == to) return false;
    return table[from]?.contains(to) ?? false;
  }

  static void requireTransition<T extends Enum>(
    Map<T, Set<T>> table,
    T from,
    T to, {
    String? entity,
  }) {
    if (!canTransition(table, from, to)) {
      final label = entity ?? T.toString();
      throw StateError(
        'Invalid $label status transition from ${from.name} to ${to.name}.',
      );
    }
  }
}

extension UserRoleLabelX on UserRole {
  String get label => displayLabel;
}

extension AccountStatusLabelX on AccountStatus {
  String get label => switch (this) {
    AccountStatus.active => 'Active',
    AccountStatus.deactivated => 'Deactivated',
  };
}

extension MentorApplicationStatusLabelX on MentorApplicationStatus {
  String get label => switch (this) {
    MentorApplicationStatus.pending => 'Pending',
    MentorApplicationStatus.approved => 'Approved',
    MentorApplicationStatus.rejected => 'Rejected',
    MentorApplicationStatus.revoked => 'Revoked',
  };
}

extension MentorRequestStatusLabelX on MentorRequestStatus {
  String get label => switch (this) {
    MentorRequestStatus.pending => 'Pending',
    MentorRequestStatus.accepted => 'Accepted',
    MentorRequestStatus.declined => 'Declined',
    MentorRequestStatus.cancelled => 'Cancelled',
  };
}

extension MentorshipStatusLabelX on MentorshipStatus {
  String get label => switch (this) {
    MentorshipStatus.active => 'Active',
    MentorshipStatus.completed => 'Completed',
    MentorshipStatus.ended => 'Ended',
  };
}

extension SessionStatusLabelX on SessionStatus {
  String get label => switch (this) {
    SessionStatus.scheduled => 'Scheduled',
    SessionStatus.completed => 'Completed',
    SessionStatus.cancelled => 'Cancelled',
  };
}

extension CourseStatusLabelX on CourseStatus {
  String get label => switch (this) {
    CourseStatus.draft => 'Draft',
    CourseStatus.published => 'Published',
    CourseStatus.archived => 'Archived',
  };
}

extension OpportunityStatusLabelX on OpportunityStatus {
  String get label => switch (this) {
    OpportunityStatus.draft => 'Draft',
    OpportunityStatus.published => 'Published',
    OpportunityStatus.closed => 'Closed',
    OpportunityStatus.archived => 'Archived',
  };
}

extension OpportunityApplicationStatusLabelX on OpportunityApplicationStatus {
  String get label => switch (this) {
    OpportunityApplicationStatus.submitted => 'Submitted',
    OpportunityApplicationStatus.underReview => 'Under review',
    OpportunityApplicationStatus.accepted => 'Accepted',
    OpportunityApplicationStatus.rejected => 'Rejected',
    OpportunityApplicationStatus.withdrawn => 'Withdrawn',
  };
}
