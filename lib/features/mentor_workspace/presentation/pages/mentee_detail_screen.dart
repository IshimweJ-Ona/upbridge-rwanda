// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/features/mentor_workspace/data/models/mentee_model.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentee.dart';
import 'package:upbridge/features/mentor_workspace/presentation/providers/mentor_providers.dart';

/// MM2 · One mentee: status and sessions with you.
class MenteeDetailScreen extends ConsumerWidget {
  const MenteeDetailScreen({super.key, required this.menteeId});

  final String menteeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menteeAsync = ref.watch(menteeProvider(menteeId));
    final now = ref.watch(mentorClockProvider)();

    if (!menteeAsync.hasValue && menteeAsync.hasError) {
      return DetailPage(
        title: 'Mentee',
        backFallback: '/m/mentees',
        children: [
          const SizedBox(height: 24),
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load this mentee',
            body: mentorshipErrorText(menteeAsync.error!),
            action: 'Try again',
            onAction: () => ref.invalidate(menteeProvider(menteeId)),
          ),
        ],
      );
    }
    if (!menteeAsync.hasValue) {
      return const DetailPage(
        title: 'Mentee',
        backFallback: '/m/mentees',
        children: [SizedBox(height: 16), Shimmer(child: SkeletonBox(height: 280, radius: Radii.lg))],
      );
    }
    final record = menteeAsync.value;
    if (record == null) {
      return const DetailPage(
        title: 'Mentee',
        backFallback: '/m/mentees',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.person_off_outlined, title: 'Mentee not found')],
      );
    }

    final m = MenteeModel.toMentee(record, now);
    final attention = record.attentionAt(now);
    final sessions = record.sessions.reversed.toList();

    return DetailPage(
      title: m.name,
      backFallback: '/m/mentees',
      footer: record.pendingRequests > 0
          ? [AppButton('Answer ${record.firstName}’s request', icon: Icons.arrow_forward_rounded, onPressed: () => context.go('/m/sessions'))]
          : null,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            AppAvatar(m.initials, tone: Tone.info, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: AppText.titleL),
                  const SizedBox(height: 2),
                  Text(m.lastActive, style: AppText.bodyS),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StatusBadge(m.status, tone: m.tone),
        const SizedBox(height: 18),
        StatStrip([
          StatItem('', 'Sessions done', countTo: record.sessionsDone),
          StatItem('', 'Upcoming', countTo: record.upcoming),
          StatItem('', 'Requests', countTo: record.pendingRequests),
        ]),
        if (attention == MenteeAttention.quiet) ...[
          const SizedBox(height: 16),
          NoticeCard(
            tone: Tone.warning,
            icon: Icons.notifications_paused_outlined,
            title: '${record.firstName} has been quiet',
            body: 'A short message often helps. Suggest a 15-minute check-in.',
          ),
        ],
        const SizedBox(height: 16),
        const NoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Task progress coming soon',
          body: 'Path progress shows here once learning progress is connected.',
        ),
        const SectionLabel('Sessions'),
        ListGroup(
          children: [
            for (final s in sessions)
              ListRow(
                leading: IconTile(s.state == SessionState.done ? Icons.check_rounded : Icons.videocam_outlined, tone: s.state == SessionState.done ? Tone.success : Tone.info),
                title: s.topic,
                meta: '${s.day} · ${s.time}',
                trailing: StatusBadge(switch (s.state) {
                  SessionState.requested => 'Requested',
                  SessionState.upcoming => 'Upcoming',
                  SessionState.done => 'Done',
                  SessionState.declined => 'Declined',
                }),
              ),
          ],
        ),
      ],
    );
  }
}
