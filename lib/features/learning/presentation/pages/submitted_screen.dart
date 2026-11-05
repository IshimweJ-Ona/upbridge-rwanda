// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// L5 · Submitted for review. If the (simulated) approval lands while this
/// screen is open, a success card slides in.
class SubmittedScreen extends ConsumerWidget {
  const SubmittedScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final task = data.task(taskId);
    final approved = task.status == TaskStatus.approved;
    final isJean = data.user?.id == 'jean';
    final mentor = isJean ? 'Alice' : 'A mentor';

    return DetailPage(
      title: '',
      closeIcon: true,
      backFallback: '/home',
      onBack: () => context.go('/home'),
      footer: [
        AppButton('Back to home', onPressed: () => context.go('/home')),
        AppButton('View my path', variant: ButtonVariant.secondary, onPressed: () => context.go('/learn')),
      ],
      children: [
        SuccessBlock(
          eyebrow: 'Task ${task.number} · sent',
          title: 'Submitted for review',
          body: isJean
              ? '$mentor usually checks resubmissions the same day. We’ll let you know as soon as she does.'
              : '$mentor reviews your work within 48 hours. We’ll text you when it’s ready.',
        ),
        AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (child, a) => SizeTransition(
            sizeFactor: a,
            alignment: Alignment.topCenter,
            child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: child)),
          ),
          child: approved
              ? Padding(
                  key: const ValueKey('approved'),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SurfaceCard(
                    accentEdge: AppColors.successText,
                    onTap: () => context.push('/task-feedback/$taskId'),
                    child: Row(
                      children: [
                        const SuccessMark(size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Approved just now', style: AppText.bodyMStrong),
                              Text('All criteria met. Tap to read the review.', style: AppText.bodyS),
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
        KeyValueTable([
          ('Task', task.title),
          ('Attempt', isJean ? '2 (resubmission)' : '1'),
          ('Sent', 'Sat 17 Oct · 10:05'),
          ('Reviewer', isJean ? 'Alice Uwimana' : 'Assigned within 24 h'),
        ]),
        const SectionLabel('What happens next'),
        SurfaceCard(
          child: TimelineList(
            events: [
              const TimelineEvent('Submitted', 'SAT 17 OCT · 10:05', detail: 'Your links and note are with your mentor'),
              TimelineEvent(
                'Mentor review',
                approved ? 'SAT 17 OCT · 16:40' : (isJean ? 'USUALLY THE SAME DAY' : 'WITHIN 48 H'),
                detail: 'Checked against the ${task.criteria.length} criteria',
                current: !approved,
                done: approved,
              ),
              TimelineEvent(
                'Added to your portfolio',
                approved ? 'READY' : 'WHEN APPROVED',
                detail: 'Approved work becomes evidence employers can check',
                done: false,
                current: approved,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
