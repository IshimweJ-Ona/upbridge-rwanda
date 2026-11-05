// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// L2 · Task details (Task 3, change requested) and L8 · Task 1 on day one.
class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final task = data.task(taskId);
    final review = data.latestReview(taskId);
    final project = data.projectForTask(taskId);
    final brief = task.brief.isEmpty ? task.summary : task.brief;

    return DetailPage(
      title: 'Task ${task.number}',
      backFallback: '/learn',
      footer: _footer(context, task, project),
      children: [
        const SizedBox(height: 8),
        MonoLabel('Task ${task.number} of ${data.tasks.length} · Stage ${task.stage} · ${task.duration}'),
        const SizedBox(height: 8),
        Text(task.title, style: AppText.titleL),
        const SizedBox(height: 16),
        _StatusNotice(task: task, review: review),
        const SectionLabel('The brief'),
        Text(brief, style: AppText.bodyM),
        if (task.deliverables.isNotEmpty) ...[
          const SectionLabel('What to submit'),
          ListGroup(
            children: [
              for (final d in task.deliverables)
                ListRow(
                  dense: true,
                  leading: Icon(
                    d.toLowerCase().contains('link') ? Icons.link_rounded : (d.toLowerCase().contains('screenshot') ? Icons.image_outlined : Icons.notes_rounded),
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  title: d,
                  titleStyle: AppText.bodyS.copyWith(color: AppColors.textPrimary),
                ),
            ],
          ),
        ],
        if (task.criteria.isNotEmpty) ...[
          SectionLabel('How it’s reviewed · ${task.criteria.length} criteria'),
          SurfaceCard(
            child: Column(
              children: [
                for (var i = 0; i < task.criteria.length; i++) ...[
                  if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.borderSubtle)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 28, child: Text('0${i + 1}', style: AppText.dataMonoStrong.copyWith(color: AppColors.accentText))),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.criteria[i].title, style: AppText.bodyMStrong),
                            const SizedBox(height: 2),
                            Text(task.criteria[i].detail, style: AppText.bodyS),
                          ],
                        ),
                      ),
                      if (review != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          _verdictFor(review, task.criteria[i].title)?.icon ?? Icons.remove_rounded,
                          size: 20,
                          color: _verdictFor(review, task.criteria[i].title)?.tone.foreground ?? AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (task.resources.isNotEmpty) ...[
          const SectionLabel('Resources'),
          ListGroup(
            children: [
              for (final r in task.resources)
                ListRow(
                  leading: IconTile(r.kind.startsWith('Tool') ? Icons.build_outlined : Icons.menu_book_outlined, tone: Tone.info),
                  title: r.title,
                  subtitle: r.source,
                  meta: r.kind,
                  chevron: false,
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.link),
                  onTap: () => openLink(context, r.url),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static Verdict? _verdictFor(Review review, String criterion) {
    for (final r in review.results) {
      if (r.criterion == criterion) return r.verdict;
    }
    return null;
  }

  List<Widget>? _footer(BuildContext context, LearningTask task, Project? project) {
    switch (task.status) {
      case TaskStatus.changesRequested:
        return [
          AppButton('Resubmit your work', icon: Icons.upload_rounded, onPressed: () => context.push('/task-submit/${task.id}')),
          AppButton('See feedback', variant: ButtonVariant.secondary, onPressed: () => context.push('/task-feedback/${task.id}')),
        ];
      case TaskStatus.available:
        return [
          AppButton('Submit your work', icon: Icons.upload_rounded, onPressed: () => context.push('/task-submit/${task.id}')),
          if (task.resources.isNotEmpty)
            AppButton('Open the first lesson', variant: ButtonVariant.secondary, icon: Icons.open_in_new_rounded, onPressed: () => openLink(context, task.resources.first.url)),
        ];
      case TaskStatus.inReview:
        return [AppButton('Back to my path', variant: ButtonVariant.secondary, onPressed: () => context.go('/learn'))];
      case TaskStatus.approved:
        return [
          AppButton('See mentor review', onPressed: () => context.push('/task-feedback/${task.id}')),
          if (project != null)
            AppButton('View in portfolio', variant: ButtonVariant.secondary, onPressed: () => context.push('/project/${project.id}')),
        ];
      case TaskStatus.locked:
        return [AppButton('Unlocks after Task ${task.number - 1}', leadingIcon: Icons.lock_outline_rounded, onPressed: null)];
    }
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.task, required this.review});

  final LearningTask task;
  final Review? review;

  @override
  Widget build(BuildContext context) {
    final mentor = review?.mentorName.split(' ').first ?? 'Your mentor';
    switch (task.status) {
      case TaskStatus.changesRequested:
        CriterionResult? partly;
        for (final r in review?.results ?? const <CriterionResult>[]) {
          if (r.verdict != Verdict.met) {
            partly = r;
            break;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NoticeCard(
              tone: Tone.warning,
              icon: Icons.edit_note_rounded,
              title: '$mentor requested 1 change',
              body: partly == null ? null : '${partly.criterion}: ${partly.note}',
            ),
          ],
        );
      case TaskStatus.inReview:
        return NoticeCard(tone: Tone.info, icon: Icons.hourglass_top_rounded, title: 'In review', body: task.statusNote);
      case TaskStatus.approved:
        return NoticeCard(tone: Tone.success, icon: Icons.verified_outlined, title: 'Approved by $mentor', body: task.statusNote);
      case TaskStatus.available:
        return const NoticeCard(
          tone: Tone.accent,
          icon: Icons.schedule_rounded,
          title: 'Reviewed within 48 hours',
          body: 'Work at your own pace. When you submit, a mentor checks it against the criteria below.',
        );
      case TaskStatus.locked:
        return NoticeCard(icon: Icons.lock_outline_rounded, title: 'Locked', body: task.statusNote ?? 'Finish the earlier tasks first.');
    }
  }
}
