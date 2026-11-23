import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/features/admin/domain/models/audit_log_entry.dart';
import 'package:upbridge/features/admin/domain/models/platform_metrics.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/notifications/domain/models/user_notification.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';

final userProfileProvider = StreamProvider.family<UserProfile?, String>(
  (ref, uid) => ref.watch(userProfileRepositoryProvider).watchProfile(uid),
);

final userProjectsProvider =
    StreamProvider.family<List<PortfolioProject>, String>(
      (ref, uid) => ref.watch(projectRepositoryProvider).watchUserProjects(uid),
    );

final publicUserProjectsProvider =
    StreamProvider.family<List<PortfolioProject>, String>(
      (ref, uid) =>
          ref.watch(projectRepositoryProvider).watchPublicProjects(uid),
    );

final approvedMentorsProvider = StreamProvider<List<UserProfile>>(
  (ref) => ref.watch(userProfileRepositoryProvider).watchApprovedMentors(),
);

final studentRequestsProvider =
    StreamProvider.family<List<MentorRequest>, String>(
      (ref, studentUid) => ref
          .watch(mentorshipRepositoryProvider)
          .watchStudentRequests(studentUid),
    );

final mentorRequestsProvider =
    StreamProvider.family<List<MentorRequest>, String>(
      (ref, mentorUid) => ref
          .watch(mentorshipRepositoryProvider)
          .watchMentorRequests(mentorUid),
    );

final studentMentorshipsProvider =
    StreamProvider.family<List<Mentorship>, String>(
      (ref, studentUid) => ref
          .watch(mentorshipRepositoryProvider)
          .watchStudentMentorships(studentUid),
    );

final mentorMentorshipsProvider =
    StreamProvider.family<List<Mentorship>, String>(
      (ref, mentorUid) => ref
          .watch(mentorshipRepositoryProvider)
          .watchMentorMentorships(mentorUid),
    );

final studentSessionsProvider =
    StreamProvider.family<List<MentorshipSession>, String>(
      (ref, studentUid) =>
          ref.watch(sessionRepositoryProvider).watchStudentSessions(studentUid),
    );

final mentorSessionsProvider =
    StreamProvider.family<List<MentorshipSession>, String>(
      (ref, mentorUid) =>
          ref.watch(sessionRepositoryProvider).watchMentorSessions(mentorUid),
    );

final mentorshipSessionsProvider =
    StreamProvider.family<List<MentorshipSession>, String>(
      (ref, mentorshipId) => ref
          .watch(sessionRepositoryProvider)
          .watchMentorshipSessions(mentorshipId),
    );

final publishedCoursesProvider = StreamProvider<List<Course>>(
  (ref) => ref.watch(courseRepositoryProvider).watchPublishedCourses(),
);

final allCoursesProvider = StreamProvider<List<Course>>(
  (ref) => ref.watch(courseRepositoryProvider).watchAllCourses(),
);

final mentorCoursesProvider = StreamProvider.family<List<Course>, String>(
  (ref, mentorUid) =>
      ref.watch(courseRepositoryProvider).watchMentorCourses(mentorUid),
);

final courseDetailProvider = StreamProvider.autoDispose.family<Course?, String>(
  (ref, courseId) => ref.watch(courseRepositoryProvider).watchCourse(courseId),
);

final courseEngagementProvider = StreamProvider.autoDispose
    .family<List<CourseProgress>, ({String courseId, String? mentorUid})>(
      (ref, args) => ref
          .watch(courseRepositoryProvider)
          .watchCourseEngagement(args.courseId, courseOwnerUid: args.mentorUid),
    );

final userCourseProgressProvider =
    StreamProvider.family<List<CourseProgress>, String>(
      (ref, uid) => ref.watch(courseRepositoryProvider).watchUserProgress(uid),
    );

final publishedOpportunitiesProvider = StreamProvider<List<OpportunityListing>>(
  (ref) => ref.watch(opportunityRepositoryProvider).watchPublished(),
);

final allOpportunitiesProvider = StreamProvider<List<OpportunityListing>>(
  (ref) => ref.watch(opportunityRepositoryProvider).watchAll(),
);

final opportunityDetailProvider = StreamProvider.autoDispose
    .family<OpportunityListing?, String>(
      (ref, opportunityId) => ref
          .watch(opportunityRepositoryProvider)
          .watchOpportunity(opportunityId),
    );

final opportunityApplicationsProvider = StreamProvider.autoDispose
    .family<List<OpportunityApplication>, String>(
      (ref, opportunityId) => ref
          .watch(opportunityRepositoryProvider)
          .watchApplicationsForOpportunity(opportunityId),
    );

final projectDetailProvider = StreamProvider.autoDispose
    .family<PortfolioProject?, String>(
      (ref, projectId) =>
          ref.watch(projectRepositoryProvider).watchProject(projectId),
    );

final mentorshipDetailProvider = StreamProvider.autoDispose
    .family<Mentorship?, String>(
      (ref, mentorshipId) =>
          ref.watch(mentorshipRepositoryProvider).watchMentorship(mentorshipId),
    );

final mentorApplicationDetailProvider = StreamProvider.autoDispose
    .family<MentorApplication?, String>(
      (ref, uid) =>
          ref.watch(mentorApplicationRepositoryProvider).watchOwnApplication(uid),
    );

final userApplicationsProvider =
    StreamProvider.family<List<OpportunityApplication>, String>(
      (ref, uid) =>
          ref.watch(opportunityRepositoryProvider).watchUserApplications(uid),
    );

final liveNotificationsProvider =
    StreamProvider.family<List<UserNotification>, String>(
      (ref, uid) =>
          ref.watch(userNotificationRepositoryProvider).watchNotifications(uid),
    );

final liveUnreadNotificationCountProvider = StreamProvider.family<int, String>(
  (ref, uid) =>
      ref.watch(userNotificationRepositoryProvider).watchUnreadCount(uid),
);

final pendingMentorApplicationsProvider =
    StreamProvider<List<MentorApplication>>(
      (ref) => ref
          .watch(mentorApplicationRepositoryProvider)
          .watchApplications(status: MentorApplicationStatus.pending),
    );

final allMentorApplicationsProvider = StreamProvider<List<MentorApplication>>(
  (ref) => ref.watch(mentorApplicationRepositoryProvider).watchApplications(),
);

final platformMetricsProvider = FutureProvider<PlatformMetrics>(
  (ref) => ref.watch(platformAdminRepositoryProvider).loadMetrics(),
);

final adminUsersFilterProvider =
    StreamProvider.family<
      List<AppUserAccount>,
      ({UserRole? role, AccountStatus? status})
    >(
      (ref, filter) => ref
          .watch(platformAdminRepositoryProvider)
          .watchUsers(roleFilter: filter.role, statusFilter: filter.status),
    );

final adminAuditLogsProvider = StreamProvider<List<AuditLogEntry>>(
  (ref) => ref.watch(platformAdminRepositoryProvider).watchAuditLogs(),
);

final adminMentorshipsProvider =
    StreamProvider.family<List<Mentorship>, MentorshipStatus?>(
      (ref, statusFilter) => ref
          .watch(platformAdminRepositoryProvider)
          .watchAllMentorships(statusFilter: statusFilter),
    );

final adminSessionsProvider =
    StreamProvider.family<List<MentorshipSession>, SessionStatus?>(
      (ref, statusFilter) => ref
          .watch(platformAdminRepositoryProvider)
          .watchAllSessions(statusFilter: statusFilter),
    );

final userAccountDetailProvider = StreamProvider.family<AppUserAccount?, String>(
  (ref, uid) => ref.watch(userAccountRepositoryProvider).watchAccount(uid),
);
