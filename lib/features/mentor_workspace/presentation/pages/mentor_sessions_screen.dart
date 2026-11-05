// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/features/mentor_workspace/presentation/widgets/mentor_widgets.dart';

/// MS1 · Sessions — requests to answer, upcoming and past.
class MentorSessionsScreen extends ConsumerWidget {
  const MentorSessionsScreen({super.key});

  Future<void> _decline(BuildContext context, WidgetRef ref, Session s) async {
    final first = s.youthName.split(' ').first;
    final ok = await showAppDialog(
      context,
      title: 'Decline $first’s request?',
      body: '$first will be asked to pick another time from your availability.',
      confirmLabel: 'Decline',
      destructive: true,
      icon: Icons.event_busy_outlined,
    );
    if (!ok) return;
    ref.read(appStoreProvider.notifier).respondToSession(s.id, accept: false);
    if (context.mounted) showToast(context, 'Declined — $first can choose another time', icon: Icons.event_busy_outlined, tone: Tone.warning);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final mine = data.mentorSessions;
    final requests = mine.where((s) => s.state == SessionState.requested).toList();
    final upcoming = mine.where((s) => s.state == SessionState.upcoming).toList();
    final past = mine.where((s) => s.state == SessionState.done).toList();
    final isNew = data.user?.isNewMentor ?? false;

    return PageFrame(
      largeTitle: 'Sessions',
      eyebrow: isNew ? 'Set your availability first' : 'Tue and Thu · 18:00–20:00',
      children: [
        if (isNew)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(icon: Icons.event_available_outlined, title: 'No sessions yet', body: 'Mentees can request a session once you’ve set your availability.'),
          ),
        if (requests.isNotEmpty) ...[
          SectionLabel('Requests · ${requests.length}'),
          for (final s in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MentorSessionCard(
                session: s,
                actions: [
                  AppButton(
                    'Accept',
                    size: ButtonSize.medium,
                    onPressed: () {
                      ref.read(appStoreProvider.notifier).respondToSession(s.id, accept: true);
                      showToast(context, 'Confirmed — ${s.youthName.split(' ').first} gets the Meet link by SMS');
                    },
                  ),
                  AppButton('Decline', size: ButtonSize.medium, variant: ButtonVariant.secondary, onPressed: () => _decline(context, ref, s)),
                ],
              ),
            ),
        ],
        if (upcoming.isNotEmpty) ...[
          const SectionLabel('Upcoming'),
          for (final s in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MentorSessionCard(
                session: s,
                actions: [
                  AppButton('Join on Google Meet', size: ButtonSize.medium, leadingIcon: Icons.videocam_rounded, onPressed: () => openLink(context, s.link)),
                ],
              ),
            ),
        ],
        if (past.isNotEmpty) ...[
          const SectionLabel('Past'),
          ListGroup(
            children: [
              for (final s in past)
                ListRow(
                  leading: AppAvatar(initialsOf(s.youthName), tone: Tone.success, size: 36),
                  title: s.youthName,
                  subtitle: s.topic,
                  meta: '${s.day} · ${s.time}',
                ),
            ],
          ),
        ],
      ],
    );
  }
}
