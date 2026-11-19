// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/features/mentor_workspace/presentation/providers/mentor_providers.dart';
import 'package:upbridge/features/mentor_workspace/presentation/widgets/mentor_widgets.dart';

/// MS1 · Sessions — requests to answer, upcoming and past (mentorSessions).
class MentorSessionsScreen extends ConsumerWidget {
  const MentorSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(mentorSessionsProvider);
    final profile = ref.watch(myMentorProfileProvider).value;
    final groups = MentorSessionGroups(sessionsAsync.value ?? const <Session>[]);
    final busy = ref.watch(mentorSessionActionsProvider);
    final actions = ref.read(mentorSessionActionsProvider.notifier);
    final link = profile?.meetingLink ?? '';

    return PageFrame(
      largeTitle: 'Sessions',
      eyebrow: profile == null || !profile.hasAvailability ? 'Set your availability first' : profile.availabilityLabel,
      onRefresh: () async => ref.invalidate(mentorSessionsProvider),
      children: [
        if (!sessionsAsync.hasValue && sessionsAsync.hasError)
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your sessions',
            body: mentorshipErrorText(sessionsAsync.error!),
            action: 'Try again',
            onAction: () => ref.invalidate(mentorSessionsProvider),
          )
        else if (!sessionsAsync.hasValue)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Shimmer(child: SkeletonBox(height: 280, radius: Radii.lg)),
          )
        else if (groups.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(icon: Icons.event_available_outlined, title: 'No sessions yet', body: 'Mentees can request a session once you’ve set your availability.'),
          )
        else ...[
          if (groups.requests.isNotEmpty) ...[
            SectionLabel('Requests · ${groups.requests.length}'),
            for (final s in groups.requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MentorSessionCard(
                  session: s,
                  actions: [
                    AppButton(
                      'Accept',
                      size: ButtonSize.medium,
                      loading: busy.contains(s.id),
                      onPressed: busy.contains(s.id)
                          ? null
                          : () => _run(
                                context,
                                () => actions.accept(s.id, meetingLink: link),
                                link.isEmpty
                                    ? 'Confirmed — add a meeting link in Profile so ${_first(s)} can join'
                                    : 'Confirmed — ${_first(s)} can now see the meeting link',
                              ),
                    ),
                    AppButton(
                      'Decline',
                      size: ButtonSize.medium,
                      variant: ButtonVariant.secondary,
                      onPressed: busy.contains(s.id) ? null : () => _decline(context, actions, s),
                    ),
                  ],
                ),
              ),
          ],
          if (groups.upcoming.isNotEmpty) ...[
            const SectionLabel('Upcoming'),
            for (final s in groups.upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MentorSessionCard(
                  session: s,
                  actions: [
                    if (s.link.isNotEmpty)
                      AppButton('Join on ${s.mode}', size: ButtonSize.medium, leadingIcon: Icons.videocam_rounded, onPressed: () => openLink(context, s.link)),
                    if (s.startsAt != null && s.startsAt!.isBefore(DateTime.now()))
                      AppButton(
                        'Mark as done',
                        size: ButtonSize.medium,
                        variant: ButtonVariant.secondary,
                        loading: busy.contains(s.id),
                        onPressed: busy.contains(s.id) ? null : () => _run(context, () => actions.complete(s.id), 'Marked as done'),
                      ),
                  ],
                ),
              ),
          ],
          if (groups.past.isNotEmpty) ...[
            const SectionLabel('Past'),
            ListGroup(
              children: [
                for (final s in groups.past)
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
      ],
    );
  }

  static String _first(Session s) => s.youthName.split(' ').first;

  Future<void> _decline(BuildContext context, MentorSessionActionsNotifier actions, Session s) async {
    final first = _first(s);
    final ok = await showAppDialog(
      context,
      title: 'Decline $first’s request?',
      body: '$first will be asked to pick another time from your availability.',
      confirmLabel: 'Decline',
      destructive: true,
      icon: Icons.event_busy_outlined,
    );
    if (!ok || !context.mounted) return;
    await _run(context, () => actions.decline(s.id), 'Declined — $first can choose another time', icon: Icons.event_busy_outlined, tone: Tone.warning);
  }

  /// Runs the action, then reports the real outcome.
  static Future<void> _run(BuildContext context, Future<void> Function() action, String done, {IconData? icon, Tone? tone}) async {
    try {
      await action();
      if (context.mounted) {
        showToast(context, done, icon: icon ?? Icons.check_circle_outline_rounded, tone: tone ?? Tone.success);
      }
    } catch (error) {
      if (context.mounted) {
        showToast(context, mentorshipErrorText(error), icon: Icons.error_outline_rounded, tone: Tone.danger);
      }
    }
  }
}
