// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/models/models.dart';

/// One submission waiting for review (MH1, MR1).
class QueueRow extends StatelessWidget {
  const QueueRow({super.key, required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context) {
    final s = submission;
    return InkWell(
      onTap: () => context.push('/m-submission/${s.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AppAvatar(s.youthInitials, tone: s.urgent ? Tone.danger : Tone.info, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(s.youthName, style: AppText.bodyMStrong, overflow: TextOverflow.ellipsis)),
                      if (s.isRecheck) ...[const SizedBox(width: 8), const StatusBadge('Re-check', tone: Tone.warning)],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Task ${s.taskNumber} · ${s.taskTitle}', style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: s.urgent ? AppColors.dangerText : AppColors.textMuted),
                      const SizedBox(width: 4),
                      MonoLabel(s.dueLabel, color: s.urgent ? AppColors.dangerText : AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Session row for mentors, with optional actions.
class MentorSessionCard extends StatelessWidget {
  const MentorSessionCard({super.key, required this.session, this.actions = const []});

  final Session session;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final s = session;
    return SurfaceCard(
      accentEdge: s.state == SessionState.requested ? AppColors.warningText : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(initialsOf(s.youthName), tone: Tone.info, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.youthName, style: AppText.bodyMStrong),
                    MonoLabel('${s.day} · ${s.time} · ${s.mode}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.topic, style: AppText.titleS),
          if (s.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('“${s.note}”', style: AppText.bodyS),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
