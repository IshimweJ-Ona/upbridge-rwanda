// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// MM2 · One mentee's progress.
class MenteeDetailScreen extends ConsumerWidget {
  const MenteeDetailScreen({super.key, required this.menteeId});

  final String menteeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final m = data.mentee(menteeId);
    if (m == null) {
      return const DetailPage(
        title: 'Mentee',
        backFallback: '/m/mentees',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.person_off_outlined, title: 'Mentee not found')],
      );
    }
    final pending = data.queue.where((s) => s.youthId == m.id).toList();
    final sessions = data.mentorSessions.where((s) => s.youthId == m.id).toList();
    final first = m.name.split(' ').first;

    final tasks = [
      for (final t in SampleData.jeanTasks().where((t) => t.stage == 1 || t.number <= m.approved + 1))
        t.copyWith(
          status: t.number <= m.approved
              ? TaskStatus.approved
              : pending.any((p) => p.taskId == t.id)
                  ? TaskStatus.inReview
                  : (t.number == m.approved + 1 ? TaskStatus.available : TaskStatus.locked),
          statusNote: t.number <= m.approved ? 'Approved' : (pending.any((p) => p.taskId == t.id) ? 'Waiting for you' : null),
        ),
    ];

    return DetailPage(
      title: m.name,
      backFallback: '/m/mentees',
      footer: pending.isEmpty
          ? null
          : [
              AppButton(
                'Open Task ${pending.first.taskNumber} ${pending.first.isRecheck ? 'resubmission' : 'submission'}',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push('/m-submission/${pending.first.id}'),
              ),
            ],
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
                  Text('${m.district} · ${m.lastActive}', style: AppText.bodyS),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StatusBadge(m.status, tone: m.tone),
        const SizedBox(height: 18),
        StatStrip([
          StatItem('', 'Tasks approved', countTo: m.approved),
          StatItem('', 'Waiting for you', countTo: pending.length),
          StatItem('', 'Sessions', countTo: sessions.length),
        ]),
        const SizedBox(height: 18),
        MonoLabel('${m.path} · ${m.approved} of ${m.total}'),
        const SizedBox(height: 8),
        ProgressLine(m.progress),
        if (m.tone == Tone.warning && pending.isEmpty) ...[
          const SizedBox(height: 16),
          NoticeCard(
            tone: Tone.warning,
            icon: Icons.notifications_paused_outlined,
            title: '$first has been quiet',
            body: 'A short message often helps. Suggest a 15-minute check-in.',
          ),
        ],
        const SectionLabel('Path progress'),
        ListGroup(children: [for (final t in tasks) TaskRow(task: t)]),
        if (sessions.isNotEmpty) ...[
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
      ],
    );
  }
}
