// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// M5 · My mentorship — next session, requests, history and reviews.
class MyMentorshipScreen extends ConsumerWidget {
  const MyMentorshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final m = data.mentor('alice');
    final mine = data.mySessions;
    final upcoming = mine.where((s) => s.state == SessionState.upcoming).toList();
    final requested = mine.where((s) => s.state == SessionState.requested).toList();
    final past = mine.where((s) => s.state == SessionState.done).toList();
    final reviews = data.reviews;

    return DetailPage(
      title: 'My mentorship',
      backFallback: '/mentors',
      children: [
        const SizedBox(height: 8),
        SurfaceCard(
          onTap: () => context.push('/mentor/${m.id}', extra: 'mentor-alice-yours'),
          child: Row(
            children: [
              Hero(tag: 'mentor-alice-yours', child: AppAvatar(m.initials, tone: m.tone, size: 52)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MonoLabel('Your mentor since 8 Oct'),
                    const SizedBox(height: 4),
                    Text(m.name, style: AppText.titleS),
                    Text('${m.title} · ${m.city}', style: AppText.bodyS),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatStrip([
          StatItem('', 'Tasks reviewed', countTo: reviews.length),
          StatItem('', 'Sessions held', countTo: past.length),
          StatItem(m.replyTime, 'Median reply'),
        ]),
        const SectionLabel('Next session'),
        if (upcoming.isEmpty)
          EmptyState(
            icon: Icons.event_outlined,
            title: 'No session booked',
            body: '${m.name.split(' ').first} is free ${m.availability}.',
            action: 'Request a session',
            onAction: () => context.push('/mentor-request/${m.id}'),
          )
        else
          for (final s in upcoming) _NextSession(session: s),
        if (requested.isNotEmpty) ...[
          const SectionLabel('Waiting for a reply'),
          ListGroup(
            children: [
              for (final s in requested)
                ListRow(
                  leading: const IconTile(Icons.hourglass_top_rounded, tone: Tone.warning),
                  title: s.topic,
                  meta: '${s.day} · ${s.time}',
                  trailing: const StatusBadge('Requested', tone: Tone.warning),
                ),
            ],
          ),
        ],
        if (past.isNotEmpty) ...[
          const SectionLabel('Past sessions'),
          ListGroup(
            children: [
              for (final s in past)
                ListRow(
                  leading: const IconTile(Icons.check_rounded, tone: Tone.success),
                  title: s.topic,
                  meta: '${s.day} · ${s.time} · ${s.mode}',
                ),
            ],
          ),
        ],
        if (reviews.isNotEmpty) ...[
          SectionLabel('Reviews from ${m.name.split(' ').first}'),
          ListGroup(
            children: [
              for (final r in reviews)
                ListRow(
                  leading: IconTile(r.approved ? Icons.verified_outlined : Icons.edit_note_rounded, tone: r.approved ? Tone.success : Tone.warning),
                  title: data.task(r.taskId).title,
                  meta: '${r.when} · ${r.approved ? 'approved' : 'changes requested'}',
                  onTap: () => context.push('/task-feedback/${r.taskId}'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NextSession extends StatelessWidget {
  const _NextSession({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.inverse, borderRadius: Radii.rXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam_outlined, size: 18, color: AppColors.brandOrange),
              const SizedBox(width: 8),
              Expanded(child: MonoLabel('${session.day} · ${session.time} · ${session.mode}', color: AppColors.brandOrange)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: Radii.rSm),
                child: Text('In 3 days', style: AppText.caption.copyWith(color: AppColors.textInverse)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(session.topic, style: AppText.titleM.copyWith(color: AppColors.textInverse)),
          const SizedBox(height: 4),
          Text('With ${session.mentorName} · 30 minutes', style: AppText.bodyS.copyWith(color: const Color(0xD9FFFFFF))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  'Join on Google Meet',
                  variant: ButtonVariant.onDark,
                  size: ButtonSize.medium,
                  leadingIcon: Icons.videocam_rounded,
                  onPressed: () => openLink(context, session.link),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                'Reschedule',
                variant: ButtonVariant.outlineOnDark,
                size: ButtonSize.medium,
                expand: false,
                onPressed: () => context.push('/mentor-request/${session.mentorId}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
