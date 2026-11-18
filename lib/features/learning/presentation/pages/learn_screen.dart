// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/learning/presentation/providers/learn_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/shared/shared.dart';

/// L1 · Skill path: overall progress, then each stage with its tasks.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final tasks = data.tasks;
    final currentStage = data.currentTask?.stage ?? 1;

    return PageFrame(
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 800)),
      children: [
        Text(SampleData.pathTitle, style: AppText.titleM, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Based on freeCodeCamp Responsive Web Design and MDN', style: AppText.caption, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const NoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Demo preview',
          body: 'This path uses sample data, not live account records.',
        ),
        const SizedBox(height: 12),
        _PathProgressCard(tasks: tasks, currentStage: currentStage),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No tasks yet',
              body: 'Your learning path appears here once it is set up.',
            ),
          ),
        for (final stage in SampleData.stages)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _StageCard(
              stage: stage,
              tasks: tasks.where((t) => t.stage == stage.number).toList(),
              isCurrent: stage.number == currentStage,
            ),
          ),
      ],
    );
  }
}

class _PathProgressCard extends StatelessWidget {
  const _PathProgressCard({required this.tasks, required this.currentStage});

  final List<LearningTask> tasks;
  final int currentStage;

  @override
  Widget build(BuildContext context) {
    final percent = approvedPercent(tasks);
    final approved = tasks.where((t) => t.status == TaskStatus.approved).length;
    final unlocked = SampleData.stages.where((s) => stageStateOf(tasks.where((t) => t.stage == s.number).toList()) != StageState.locked).length;

    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.sunken, shape: BoxShape.circle),
            child: Text('$percent%', style: AppText.titleS),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stage $currentStage progress', style: AppText.bodyMStrong),
                const SizedBox(height: 2),
                Text('$approved of ${tasks.length} tasks approved · $unlocked of ${SampleData.stages.length} stages unlocked', style: AppText.caption),
                const SizedBox(height: 8),
                ProgressLine(percent / 100, color: AppColors.brandOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage, required this.tasks, required this.isCurrent});

  final PathStage stage;
  final List<LearningTask> tasks;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final state = stageStateOf(tasks);
    final locked = state == StageState.locked;
    final badge = switch (state) {
      StageState.done => ('STAGE ${stage.number} · DONE', Tone.success),
      StageState.inProgress => ('STAGE ${stage.number} · IN PROGRESS', Tone.info),
      StageState.locked => ('STAGE ${stage.number} · LOCKED', Tone.neutral),
    };

    return AnimatedContainer(
      duration: Motion.base,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: locked ? AppColors.sunken.withValues(alpha: 0.6) : AppColors.surface,
        borderRadius: Radii.rLg,
        border: Border.all(
          color: isCurrent && !locked ? AppColors.textPrimary : AppColors.borderSubtle,
          width: isCurrent && !locked ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusBadge(badge.$1, tone: badge.$2),
              const Spacer(),
              if (isCurrent && !locked)
                Text('Current stage', style: AppText.caption.copyWith(color: AppColors.brandOrange, fontWeight: FontWeight.w600))
              else if (locked)
                const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textDisabled),
            ],
          ),
          const SizedBox(height: 10),
          Text(stage.title, style: AppText.titleS.copyWith(color: locked ? AppColors.textMuted : AppColors.textPrimary)),
          if (locked || tasks.isEmpty) ...[
            const SizedBox(height: 4),
            Text(stage.summary, style: AppText.bodyS.copyWith(color: AppColors.textMuted)),
          ] else ...[
            const SizedBox(height: 10),
            for (final t in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PathTaskRow(task: t, onTap: () => context.push('/task/${t.id}')),
              ),
          ],
        ],
      ),
    );
  }
}

/// One task inside a stage card: done, current or locked.
class _PathTaskRow extends StatelessWidget {
  const _PathTaskRow({required this.task, required this.onTap});

  final LearningTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    final locked = status == TaskStatus.locked;
    final (bg, border, fg, icon) = switch (status) {
      TaskStatus.approved => (AppColors.successSubtle, AppColors.successText.withValues(alpha: 0.25), AppColors.successText, Icons.check_circle_outline_rounded),
      TaskStatus.available => (AppColors.infoSubtle, AppColors.infoText.withValues(alpha: 0.3), AppColors.infoText, Icons.play_circle_outline_rounded),
      TaskStatus.changesRequested => (AppColors.warningSubtle, AppColors.warningText.withValues(alpha: 0.3), AppColors.warningText, Icons.edit_note_rounded),
      TaskStatus.inReview => (AppColors.infoSubtle, AppColors.infoText.withValues(alpha: 0.3), AppColors.infoText, Icons.hourglass_top_rounded),
      TaskStatus.locked => (AppColors.surface, AppColors.borderSubtle, AppColors.textMuted, Icons.lock_outline_rounded),
    };
    final current = status == TaskStatus.available || status == TaskStatus.changesRequested;

    return Semantics(
      button: !locked,
      label: '${task.title}, ${status.label}',
      excludeSemantics: true,
      child: Pressable(
        onTap: locked ? null : onTap,
        scale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: Radii.rMd, border: Border.all(color: border)),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  style: (current ? AppText.bodySStrong : AppText.bodyS).copyWith(color: locked ? AppColors.textMuted : fg),
                ),
              ),
              if (status == TaskStatus.changesRequested || status == TaskStatus.inReview) ...[
                const SizedBox(width: 8),
                StatusBadge(status == TaskStatus.changesRequested ? 'Fix 1' : status.label, tone: status.tone),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
