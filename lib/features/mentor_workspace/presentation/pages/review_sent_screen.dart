// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// MR4 · Review sent.
class ReviewSentScreen extends ConsumerWidget {
  const ReviewSentScreen({super.key, required this.submissionId});

  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final s = data.submission(submissionId);
    final approved = GoRouterState.of(context).uri.queryParameters['approved'] != 'false';
    final next = data.queue.isEmpty ? null : data.queue.first;
    final first = s?.youthName.split(' ').first ?? 'They';
    final n = s == null ? 0 : data.task(s.taskId).criteria.length;

    return DetailPage(
      title: '',
      closeIcon: true,
      backFallback: '/m/reviews',
      onBack: () => context.go('/m/reviews'),
      footer: [
        AppButton('Back to review queue', onPressed: () => context.go('/m/reviews')),
        if (next != null)
          AppButton(
            'Next: ${next.youthName.split(' ').first} · Task ${next.taskNumber}',
            variant: ButtonVariant.secondary,
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.pushReplacement('/m-submission/${next.id}'),
          ),
      ],
      children: [
        SuccessBlock(
          eyebrow: 'Review sent',
          title: approved ? '$first’s work is approved' : 'Changes requested',
          body: approved
              ? '$first gets an SMS and a notification now. The approved work goes into their portfolio as evidence employers can check.'
              : '$first sees your notes now and can resubmit. Re-checks land back in your queue.',
        ),
        if (s != null)
          KeyValueTable([
            ('Mentee', s.youthName),
            ('Task', 'Task ${s.taskNumber} · ${s.taskTitle}'),
            ('Result', approved ? 'Approved · $n of $n met' : 'Changes requested'),
            ('Turnaround', s.isRecheck ? '6 h 35 min' : 'Within 48 h'),
          ]),
        const SizedBox(height: 16),
        StatStrip([
          StatItem('', 'Reviewed in total', countTo: data.reviewedCount),
          StatItem('', 'Still waiting', countTo: data.queue.length),
        ]),
      ],
    );
  }
}
