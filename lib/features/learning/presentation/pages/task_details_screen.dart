// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/core/utils/formatters.dart';
import 'package:upbridge/features/learning/presentation/providers/learn_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/shared/shared.dart';

/// L2 · Task detail, and the task-in-progress checklist once the youth starts it.
class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final task = data.task(taskId);
    final progress = ref.watch(taskProgressProvider.select((m) => m[task.id]));

    if (task.status == TaskStatus.available && progress != null) {
      return _InProgressView(task: task, progress: progress);
    }
    return _DetailView(task: task, review: data.latestReview(task.id), project: data.projectForTask(task.id));
  }
}

String _pathLabel() => SampleData.pathTitle.toUpperCase();

// ───────────────────────────── Task detail ─────────────────────────────

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.task, required this.review, required this.project});

  final LearningTask task;
  final Review? review;
  final Project? project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = task.brief.isEmpty ? task.summary : task.brief;

    return DetailPage(
      title: 'Task detail',
      backFallback: '/learn',
      footer: _footer(context, ref),
      children: [
        const SizedBox(height: 8),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(_pathLabel(), color: AppColors.infoText),
              const SizedBox(height: 6),
              Text(task.title, style: AppText.titleL),
              const SizedBox(height: 10),
              StatusBadge('${task.status.label} · ${task.duration.toLowerCase()}', tone: task.status.tone, icon: task.status.icon),
            ],
          ),
        ),
        if (task.status != TaskStatus.available) ...[
          const SizedBox(height: 12),
          _StatusNotice(task: task, review: review),
        ],
        const SectionLabel('About this task'),
        Text(brief, style: AppText.bodyM),
        if (task.criteria.isNotEmpty) ...[
          SectionLabel('How it’s reviewed · ${task.criteria.length} criteria'),
          SurfaceCard(
            child: Column(
              children: [
                for (var i = 0; i < task.criteria.length; i++) ...[
                  if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: AppColors.borderSubtle)),
                  _CriterionLine(index: i, criterion: task.criteria[i], verdict: _verdictFor(review, task.criteria[i].title)),
                ],
              ],
            ),
          ),
        ],
        if (task.resources.isNotEmpty) ...[
          const SectionLabel('Resources'),
          _ResourceList(resources: task.resources),
        ],
      ],
    );
  }

  static Verdict? _verdictFor(Review? review, String criterion) {
    for (final r in review?.results ?? const <CriterionResult>[]) {
      if (r.criterion == criterion) return r.verdict;
    }
    return null;
  }

  List<Widget> _footer(BuildContext context, WidgetRef ref) {
    switch (task.status) {
      case TaskStatus.available:
        return [
          AppButton(
            'Start task',
            icon: Icons.play_arrow_rounded,
            onPressed: () => ref.read(taskProgressProvider.notifier).start(task.id),
          ),
        ];
      case TaskStatus.changesRequested:
        return [
          AppButton('Resubmit your work', icon: Icons.upload_rounded, onPressed: () => context.push('/task-submit/${task.id}')),
          AppButton('See feedback', variant: ButtonVariant.secondary, onPressed: () => context.push('/task-feedback/${task.id}')),
        ];
      case TaskStatus.inReview:
        return [AppButton('Back to my path', variant: ButtonVariant.secondary, onPressed: () => context.go('/learn'))];
      case TaskStatus.approved:
        return [
          AppButton('See mentor review', onPressed: () => context.push('/task-feedback/${task.id}')),
          if (project != null)
            AppButton('View in portfolio', variant: ButtonVariant.secondary, onPressed: () => context.push('/project/${project!.id}')),
        ];
      case TaskStatus.locked:
        return [AppButton('Unlocks after Task ${task.number - 1}', leadingIcon: Icons.lock_outline_rounded, onPressed: null)];
    }
  }
}

class _CriterionLine extends StatelessWidget {
  const _CriterionLine({required this.index, required this.criterion, required this.verdict});

  final int index;
  final Criterion criterion;
  final Verdict? verdict;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 28, child: Text('0${index + 1}', style: AppText.dataMonoStrong.copyWith(color: AppColors.infoText))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(criterion.title, style: AppText.bodyMStrong),
              const SizedBox(height: 2),
              Text(criterion.detail, style: AppText.bodyS),
            ],
          ),
        ),
        if (verdict != null) ...[
          const SizedBox(width: 8),
          Icon(verdict!.icon, size: 20, color: verdict!.tone.foreground, semanticLabel: verdict!.label),
        ],
      ],
    );
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
        return NoticeCard(
          tone: Tone.warning,
          icon: Icons.edit_note_rounded,
          title: '$mentor requested 1 change',
          body: partly == null ? null : '${partly.criterion}: ${partly.note}',
        );
      case TaskStatus.inReview:
        return NoticeCard(tone: Tone.info, icon: Icons.hourglass_top_rounded, title: 'In review', body: task.statusNote);
      case TaskStatus.approved:
        return NoticeCard(tone: Tone.success, icon: Icons.verified_outlined, title: 'Approved by $mentor', body: task.statusNote);
      case TaskStatus.locked:
        return NoticeCard(icon: Icons.lock_outline_rounded, title: 'Locked', body: task.statusNote ?? 'Finish the earlier tasks first.');
      case TaskStatus.available:
        return const SizedBox.shrink();
    }
  }
}

class _ResourceList extends StatelessWidget {
  const _ResourceList({required this.resources});

  final List<Resource> resources;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in resources)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => openLink(context, r.url),
              child: Row(
                children: [
                  IconTile(_iconFor(r), tone: Tone.info, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: AppText.bodySStrong),
                        const SizedBox(height: 2),
                        Text('${r.source} · ${r.kind}', style: AppText.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.link, semanticLabel: 'Opens in browser'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static IconData _iconFor(Resource r) {
    final kind = r.kind.toLowerCase();
    if (kind.startsWith('tool')) return Icons.build_outlined;
    if (kind.startsWith('video')) return Icons.videocam_outlined;
    return Icons.description_outlined;
  }
}

// ───────────────────────────── Task in progress ─────────────────────────────

class _InProgressView extends ConsumerWidget {
  const _InProgressView({required this.task, required this.progress});

  final LearningTask task;
  final TaskProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklist = TaskChecklist(task, progress);
    final now = ref.watch(learningClockProvider)();
    final started = formatRelativeTime(progress.startedAt, now: now);
    final remaining = checklist.tickable - checklist.completed;

    return DetailPage(
      title: 'Task in progress',
      backFallback: '/learn',
      footer: [
        AppButton(
          'Submit task',
          icon: Icons.send_rounded,
          onPressed: checklist.readyToSubmit ? () => context.push('/task-submit/${task.id}') : null,
        ),
      ],
      footerNote: checklist.readyToSubmit
          ? null
          : Text(
              'Tick off ${remaining == 1 ? 'the last item' : 'the $remaining remaining items'} to submit.',
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
      children: [
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: StatusBadge('${checklist.completed} of ${checklist.total} complete', tone: Tone.info),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonoLabel(_pathLabel(), color: AppColors.infoText),
              const SizedBox(height: 6),
              Text(task.title, style: AppText.titleM),
              const SizedBox(height: 6),
              Text(
                started == 'just now'
                    ? 'You just started this task. Work through the checklist, then submit it for review.'
                    : 'You started this task $started. Finish the checklist, then submit it for review.',
                style: AppText.bodyS,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Progress', style: AppText.bodySStrong),
                  const Spacer(),
                  Text('${checklist.percent}%', style: AppText.bodySStrong.copyWith(color: AppColors.infoText)),
                ],
              ),
              const SizedBox(height: 6),
              ProgressLine(checklist.fraction, color: AppColors.infoText),
              const SizedBox(height: 16),
              Text('Checklist', style: AppText.bodySStrong),
              const SizedBox(height: 8),
              for (var i = 0; i < checklist.total; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChecklistItem(
                    label: checklist.steps[i],
                    state: checklist.isDone(i)
                        ? _StepState.done
                        : (i == checklist.currentIndex ? _StepState.current : _StepState.pending),
                    onTap: i < checklist.tickable ? () => ref.read(taskProgressProvider.notifier).toggle(task, i) : null,
                  ),
                ),
            ],
          ),
        ),
        if (task.resources.isNotEmpty) ...[
          const SectionLabel('Supporting resources'),
          _ResourceList(resources: task.resources),
        ],
      ],
    );
  }
}

enum _StepState { done, current, pending }

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.label, required this.state, this.onTap});

  final String label;
  final _StepState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (status, icon, color) = switch (state) {
      _StepState.done => ('Completed', Icons.check_circle_rounded, AppColors.infoText),
      _StepState.current => (onTap == null ? 'Ready when you are' : 'In progress', Icons.radio_button_checked_rounded, AppColors.infoText),
      _StepState.pending => ('Pending', Icons.radio_button_unchecked_rounded, AppColors.textDisabled),
    };

    return Semantics(
      checked: onTap == null ? null : state == _StepState.done,
      label: '$label, $status',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.99,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: Radii.rMd,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: Motion.fast,
                child: Icon(icon, key: ValueKey(state), size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.bodySStrong),
                    Text(status, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
