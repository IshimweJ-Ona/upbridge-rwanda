import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;

    if (session == null || uid == null) {
      return PageFrame(
        largeTitle: l10n.studentDashboardTitle,
        children: const [SizedBox(height: 16), SkeletonDashboardLoader()],
      );
    }

    final unreadCount =
        ref.watch(liveUnreadNotificationCountProvider(uid)).asData?.value ?? 0;
    final profileAsync = ref.watch(userProfileProvider(uid));
    final mentorshipsAsync = ref.watch(studentMentorshipsProvider(uid));
    final sessionsAsync = ref.watch(studentSessionsProvider(uid));
    final coursesAsync = ref.watch(publishedCoursesProvider);
    final progressAsync = ref.watch(userCourseProgressProvider(uid));
    final mentorsAsync = ref.watch(approvedMentorsProvider);
    final oppsAsync = ref.watch(publishedOpportunitiesProvider);

    final profile = profileAsync.asData?.value;
    final mentorships = mentorshipsAsync.asData?.value ?? const <Mentorship>[];
    final sessions = sessionsAsync.asData?.value ?? const <MentorshipSession>[];
    final courses = coursesAsync.asData?.value ?? const <Course>[];
    final progressList =
        progressAsync.asData?.value ?? const <CourseProgress>[];
    final mentors = mentorsAsync.asData?.value ?? const <UserProfile>[];
    final opps = oppsAsync.asData?.value ?? const <OpportunityListing>[];

    final activeMentorship = mentorships
        .where((m) => m.status == MentorshipStatus.active)
        .firstOrNull;
    final upcomingSession = sessions
        .where((s) => s.status == SessionStatus.scheduled)
        .firstOrNull;

    final nextAction = _computeNextAction(
      context: context,
      profile: profile,
      activeMentorship: activeMentorship,
      upcomingSession: upcomingSession,
      courses: courses,
      progressList: progressList,
      opps: opps,
    );

    final completedCourses = progressList
        .where((p) => p.status == CourseProgressStatus.completed)
        .length;

    return PageFrame(
      largeTitle: l10n.greeting(session.firstName),
      subtitle: l10n.studentDashboardTitle,
      actions: [
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          badge: unreadCount > 0,
          tooltip: l10n.notificationsTitle,
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(width: 4),
      ],
      onRefresh: () async {
        ref.invalidate(userProfileProvider(uid));
        ref.invalidate(studentMentorshipsProvider(uid));
        ref.invalidate(studentSessionsProvider(uid));
        ref.invalidate(publishedCoursesProvider);
        ref.invalidate(userCourseProgressProvider(uid));
        ref.invalidate(approvedMentorsProvider);
        ref.invalidate(publishedOpportunitiesProvider);
      },
      children: [
        const SizedBox(height: 12),
        if (session.hasPendingMentorApplication) ...[
          SurfaceCard(
            onTap: () => context.push('/mentor-apply'),
            accentEdge: context.palette.warningText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(l10n.mentorPendingBannerTitle, tone: Tone.warning),
                const SizedBox(height: 8),
                Text(
                  l10n.mentorPendingBannerBody,
                  style: AppText.bodyS.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (session.hasRejectedMentorApplication) ...[
          SurfaceCard(
            onTap: () => context.push('/mentor-apply'),
            accentEdge: context.palette.dangerText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge(
                  'Mentor application update',
                  tone: Tone.danger,
                ),
                const SizedBox(height: 8),
                Text(
                  session.mentorApplication?.rejectionReason ??
                      'Your mentor application needs updates before approval.',
                  style: AppText.bodyS.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        NextStepCard(
          eyebrow: l10n.nextActionLabel,
          icon: nextAction.icon,
          title: nextAction.title,
          body: nextAction.body,
          action: nextAction.actionLabel,
          onAction: nextAction.onTap,
        ),
        SectionLabel(l10n.activeMentorshipLabel),
        if (mentorshipsAsync.isLoading && !mentorshipsAsync.hasValue)
          const SkeletonCardLoader(lines: 1)
        else if (activeMentorship == null)
          EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No active mentorship yet',
            body: 'Explore verified mentors and send a mentorship request.',
            action: 'Find a mentor',
            onAction: () => context.go('/mentors'),
          )
        else
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: ListRow(
              onTap: () => context.push('/mentorship/${activeMentorship.id}'),
              leading: AppAvatar(
                initialsOf(activeMentorship.mentorName),
                tone: Tone.info,
                size: 40,
              ),
              title: activeMentorship.mentorName,
              subtitle: activeMentorship.goalSummary.isEmpty
                  ? 'Active mentorship'
                  : activeMentorship.goalSummary,
              trailing: const StatusBadge('Active', tone: Tone.success),
            ),
          ),
        SectionLabel(l10n.upcomingSessionLabel),
        if (sessionsAsync.isLoading && !sessionsAsync.hasValue)
          const SkeletonCardLoader(lines: 1)
        else if (upcomingSession == null)
          EmptyState(
            icon: Icons.event_outlined,
            title: 'No upcoming session',
            body: activeMentorship == null
                ? 'Schedule a session once a mentor accepts your request.'
                : 'Schedule a 1-on-1 session with ${activeMentorship.mentorName}.',
            action: activeMentorship == null ? null : 'Open mentorship',
            onAction: activeMentorship == null
                ? null
                : () => context.push('/mentorship/${activeMentorship.id}'),
          )
        else
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: ListRow(
              onTap: () =>
                  context.push('/mentorship/${upcomingSession.mentorshipId}'),
              leading: const IconTile(Icons.videocam_outlined, tone: Tone.info),
              title: upcomingSession.topic,
              subtitle: 'With ${upcomingSession.mentorName}',
              meta:
                  '${DateFormat('EEE d MMM · HH:mm').format(upcomingSession.scheduledAt.toLocal())} · ${upcomingSession.meetingMode}',
            ),
          ),
        SectionLabel(
          l10n.learningProgressLabel,
          action: 'Open courses',
          onAction: () => context.go('/learn'),
        ),
        if (coursesAsync.isLoading && !coursesAsync.hasValue)
          const SkeletonCardLoader(lines: 1)
        else if (courses.isEmpty)
          EmptyState(
            icon: Icons.school_outlined,
            title: l10n.noCoursesYet,
            body: l10n.noCoursesBody,
          )
        else
          SurfaceCard(
            onTap: () => context.go('/learn'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$completedCourses of ${courses.length} courses completed',
                        style: AppText.bodyMStrong.copyWith(
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${courses.isEmpty ? 0 : ((completedCourses / courses.length) * 100).round()}%',
                      style: AppText.dataMonoStrong.copyWith(
                        color: context.palette.actionPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressLine(
                  courses.isEmpty ? 0 : completedCourses / courses.length,
                  color: context.palette.actionPrimary,
                ),
              ],
            ),
          ),
        SectionLabel(
          l10n.recommendedMentorsLabel,
          action: 'Browse all',
          onAction: () => context.go('/mentors'),
        ),
        if (mentorsAsync.isLoading && !mentorsAsync.hasValue)
          const SkeletonCardLoader(lines: 1)
        else if (mentors.where((m) => m.ownerUid != uid).isEmpty)
          EmptyState(
            icon: Icons.person_search_outlined,
            title: l10n.noMentorsYet,
            body: l10n.noMentorsBody,
          )
        else
          ListGroup(
            children: [
              for (final mentor
                  in mentors.where((m) => m.ownerUid != uid).take(3))
                ListRow(
                  leading: AppAvatar(
                    initialsOf(mentor.displayName),
                    imageUrl: mentor.photoAsset?.url,
                    tone: Tone.info,
                  ),
                  title: mentor.displayName.isEmpty
                      ? 'Verified Mentor'
                      : mentor.displayName,
                  subtitle: mentor.headline.isEmpty
                      ? mentor.mentorExpertise.take(3).join(' · ')
                      : mentor.headline,
                  meta: mentor.mentorExpertise.take(2).join(' · '),
                  onTap: () => context.push('/mentor/${mentor.ownerUid}'),
                ),
            ],
          ),
        SectionLabel(
          l10n.opportunitiesLabel,
          action: 'See all',
          onAction: () => context.go('/jobs'),
        ),
        if (oppsAsync.isLoading && !oppsAsync.hasValue)
          const SkeletonCardLoader(lines: 1)
        else if (opps.isEmpty)
          EmptyState(
            icon: Icons.work_outline_rounded,
            title: l10n.noOpportunitiesYet,
            body: l10n.noOpportunitiesBody,
          )
        else
          ListGroup(
            children: [
              for (final opp in opps.take(3))
                ListRow(
                  leading: const IconTile(
                    Icons.work_outline_rounded,
                    tone: Tone.info,
                  ),
                  title: opp.title,
                  subtitle: '${opp.organization} · ${opp.location}',
                  meta:
                      '${opp.displayType}${opp.workMode.isNotEmpty ? ' · ${opp.workMode}' : ''} · Closes ${DateFormat('d MMM').format(opp.deadline.toLocal())}',
                  onTap: () => context.push('/opportunity/${opp.id}'),
                ),
            ],
          ),
      ],
    );
  }

  _NextAction _computeNextAction({
    required BuildContext context,
    required UserProfile? profile,
    required Mentorship? activeMentorship,
    required MentorshipSession? upcomingSession,
    required List<Course> courses,
    required List<CourseProgress> progressList,
    required List<OpportunityListing> opps,
  }) {
    if (profile == null ||
        profile.headline.trim().isEmpty ||
        profile.skills.isEmpty) {
      return _NextAction(
        icon: Icons.badge_outlined,
        title: 'Complete your CV & portfolio profile',
        body: 'Add a headline, skills, and bio so mentors and employers can discover your strengths.',
        actionLabel: 'Edit profile',
        onTap: () => context.push('/profile-edit'),
      );
    }
    if (upcomingSession != null) {
      return _NextAction(
        icon: Icons.videocam_outlined,
        title: 'Prepare for "${upcomingSession.topic}"',
        body:
            'Session with ${upcomingSession.mentorName} on ${DateFormat('EEE d MMM · HH:mm').format(upcomingSession.scheduledAt.toLocal())}.',
        actionLabel: 'View session',
        onTap: () =>
            context.push('/mentorship/${upcomingSession.mentorshipId}'),
      );
    }
    if (courses.isNotEmpty) {
      final inProgress = progressList
          .where((p) => p.status == CourseProgressStatus.inProgress)
          .firstOrNull;
      if (inProgress != null) {
        return _NextAction(
          icon: Icons.play_circle_outline_rounded,
          title: 'Resume ${inProgress.courseTitle}',
          body:
              '${inProgress.progressPercent}% completed. Keep building your skills.',
          actionLabel: 'Continue learning',
          onTap: () => context.push('/course/${inProgress.courseId}'),
        );
      }
      return _NextAction(
        icon: Icons.school_outlined,
        title: 'Start "${courses.first.title}"',
        body: courses.first.summary,
        actionLabel: 'Open course',
        onTap: () => context.push('/course/${courses.first.id}'),
      );
    }
    if (activeMentorship == null) {
      return _NextAction(
        icon: Icons.people_outline_rounded,
        title: 'Connect with a verified mentor',
        body: 'Browse working professionals in Rwanda and request 1-on-1 guidance.',
        actionLabel: 'Find a mentor',
        onTap: () => context.go('/mentors'),
      );
    }
    return _NextAction(
      icon: Icons.work_outline_rounded,
      title: opps.isEmpty
          ? 'Build a portfolio project'
          : 'Explore ${opps.length} open opportunities',
      body: opps.isEmpty
          ? 'Add a project with screenshots or links to strengthen your CV.'
          : 'Apply with your verified portfolio projects and CV.',
      actionLabel: opps.isEmpty ? 'Add project' : 'View opportunities',
      onTap: () =>
          opps.isEmpty ? context.push('/project-new') : context.go('/jobs'),
    );
  }
}

class _NextAction {
  const _NextAction({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;
}
