import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/prompt_sheet.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/admin/presentation/widgets/catalog_editor_sheets.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/mentorship/presentation/widgets/book_session_sheet.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorDashboardScreen extends ConsumerStatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  ConsumerState<MentorDashboardScreen> createState() =>
      _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends ConsumerState<MentorDashboardScreen> {
  final Set<String> _processingIds = {};

  Future<void> _acceptRequest(MentorRequest request) async {
    setState(() => _processingIds.add(request.id));
    try {
      final mentorshipId = await ref
          .read(mentorshipRepositoryProvider)
          .acceptRequest(requestId: request.id);
      if (!mounted) return;
      showToast(context, 'Mentorship started with ${request.studentName}');
      context.push('/mentorship/$mentorshipId');
    } catch (error) {
      if (mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
    }
  }

  Future<void> _declineRequest(MentorRequest request) async {
    final note = await showTextPromptSheet(
      context,
      title: 'Decline request from ${request.studentName}',
      fieldLabel: 'Short note (optional)',
      hint: 'Share why or when to try again',
      confirmLabel: 'Decline request',
      destructive: true,
    );
    if (note == null || !mounted) return;

    setState(() => _processingIds.add(request.id));
    try {
      await ref
          .read(mentorshipRepositoryProvider)
          .declineRequest(requestId: request.id, responseNote: note);
      if (mounted) showToast(context, 'Request declined', tone: Tone.warning);
    } catch (error) {
      if (mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;

    if (session == null || uid == null) {
      return PageFrame(
        largeTitle: l10n.mentorDashboardTitle,
        children: const [SizedBox(height: 16), SkeletonDashboardLoader()],
      );
    }

    final unreadCount =
        ref.watch(liveUnreadNotificationCountProvider(uid)).asData?.value ?? 0;
    final requestsAsync = ref.watch(mentorRequestsProvider(uid));
    final mentorshipsAsync = ref.watch(mentorMentorshipsProvider(uid));
    final sessionsAsync = ref.watch(mentorSessionsProvider(uid));
    final coursesAsync = ref.watch(mentorCoursesProvider(uid));
    final profile = ref.watch(userProfileProvider(uid)).asData?.value;

    final requests = requestsAsync.asData?.value ?? const <MentorRequest>[];
    final mentorships = mentorshipsAsync.asData?.value ?? const <Mentorship>[];
    final sessions = sessionsAsync.asData?.value ?? const <MentorshipSession>[];
    final courses = coursesAsync.asData?.value ?? const <Course>[];

    final pendingRequests = requests
        .where((r) => r.status == MentorRequestStatus.pending)
        .toList(growable: false);
    final activeMentees = mentorships
        .where((m) => m.status == MentorshipStatus.active)
        .toList(growable: false);
    final upcomingSessions = sessions
        .where((s) => s.status == SessionStatus.scheduled)
        .toList(growable: false);
    final completedSessionsCount = sessions
        .where((s) => s.status == SessionStatus.completed)
        .length;
    final publishedCourses = courses
        .where((c) => c.status == CourseStatus.published)
        .length;
    final mentorFullName = (session.displayName?.trim().isNotEmpty ?? false)
        ? session.displayName!.trim()
        : session.firstName;
    final profileCompletion = _computeMentorProfileCompletion(profile);
    final recentActivity = _buildRecentActivity(
      requests: requests,
      mentorships: mentorships,
      sessions: sessions,
    );

    return PageFrame(
      largeTitle: l10n.greeting(session.firstName),
      subtitle: l10n.mentorDashboardTitle,
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
        ref.invalidate(mentorRequestsProvider(uid));
        ref.invalidate(mentorMentorshipsProvider(uid));
        ref.invalidate(mentorSessionsProvider(uid));
        ref.invalidate(mentorCoursesProvider(uid));
        ref.invalidate(userProfileProvider(uid));
      },
      children: [
        const SizedBox(height: 12),
        SurfaceCard(
          accentEdge: p.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.mentorDashboardWelcomeBack(mentorFullName),
                style: AppText.titleM.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.mentorDashboardWelcomeBody,
                style: AppText.bodyS.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!session.isApprovedMentor) ...[
          SurfaceCard(
            accentEdge: p.warningText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(l10n.mentorPendingBannerTitle, tone: Tone.warning),
                const SizedBox(height: 8),
                Text(
                  l10n.mentorPendingBannerBody,
                  style: AppText.bodyS.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (profile != null) ...[
          SurfaceCard(
            padding: EdgeInsets.zero,
            accentEdge: profile.isMentorPublic ? p.successText : p.infoText,
            child: ListRow(
              onTap: () => context.go('/m/profile'),
              leading: IconTile(
                profile.isMentorPublic
                    ? Icons.verified_user_outlined
                    : Icons.visibility_off_outlined,
                tone: profile.isMentorPublic ? Tone.success : Tone.info,
              ),
              title: profile.isMentorPublic
                  ? 'Mentor profile active & visible'
                  : 'Mentor profile hidden',
              subtitle: profile.isMentorPublic
                  ? (profile.mentorAvailability.isNotEmpty
                        ? 'Availability: ${profile.mentorAvailability}'
                        : 'Tap to manage expertise, capacity & availability')
                  : 'Enable directory visibility so students can request you.',
            ),
          ),
          const SizedBox(height: 12),
        ],
        MetricsGrid(
          items: [
            MetricTileData(
              label: l10n.tabMentorMentees,
              value: '${activeMentees.length}',
              icon: Icons.groups_outlined,
              tone: Tone.success,
              onTap: () => context.go('/m/mentees'),
            ),
            MetricTileData(
              label: l10n.tabMentorRequests,
              value: '${pendingRequests.length}',
              icon: Icons.inbox_outlined,
              tone: pendingRequests.isNotEmpty ? Tone.warning : Tone.neutral,
              onTap: () => context.go('/m/requests'),
            ),
            MetricTileData(
              label: l10n.tabMentorSessions,
              value: '${upcomingSessions.length}',
              icon: Icons.event_outlined,
              tone: Tone.info,
              onTap: () => context.push('/m/sessions'),
            ),
            MetricTileData(
              label: '${l10n.tabMentorCourses} ($publishedCourses live)',
              value: '${courses.length}',
              icon: Icons.menu_book_outlined,
              tone: Tone.info,
              onTap: () => context.go('/m/courses'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListRow(
                onTap: () => context.push('/m/sessions'),
                leading: const IconTile(
                  Icons.task_alt_rounded,
                  tone: Tone.success,
                ),
                title: l10n.completedSessionsLabel,
                subtitle: 'Total sessions marked completed across mentees',
                trailing: Text(
                  '$completedSessionsCount',
                  style: AppText.titleM.copyWith(color: p.textPrimary),
                ),
              ),
              const Divider(height: 1),
              ListRow(
                onTap: () => context.go('/m/profile'),
                leading: IconTile(
                  Icons.workspace_premium_outlined,
                  tone: profileCompletion >= 80 ? Tone.success : Tone.warning,
                ),
                title: l10n.profileCompletionLabel,
                subtitle: profileCompletion >= 100
                    ? 'Mentor directory profile complete'
                    : 'Complete headline, bio, expertise & availability',
                trailing: StatusBadge(
                  '$profileCompletion%',
                  tone: profileCompletion >= 80 ? Tone.success : Tone.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            QuickActionChip(
              label: l10n.createCourseLabel,
              icon: Icons.add_rounded,
              primary: true,
              onTap: () => showCourseEditorSheet(
                context,
                adminUid: uid,
                ownerName: session.displayName ?? 'UpBridge Mentor',
                isMentorAuthor: true,
              ),
            ),
            QuickActionChip(
              label: l10n.mentorCoursesTitle,
              icon: Icons.menu_book_outlined,
              onTap: () => context.go('/m/courses'),
            ),
            QuickActionChip(
              label: l10n.tabMentorSessions,
              icon: Icons.event_outlined,
              onTap: () => context.push('/m/sessions'),
            ),
          ],
        ),
        SectionLabel(l10n.pendingRequestsLabel),
        if (requestsAsync.isLoading && !requestsAsync.hasValue)
          const SkeletonCardLoader(lines: 2)
        else if (requestsAsync.hasError && !requestsAsync.hasValue)
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: l10n.errorLoadingTitle,
            body: errorMessage(requestsAsync.error!),
            action: l10n.retry,
            onAction: () => ref.invalidate(mentorRequestsProvider(uid)),
          )
        else if (pendingRequests.isEmpty)
          EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No pending requests',
            body: 'Students discovering you in Mentors will appear here.',
          )
        else
          for (final req in pendingRequests.take(3)) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListRow(
                    padding: EdgeInsets.zero,
                    leading: AppAvatar(
                      initialsOf(req.studentName),
                      tone: Tone.warning,
                      size: 44,
                    ),
                    title: req.studentName,
                    subtitle: req.goals.isEmpty
                        ? 'Mentorship request'
                        : req.goals,
                    trailing: const StatusBadge('Pending', tone: Tone.warning),
                    chevron: false,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    req.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyS.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          'Accept',
                          size: ButtonSize.small,
                          loading: _processingIds.contains(req.id),
                          onPressed: () => _acceptRequest(req),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          'Decline',
                          size: ButtonSize.small,
                          variant: ButtonVariant.secondary,
                          onPressed: _processingIds.contains(req.id)
                              ? null
                              : () => _declineRequest(req),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        SectionLabel(l10n.upcomingSessionLabel),
        if (sessionsAsync.isLoading && !sessionsAsync.hasValue)
          const SkeletonCardLoader(lines: 1)
        else if (upcomingSessions.isEmpty)
          EmptyState(
            icon: Icons.event_outlined,
            title: 'No upcoming sessions',
            body: activeMentees.isEmpty
                ? 'Accept a request to begin scheduling 1-on-1 sessions.'
                : 'Open a mentee workspace or schedule a 1-on-1 session.',
            action: activeMentees.isEmpty ? null : 'Schedule session',
            onAction: activeMentees.isEmpty
                ? null
                : () => context.push('/m/sessions'),
          )
        else
          for (final s in upcomingSessions.take(3)) ...[
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListRow(
                onTap: () => s.mentorshipId.isNotEmpty
                    ? context.push('/mentorship/${s.mentorshipId}')
                    : showSessionDetailSheet(
                        context,
                        session: s,
                        actorUid: uid,
                        isMentor: true,
                      ),
                leading: const IconTile(
                  Icons.videocam_outlined,
                  tone: Tone.info,
                ),
                title: s.topic,
                subtitle: 'With ${s.studentName}',
                meta:
                    '${DateFormat('EEE d MMM · HH:mm').format(s.scheduledAt.toLocal())} · ${s.meetingMode}',
              ),
            ),
            const SizedBox(height: 10),
          ],
        SectionLabel(l10n.myMenteesLabel),
        if (mentorshipsAsync.isLoading && !mentorshipsAsync.hasValue)
          const SkeletonCardLoader(lines: 1)
        else if (activeMentees.isEmpty)
          const EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No active mentees yet',
            body: 'Accepted mentorship pairings appear here.',
          )
        else
          for (final m in activeMentees.take(4)) ...[
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListRow(
                onTap: () => context.push('/mentorship/${m.id}'),
                leading: AppAvatar(
                  initialsOf(m.studentName),
                  tone: Tone.success,
                  size: 40,
                ),
                title: m.studentName,
                subtitle: m.goalSummary.isEmpty
                    ? 'Open workspace'
                    : m.goalSummary,
                trailing: const StatusBadge('Active', tone: Tone.success),
              ),
            ),
            const SizedBox(height: 10),
          ],
        SectionLabel(l10n.recentMentorshipActivityLabel),
        if (recentActivity.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'No recent mentorship activity',
            body: 'Incoming requests, pairings, and session milestones appear here.',
          )
        else
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < recentActivity.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListRow(
                    onTap: () => context.push(recentActivity[i].route),
                    leading: IconTile(
                      recentActivity[i].icon,
                      tone: recentActivity[i].tone,
                    ),
                    title: recentActivity[i].title,
                    subtitle: recentActivity[i].subtitle,
                    meta: DateFormat(
                      'd MMM y · HH:mm',
                    ).format(recentActivity[i].timestamp.toLocal()),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static int _computeMentorProfileCompletion(UserProfile? profile) {
    if (profile == null) return 0;
    final checks = [
      profile.displayName.trim().isNotEmpty,
      profile.headline.trim().isNotEmpty,
      profile.mentorBio.trim().isNotEmpty || profile.about.trim().isNotEmpty,
      profile.mentorExpertise.isNotEmpty,
      profile.mentorAvailability.trim().isNotEmpty,
      profile.skills.isNotEmpty || profile.professionalLinks.isNotEmpty,
      profile.isMentorPublic,
    ];
    final done = checks.where((ok) => ok).length;
    return ((done / checks.length) * 100).round();
  }

  static List<_MentorActivityItem> _buildRecentActivity({
    required List<MentorRequest> requests,
    required List<Mentorship> mentorships,
    required List<MentorshipSession> sessions,
  }) {
    final items = <_MentorActivityItem>[
      for (final req in requests)
        _MentorActivityItem(
          title: 'Request from ${req.studentName}',
          subtitle: 'Status: ${req.status.label}',
          route: '/m/requests',
          timestamp: req.updatedAt,
          icon: Icons.inbox_outlined,
          tone: req.status == MentorRequestStatus.pending
              ? Tone.warning
              : req.status == MentorRequestStatus.accepted
              ? Tone.success
              : Tone.neutral,
        ),
      for (final mentorship in mentorships)
        _MentorActivityItem(
          title: 'Mentorship with ${mentorship.studentName}',
          subtitle: 'Status: ${mentorship.status.label}',
          route: '/mentorship/${mentorship.id}',
          timestamp: mentorship.updatedAt,
          icon: Icons.groups_outlined,
          tone: mentorship.status == MentorshipStatus.active
              ? Tone.success
              : Tone.info,
        ),
      for (final session in sessions)
        _MentorActivityItem(
          title: 'Session: ${session.topic}',
          subtitle:
              '${session.studentName} · ${session.status.label}',
          route: session.mentorshipId.isNotEmpty
              ? '/mentorship/${session.mentorshipId}'
              : '/m/sessions',
          timestamp: session.updatedAt,
          icon: Icons.event_outlined,
          tone: session.status == SessionStatus.completed
              ? Tone.success
              : Tone.info,
        ),
    ];
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(4).toList(growable: false);
  }
}

class _MentorActivityItem {
  const _MentorActivityItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.timestamp,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final String route;
  final DateTime timestamp;
  final IconData icon;
  final Tone tone;
}
