// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/learning/presentation/providers/learn_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/shared/shared.dart';

/// L5 · Task submitted. Shows stage progress; if the (simulated) approval
/// lands while this screen is open, an approval card slides in.
class SubmittedScreen extends ConsumerWidget {
  const SubmittedScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final task = data.task(taskId);
    final approved = task.status == TaskStatus.approved;
    final stageTasks = data.tasks.where((t) => t.stage == task.stage).toList();
    final stageTitle = SampleData.stages.where((s) => s.number == task.stage).map((s) => s.title).firstOrNull ?? 'Stage ${task.stage}';

    return DetailPage(
      title: '',
      closeIcon: true,
      backFallback: '/learn',
      onBack: () => context.go('/learn'),
      footer: [
        AppButton('Continue learning', onPressed: () => context.go('/learn')),
      ],
      children: [
        const SizedBox(height: 32),
        const Center(child: SuccessMark(size: 72)),
        const SizedBox(height: 20),
        Text(approved ? 'Task approved!' : 'Task submitted!', style: AppText.titleL, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          approved
              ? 'Your “${task.title}” work met every criterion. Your progress has been updated.'
              : 'Your “${task.title}” work is with a mentor for review. Your progress updates as soon as it is approved.',
          style: AppText.bodyM,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (child, a) => SizeTransition(
            sizeFactor: a,
            alignment: Alignment.topCenter,
            child: FadeTransition(opacity: a, child: child),
          ),
          child: approved
              ? Padding(
                  key: const ValueKey('approved'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SurfaceCard(
                    accentEdge: AppColors.successText,
                    onTap: () => context.push('/task-feedback/$taskId'),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.successText),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Approved just now', style: AppText.bodyMStrong),
                              Text('Tap to read the mentor review.', style: AppText.bodyS),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey('waiting'), width: double.infinity),
        ),
        _StageProgressCard(title: stageTitle, tasks: stageTasks),
      ],
    );
  }
}

class _StageProgressCard extends StatelessWidget {
  const _StageProgressCard({required this.title, required this.tasks});

  final String title;
  final List<LearningTask> tasks;

  @override
  Widget build(BuildContext context) {
    final percent = approvedPercent(tasks);
    final approved = tasks.where((t) => t.status == TaskStatus.approved).length;
    final inReview = tasks.where((t) => t.status == TaskStatus.inReview).length;
    final left = tasks.length - approved;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learning progress', style: AppText.bodyMStrong),
                    Text(title, style: AppText.caption),
                  ],
                ),
              ),
              StatusBadge('$percent% complete', tone: Tone.success),
            ],
          ),
          const SizedBox(height: 12),
          ProgressLine(percent / 100, color: AppColors.successText),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$approved of ${tasks.length} tasks approved${inReview > 0 ? ' · $inReview in review' : ''}',
                  style: AppText.caption,
                ),
              ),
              Text(left == 1 ? '1 task left' : '$left tasks left', style: AppText.bodySStrong),
            ],
          ),
        ],
      ),
    );
  }
}
