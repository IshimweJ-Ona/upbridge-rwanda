// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/features/mentor_workspace/presentation/widgets/mentor_widgets.dart';

/// MR1 · Review queue.
class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  static const _filters = ['All', 'Due soon', 'Re-checks', 'First attempts'];
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    if (data.user?.isNewMentor ?? false) {
      return const PageFrame(
        largeTitle: 'Reviews',
        eyebrow: 'Nothing assigned yet',
        children: [
          SizedBox(height: 24),
          EmptyState(icon: Icons.inbox_outlined, title: 'Your queue is empty', body: 'Submissions from your mentees appear here, oldest deadline first.'),
        ],
      );
    }
    final queue = data.queue.where((s) {
      return switch (_filter) {
        'Due soon' => s.urgent,
        'Re-checks' => s.isRecheck,
        'First attempts' => !s.isRecheck,
        _ => true,
      };
    }).toList();
    final reviewed = data.submissions.where((s) => s.reviewed).toList();

    return PageFrame(
      largeTitle: 'Reviews',
      eyebrow: '${data.reviewedCount} reviewed · ${data.queue.length} waiting',
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 800)),
      children: [
        const SizedBox(height: 14),
        ChipBar(options: _filters, selected: _filter, padding: EdgeInsets.zero, onSelected: (v) => setState(() => _filter = v)),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.base,
          child: queue.isEmpty
              ? const EmptyState(
                  key: ValueKey('empty'),
                  icon: Icons.task_alt_rounded,
                  title: 'Nothing here',
                  body: 'New submissions arrive as your mentees finish tasks.',
                )
              : ListGroup(key: ValueKey(_filter), children: [for (final s in queue) QueueRow(submission: s)]),
        ),
        const SizedBox(height: 14),
        const NoticeCard(
          tone: Tone.info,
          icon: Icons.timer_outlined,
          title: 'Aim to reply within 48 hours',
          body: 'Your median this month is 1.2 days. Re-checks are usually quick.',
        ),
        if (reviewed.isNotEmpty) ...[
          const SectionLabel('Sent today'),
          ListGroup(
            children: [
              for (final s in reviewed)
                ListRow(
                  leading: AppAvatar(s.youthInitials, tone: Tone.success, size: 36),
                  title: s.youthName,
                  subtitle: 'Task ${s.taskNumber} · ${s.taskTitle}',
                  trailing: const StatusBadge('Sent', tone: Tone.success),
                  onTap: () => context.push('/m-submission/${s.id}'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
