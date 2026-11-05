// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/features/mentor_workspace/presentation/widgets/mentor_widgets.dart';

/// MH1 · Mentor home (Alice) and MH0 · newly verified mentor (Claudine).
class MentorHomeScreen extends ConsumerWidget {
  const MentorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final user = data.user;
    if (user == null) return const SizedBox.shrink();
    if (user.isNewMentor) return _FirstDay(name: user.firstName);

    final queue = data.queue;
    final requests = data.mentorSessions.where((s) => s.state == SessionState.requested).toList();
    final upcoming = data.mentorSessions.where((s) => s.state == SessionState.upcoming).toList();
    final urgent = queue.where((s) => s.urgent).toList();
    final first = urgent.isNotEmpty ? urgent.first : (queue.isEmpty ? null : queue.first);

    return PageFrame(
      largeTitle: 'Muraho, ${user.firstName}',
      eyebrow: '${SampleData.today} · Mentor',
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 800)),
      children: [
        const SizedBox(height: 14),
        StatStrip([
          StatItem('', 'Reviews sent this month', countTo: 9 + (data.reviewedCount - 46)),
          const StatItem('1.2 d', 'Median reply'),
          StatItem('', 'Sessions held', countTo: data.mentorSessions.where((s) => s.state == SessionState.done).length + 2),
        ]),
        const SizedBox(height: 18),
        if (first != null)
          NextStepCard(
            eyebrow: first.urgent ? 'Due soonest' : 'Next in queue',
            icon: first.urgent ? Icons.alarm_rounded : Icons.rate_review_outlined,
            title: '${first.youthName.split(' ').first}’s Task ${first.taskNumber} · ${first.dueLabel.toLowerCase()}',
            body: '${first.taskTitle} · ${first.isRecheck ? 're-check after your feedback' : 'first attempt'}.',
            action: 'Start review',
            onAction: () => context.push('/m-submission/${first.id}'),
          )
        else
          const EmptyState(icon: Icons.task_alt_rounded, title: 'Queue clear', body: 'Nice work. New submissions appear here as your mentees finish tasks.'),
        SectionLabel('Review queue · ${queue.length}', action: 'See all', onAction: () => context.go('/m/reviews')),
        if (queue.isEmpty)
          const NoticeCard(icon: Icons.inbox_outlined, title: 'Nothing waiting')
        else
          ListGroup(children: [for (final s in queue.take(3)) QueueRow(submission: s)]),
        if (requests.isNotEmpty) ...[
          SectionLabel('Session requests · ${requests.length}', action: 'Respond', onAction: () => context.go('/m/sessions')),
          ListGroup(
            children: [
              for (final s in requests)
                ListRow(
                  leading: AppAvatar(initialsOf(s.youthName), size: 36),
                  title: '${s.youthName} · ${s.topic}',
                  meta: '${s.day} · ${s.time}',
                  trailing: const StatusBadge('New', tone: Tone.warning),
                  onTap: () => context.go('/m/sessions'),
                ),
            ],
          ),
        ],
        SectionLabel('Upcoming sessions', action: 'All sessions', onAction: () => context.go('/m/sessions')),
        ListGroup(
          children: [
            for (final s in upcoming)
              ListRow(
                leading: const IconTile(Icons.videocam_outlined, tone: Tone.info),
                title: '${s.youthName} · ${s.topic}',
                meta: '${s.day} · ${s.time} · ${s.mode}',
                onTap: () => context.go('/m/sessions'),
              ),
          ],
        ),
      ],
    );
  }
}

class _FirstDay extends StatelessWidget {
  const _FirstDay({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      largeTitle: 'Muraho, $name',
      eyebrow: '${SampleData.today} · Verified yesterday',
      children: [
        const SizedBox(height: 18),
        const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Nothing to review yet',
          body: 'This week you’ll be matched with up to 5 youth on the Data analysis path. Their work appears here when they submit.',
        ),
        const SectionLabel('Get ready · 1 of 4 done'),
        ListGroup(
          children: [
            const _Prep(done: true, title: 'Verified by UpBridge', subtitle: 'ID, work history and reference checked'),
            _Prep(title: 'Set your availability', subtitle: 'Two hours a week is enough', onTap: () => context.go('/m/profile')),
            _Prep(title: 'Add your expertise', subtitle: 'Helps us match the right youth to you', onTap: () => context.go('/m/profile')),
            _Prep(
              title: 'Read the review guide',
              subtitle: '5 minutes · how to give useful feedback',
              onTap: () => showAppSheet<void>(context, title: 'Review guide', builder: (_) => const ReviewGuide()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const NoticeCard(
          tone: Tone.info,
          icon: Icons.lightbulb_outline_rounded,
          title: 'How reviews work',
          body: 'Each task has 3–4 criteria. Mark each one Met, Partly or Not yet, and add a short, specific note.',
        ),
      ],
    );
  }
}

class _Prep extends StatelessWidget {
  const _Prep({required this.title, required this.subtitle, this.done = false, this.onTap});

  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppColors.successText : AppColors.surface,
          border: done ? null : Border.all(color: AppColors.borderStrong, width: 1.4),
        ),
        child: done ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary) : null,
      ),
      title: title,
      subtitle: subtitle,
      titleStyle: AppText.bodyMStrong.copyWith(decoration: done ? TextDecoration.lineThrough : null, color: done ? AppColors.textMuted : AppColors.textPrimary),
      onTap: onTap,
    );
  }
}

class ReviewGuide extends StatelessWidget {
  const ReviewGuide({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = [
      ('Be specific', 'Point to the exact line, screen size or element. “Footer overflows below 400 px” beats “layout needs work”.'),
      ('Say what to keep', 'Name one thing they did well so they repeat it.'),
      ('One fix at a time', 'If several things need work, ask for the most important change first.'),
      ('Reply within 48 hours', 'Fast feedback keeps youth moving. Re-checks are usually quick.'),
    ];
    return Column(
      children: [
        for (final t in tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.successText)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(t.$1, style: AppText.bodyMStrong), Text(t.$2, style: AppText.bodyS)],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
