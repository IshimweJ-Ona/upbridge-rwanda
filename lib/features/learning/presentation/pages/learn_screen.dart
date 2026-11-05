// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// L1 · Learning path with three stages.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final approved = data.approvedCount;
    final total = data.tasks.length;
    final currentStage = data.currentTask?.stage ?? 1;
    final hasMentor = !data.isFirstDay;

    return PageFrame(
      largeTitle: 'Learn',
      eyebrow: 'Your path',
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 800)),
      children: [
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconTile(Icons.code_rounded, tone: Tone.accent, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(SampleData.pathTitle, style: AppText.titleS),
                        const SizedBox(height: 2),
                        Text('Based on freeCodeCamp Responsive Web Design and MDN', style: AppText.bodyS),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MonoLabel('$approved of $total tasks approved · Stage $currentStage of ${SampleData.stages.length}'),
              const SizedBox(height: 8),
              ProgressLine(total == 0 ? 0 : approved / total),
              if (hasMentor) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 4),
                ListRow(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  leading: const AppAvatar('AU', tone: Tone.accent, size: 32),
                  title: 'Alice Uwimana',
                  subtitle: 'Your mentor · replies in about 1.4 days',
                  dense: true,
                  onTap: () => context.push('/mentor/alice'),
                ),
              ],
            ],
          ),
        ),
        for (final stage in SampleData.stages)
          _StageSection(
            stage: stage,
            tasks: data.tasks.where((t) => t.stage == stage.number).toList(),
            initiallyOpen: stage.number == currentStage,
          ),
        const SectionLabel('Other paths'),
        ListGroup(
          children: [
            for (final p in SampleData.otherPaths)
              ListRow(
                leading: IconTile(p.icon),
                title: p.title,
                subtitle: p.note,
                meta: p.progress,
                onTap: () => showToast(context, 'During the pilot you follow one path at a time.', icon: Icons.info_outline_rounded, tone: Tone.info),
              ),
          ],
        ),
      ],
    );
  }
}

class _StageSection extends StatefulWidget {
  const _StageSection({required this.stage, required this.tasks, required this.initiallyOpen});

  final PathStage stage;
  final List<LearningTask> tasks;
  final bool initiallyOpen;

  @override
  State<_StageSection> createState() => _StageSectionState();
}

class _StageSectionState extends State<_StageSection> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final s = widget.stage;
    final done = widget.tasks.where((t) => t.status == TaskStatus.approved).length;
    final allLocked = widget.tasks.every((t) => t.status == TaskStatus.locked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Pressable(
          onTap: () => setState(() => _open = !_open),
          scale: 0.99,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MonoLabel('Stage ${s.number} · $done of ${s.taskCount} approved', color: allLocked ? AppColors.textDisabled : AppColors.textMuted),
                      const SizedBox(height: 4),
                      Text(s.title, style: AppText.titleS.copyWith(color: allLocked ? AppColors.textMuted : AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(s.summary, style: AppText.bodyS),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: Motion.base,
                  curve: Motion.curve,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.slow,
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: _open
              ? ListGroup(
                  children: [
                    for (final t in widget.tasks)
                      TaskRow(
                        task: t,
                        highlight: t.status == TaskStatus.changesRequested || t.status == TaskStatus.available,
                        onTap: () => context.push('/task/${t.id}'),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
