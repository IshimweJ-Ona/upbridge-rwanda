// M5 My mentorship: the signed-in youth's upcoming, requested and past sessions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/shared.dart';

class MyMentorshipScreen extends ConsumerWidget {
  const MyMentorshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(mySessionsProvider);
    final groups = MySessionGroups(sessionsAsync.value ?? const <Session>[]);

    return DetailPage(
      title: 'My mentorship',
      backFallback: '/mentors',
      children: [
        if (!sessionsAsync.hasValue && sessionsAsync.hasError)
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your sessions',
            body: mentorshipErrorText(sessionsAsync.error!),
            action: 'Try again',
            onAction: () => ref.invalidate(mySessionsProvider),
          )
        else if (!sessionsAsync.hasValue)
          const Shimmer(child: SkeletonBox(height: 280, radius: Radii.lg))
        else if (groups.isEmpty)
          EmptyState(
            icon: Icons.event_outlined,
            title: 'No sessions yet',
            body: 'Request a session and it will show up here.',
            action: 'Find a mentor',
            onAction: () => context.go('/mentors'),
          )
        else ...[
          if (groups.upcoming.isNotEmpty) ...[
            const SectionLabel('Upcoming'),
            for (final session in groups.upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UpcomingCard(session: session),
              ),
          ],
          if (groups.requests.isNotEmpty) ...[
            const SectionLabel('Requests'),
            ListGroup(
              children: [
                for (final session in groups.requests)
                  _RequestRow(session: session),
              ],
            ),
          ],
          if (groups.past.isNotEmpty) ...[
            const SectionLabel('Past'),
            ListGroup(
              children: [
                for (final session in groups.past)
                  ListRow(
                    leading: AppAvatar(
                      initialsOf(session.mentorName),
                      size: 36,
                    ),
                    title: session.topic,
                    meta: '${session.day} · ${session.mentorName}',
                    trailing: const StatusBadge('Done'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const NoticeCard(
            icon: Icons.info_outline_rounded,
            title: 'Can’t make it?',
            body: 'Cancel at least 12 hours before so your mentor can offer the slot to someone else.',
          ),
        ],
      ],
    );
  }
}

/// Confirms, runs the action, then reports the real outcome in a toast.
Future<void> _confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String doneMessage,
  required Future<void> Function() action,
}) async {
  final confirmed = await showAppDialog(
    context,
    title: title,
    body: body,
    confirmLabel: confirmLabel,
    cancelLabel: 'Keep it',
    destructive: true,
  );
  if (!confirmed) return;
  try {
    await action();
    if (context.mounted) showToast(context, doneMessage);
  } catch (error) {
    if (!context.mounted) return;
    showToast(
      context,
      mentorshipErrorText(error),
      icon: Icons.error_outline_rounded,
      tone: Tone.danger,
    );
  }
}

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(sessionActionsProvider.notifier);
    final busy = ref.watch(sessionActionsProvider).contains(session.id);
    final dayParts = session.day.split(' ');
    final hasLink = session.link.isNotEmpty;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session.startsAt != null && dayParts.length >= 2) ...[
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sunken,
                    borderRadius: Radii.rMd,
                  ),
                  child: Column(
                    children: [
                      Text(dayParts[0], style: AppText.caption),
                      Text(dayParts[1], style: AppText.titleM),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.topic, style: AppText.titleS),
                    const SizedBox(height: 2),
                    Text(
                      '${session.mentorName} · ${session.time} · ${session.mode}',
                      style: AppText.bodyS,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const StatusBadge('Confirmed', tone: Tone.success),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  hasLink ? 'Join on Google Meet' : 'Link coming soon',
                  size: ButtonSize.medium,
                  onPressed: hasLink
                      ? () => openLink(context, session.link)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                'Cancel',
                variant: ButtonVariant.secondary,
                size: ButtonSize.medium,
                expand: false,
                loading: busy,
                onPressed: busy
                    ? null
                    : () => _confirmAction(
                        context,
                        title: 'Cancel this session?',
                        body: 'Your mentor will no longer expect you.',
                        confirmLabel: 'Cancel session',
                        doneMessage: 'Session cancelled',
                        action: () => actions.cancel(session.id),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends ConsumerWidget {
  const _RequestRow({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(sessionActionsProvider.notifier);
    final busy = ref.watch(sessionActionsProvider).contains(session.id);
    final pending = session.state == SessionState.requested;

    return ListRow(
      leading: AppAvatar(initialsOf(session.mentorName), size: 36),
      title: session.topic,
      meta: pending
          ? '${session.day} · ${session.time} · tap to withdraw'
          : '${session.day} · ${session.time}',
      trailing: pending
          ? const StatusBadge('Pending', tone: Tone.info)
          : const StatusBadge('Declined', tone: Tone.danger),
      chevron: false,
      onTap: pending && !busy
          ? () => _confirmAction(
              context,
              title: 'Withdraw this request?',
              body: 'It will be removed and your mentor will not see it.',
              confirmLabel: 'Withdraw',
              doneMessage: 'Request withdrawn',
              action: () => actions.withdraw(session.id),
            )
          : null,
    );
  }
}
