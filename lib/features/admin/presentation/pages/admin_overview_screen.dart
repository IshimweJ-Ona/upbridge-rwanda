import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/admin/domain/models/audit_log_entry.dart';
import 'package:upbridge/features/admin/presentation/widgets/catalog_editor_sheets.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  Future<void> _createCourse(BuildContext context, String uid) async {
    final saved = await showCourseEditorSheet(context, adminUid: uid);
    if (saved == true && context.mounted) {
      showToast(context, 'Course saved');
    }
  }

  Future<void> _createOpportunity(BuildContext context, String uid) async {
    final saved = await showOpportunityEditorSheet(context, adminUid: uid);
    if (saved == true && context.mounted) {
      showToast(context, 'Opportunity saved');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;

    if (session == null || uid == null) {
      return const PageFrame(
        largeTitle: 'Admin Overview',
        subtitle: 'Platform activity and management',
        children: [SizedBox(height: 16), SkeletonDashboardLoader()],
      );
    }

    final unreadCount =
        ref.watch(liveUnreadNotificationCountProvider(uid)).asData?.value ?? 0;
    final metricsAsync = ref.watch(platformMetricsProvider);
    final pendingAppsAsync = ref.watch(pendingMentorApplicationsProvider);
    final auditLogsAsync = ref.watch(adminAuditLogsProvider);

    return PageFrame(
      largeTitle: 'Admin Overview',
      subtitle: 'Platform activity and management',
      actions: [
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          badge: unreadCount > 0,
          tooltip: l10n.notificationsTitle,
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: l10n.tabAdminSettings,
          child: Pressable(
            onTap: () => context.go('/a/settings'),
            scale: 0.94,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AppAvatar(
                initialsOf(session.displayLabel),
                tone: Tone.info,
                size: 34,
              ),
            ),
          ),
        ),
      ],
      onRefresh: () async {
        ref.invalidate(platformMetricsProvider);
        ref.invalidate(pendingMentorApplicationsProvider);
        ref.invalidate(adminAuditLogsProvider);
      },
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            QuickActionChip(
              label: 'New course',
              icon: Icons.add_rounded,
              primary: true,
              onTap: () => _createCourse(context, uid),
            ),
            QuickActionChip(
              label: 'Post opportunity',
              icon: Icons.work_outline_rounded,
              onTap: () => _createOpportunity(context, uid),
            ),
            QuickActionChip(
              label: 'Manage users',
              icon: Icons.group_outlined,
              onTap: () => context.go('/a/users'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        metricsAsync.when(
          loading: () => const SkeletonMetricsGridLoader(tiles: 6),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load metrics',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(platformMetricsProvider),
          ),
          data: (metrics) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetricsGrid(
                items: [
                  MetricTileData(
                    label: 'Total users',
                    caption: 'All accounts',
                    value: '${metrics.totalUsers}',
                    icon: Icons.people_outline_rounded,
                    tone: Tone.info,
                    onTap: () => context.go('/a/users'),
                  ),
                  MetricTileData(
                    label: 'Youth',
                    caption: 'Learner accounts',
                    value: '${metrics.studentCount}',
                    icon: Icons.school_outlined,
                    tone: Tone.success,
                    onTap: () => context.go('/a/users'),
                  ),
                  MetricTileData(
                    label: 'Verified mentors',
                    caption: 'Approved mentors',
                    value: '${metrics.mentorCount}',
                    icon: Icons.workspace_premium_outlined,
                    tone: Tone.info,
                    onTap: () => context.go('/a/mentors'),
                  ),
                  MetricTileData(
                    label: 'Active mentorships',
                    caption: 'Ongoing pairs',
                    value: '${metrics.activeMentorships}',
                    icon: Icons.handshake_outlined,
                    tone: Tone.info,
                    onTap: () => context.go('/a/mentors'),
                  ),
                  MetricTileData(
                    label: 'Published courses',
                    caption: 'Live tracks',
                    value: '${metrics.publishedCourses}',
                    icon: Icons.menu_book_outlined,
                    tone: Tone.success,
                    onTap: () => context.go('/a/catalog'),
                  ),
                  MetricTileData(
                    label: 'Open opportunities',
                    caption: 'Live listings',
                    value: '${metrics.publishedOpportunities}',
                    icon: Icons.work_outline_rounded,
                    tone: Tone.warning,
                    onTap: () => context.go('/a/catalog'),
                  ),
                ],
              ),
              SectionLabel(
                'Mentor applications',
                action: 'Review applications',
                onAction: () => context.go('/a/mentors'),
              ),
              _MentorQueueCard(
                pendingCount: metrics.pendingMentorApplications,
                recentApps:
                    pendingAppsAsync.asData?.value ?? const <MentorApplication>[],
                onReviewAll: () => context.go('/a/mentors'),
                onOpenApplicant: (appUid) => context.push('/a-applicant/$appUid'),
              ),
              SectionLabel(
                'Recent activity',
                action: 'Audit logs',
                onAction: () => context.go('/a/settings'),
              ),
              _RecentActivitySection(
                logsAsync: auditLogsAsync,
                onRetry: () => ref.invalidate(adminAuditLogsProvider),
                onOpenSettings: () => context.go('/a/settings'),
              ),
              const SizedBox(height: 12),
              Text(
                'Secured by Cloud Firestore Spark rules and verified admin custom claims.',
                style: AppText.caption.copyWith(color: p.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MentorQueueCard extends StatelessWidget {
  const _MentorQueueCard({
    required this.pendingCount,
    required this.recentApps,
    required this.onReviewAll,
    required this.onOpenApplicant,
  });

  final int pendingCount;
  final List<MentorApplication> recentApps;
  final VoidCallback onReviewAll;
  final ValueChanged<String> onOpenApplicant;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final preview = recentApps.take(2).toList(growable: false);

    return SurfaceCard(
      padding: EdgeInsets.zero,
      accentEdge: pendingCount > 0 ? p.warningText : p.successText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                IconTile(
                  pendingCount > 0
                      ? Icons.how_to_reg_outlined
                      : Icons.verified_user_outlined,
                  tone: pendingCount > 0 ? Tone.warning : Tone.success,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingCount == 0
                            ? 'All mentor applications reviewed'
                            : '$pendingCount mentor application${pendingCount == 1 ? '' : 's'} waiting',
                        style: AppText.bodyMStrong.copyWith(color: p.textPrimary),
                      ),
                      Text(
                        pendingCount == 0
                            ? 'No pending applications in queue'
                            : 'Inspect credentials and approve or reply',
                        style: AppText.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  '$pendingCount pending',
                  tone: pendingCount > 0 ? Tone.warning : Tone.success,
                ),
              ],
            ),
          ),
          if (preview.isNotEmpty) ...[
            Divider(height: 1, color: p.borderSubtle),
            for (var i = 0; i < preview.length; i++) ...[
              if (i > 0) Divider(height: 1, color: p.borderSubtle),
              UserListTile(
                name: preview[i].applicantName,
                email: preview[i].headline,
                avatarTone: Tone.info,
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: p.textMuted,
                ),
                onTap: () => onOpenApplicant(preview[i].ownerUid),
              ),
            ],
          ],
          Divider(height: 1, color: p.borderSubtle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextLink(
                'Review applications',
                compact: true,
                onTap: onReviewAll,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.logsAsync,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final AsyncValue<List<AuditLogEntry>> logsAsync;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return logsAsync.when(
      loading: () => const SkeletonListLoader(rows: 2, showAvatar: true),
      error: (_, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load activity',
        action: 'Try again',
        onAction: onRetry,
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No recent admin activity',
            body: 'Mentor reviews and status changes appear here.',
          );
        }
        final recent = logs.take(4).toList(growable: false);
        return ListGroup(
          children: [
            for (final log in recent)
              ActivityTile(
                icon: Icons.history_rounded,
                tone: Tone.info,
                title: log.displayAction,
                subtitle: log.details.isNotEmpty
                    ? log.details
                    : '${log.targetCollection}/${log.targetId}',
                timestamp: DateFormat('d MMM · HH:mm')
                    .format(log.createdAt.toLocal()),
                onTap: onOpenSettings,
              ),
          ],
        );
      },
    );
  }
}
