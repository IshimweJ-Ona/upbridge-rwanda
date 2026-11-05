// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// MR2 · A youth's submission (Jean's Task 3 re-check).
class SubmissionScreen extends ConsumerWidget {
  const SubmissionScreen({super.key, required this.submissionId});

  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final s = data.submission(submissionId);
    if (s == null) {
      return const DetailPage(
        title: 'Submission',
        backFallback: '/m/reviews',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.search_off_rounded, title: 'Submission not found')],
      );
    }
    final task = data.task(s.taskId);
    final first = s.youthName.split(' ').first;

    return DetailPage(
      title: s.youthName,
      backFallback: '/m/reviews',
      footer: [
        if (s.reviewed)
          const AppButton('Review sent', leadingIcon: Icons.check_rounded, onPressed: null)
        else
          AppButton('Start review', icon: Icons.arrow_forward_rounded, onPressed: () => context.push('/m-review/${s.id}')),
        AppButton('View $first’s progress', variant: ButtonVariant.secondary, onPressed: () => context.push('/m-mentee/${s.youthId}')),
      ],
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            AppAvatar(s.youthInitials, tone: Tone.info, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.youthName, style: AppText.titleS),
                  MonoLabel('Submitted ${s.submittedAt}'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusBadge('Task ${s.taskNumber} · attempt ${s.attempt}'),
            if (s.isRecheck) const StatusBadge('Re-check', tone: Tone.warning),
            StatusBadge(s.dueLabel, tone: s.urgent ? Tone.danger : Tone.info, icon: Icons.schedule_rounded),
          ],
        ),
        const SizedBox(height: 14),
        Text(s.taskTitle, style: AppText.titleL),
        const SizedBox(height: 4),
        Text(s.path, style: AppText.bodyS),
        if (s.previousNote != null) ...[
          const SizedBox(height: 16),
          NoticeCard(tone: Tone.warning, icon: Icons.history_rounded, title: 'What you asked for last time', body: s.previousNote),
        ],
        const SectionLabel('Their work'),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.public_rounded, tone: Tone.info),
              title: 'Live page',
              subtitle: displayUrl(s.liveUrl),
              chevron: false,
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.link),
              onTap: () => openLink(context, s.liveUrl),
            ),
            ListRow(
              leading: const IconTile(Icons.code_rounded),
              title: 'Repository',
              subtitle: displayUrl(s.repoUrl),
              chevron: false,
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.link),
              onTap: () => openLink(context, s.repoUrl),
            ),
          ],
        ),
        SectionLabel(s.isRecheck ? 'What $first changed' : '$first’s note'),
        SurfaceCard(child: Text('“${s.reflection}”', style: AppText.bodyM.copyWith(color: AppColors.textPrimary))),
        if (task.criteria.isNotEmpty) ...[
          SectionLabel('You’ll check · ${task.criteria.length} criteria'),
          ListGroup(
            children: [
              for (var i = 0; i < task.criteria.length; i++)
                ListRow(
                  dense: true,
                  leading: Text('0${i + 1}', style: AppText.dataMonoStrong.copyWith(color: AppColors.accentText)),
                  title: task.criteria[i].title,
                  subtitle: task.criteria[i].detail,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
