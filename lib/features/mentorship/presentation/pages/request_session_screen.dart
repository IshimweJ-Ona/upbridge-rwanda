// M3 Request a session: saves a requested session to mentorSessions.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/shared.dart';

class RequestSessionScreen extends ConsumerStatefulWidget {
  const RequestSessionScreen({super.key, required this.mentorId});

  final String mentorId;

  @override
  ConsumerState<RequestSessionScreen> createState() =>
      _RequestSessionScreenState();
}

// Stateful only to own the message controller; choices live in requestFormProvider.
class _RequestSessionScreenState extends ConsumerState<RequestSessionScreen> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<RadioOption<String>> _topics(String first) => [
    RadioOption(
      value: 'Feedback on a project',
      title: 'Feedback on a project',
      subtitle: '$first reviews something you built',
    ),
    const RadioOption(
      value: 'Career advice',
      title: 'Career advice',
      subtitle: 'Next steps, CV, interviews',
    ),
    const RadioOption(
      value: 'Help when stuck',
      title: 'Help when stuck',
      subtitle: 'A specific technical problem',
    ),
  ];

  Future<void> _send(Mentor mentor) async {
    try {
      final id = await ref
          .read(requestFormProvider(widget.mentorId).notifier)
          .send(mentor: mentor, note: _note.text);
      if (id != null && mounted) context.pushReplacement('/request-sent/$id');
    } catch (error) {
      if (!mounted) return;
      showToast(
        context,
        mentorshipErrorText(error),
        icon: Icons.error_outline_rounded,
        tone: Tone.danger,
      );
    }
  }

  void _retry() {
    ref.invalidate(mentorProvider(widget.mentorId));
    ref.invalidate(mySessionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final mentorAsync = ref.watch(mentorProvider(widget.mentorId));
    final slotsAsync = ref.watch(freeSlotsForMentorProvider(widget.mentorId));
    final form = ref.watch(requestFormProvider(widget.mentorId));
    final formNotifier = ref.read(
      requestFormProvider(widget.mentorId).notifier,
    );
    final mentor = mentorAsync.value;

    if (mentor == null) {
      return DetailPage(
        title: 'Request a session',
        backFallback: '/mentors',
        children: [
          const SizedBox(height: 16),
          if (mentorAsync.hasValue)
            const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Mentor not found',
              body: 'This profile is no longer available.',
            )
          else if (mentorAsync.hasError)
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load this mentor',
              body: mentorshipErrorText(mentorAsync.error!),
              action: 'Try again',
              onAction: _retry,
            )
          else
            const Shimmer(child: SkeletonBox(height: 320, radius: Radii.lg)),
        ],
      );
    }

    final first = mentor.name.split(' ').first;
    final slots = slotsAsync.value ?? const <SessionSlot>[];
    // A slot can disappear while the form is open, so re-match it on every build.
    final selected = slots
        .where((s) => s.startsAt == form.slot?.startsAt)
        .firstOrNull;
    final canSend = selected != null && form.topic != null;

    return DetailPage(
      title: 'Request a session',
      backFallback: '/mentor/${mentor.id}',
      footer: [
        AppButton(
          'Send request',
          loading: form.sending,
          onPressed: canSend && !form.sending ? () => _send(mentor) : null,
        ),
      ],
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            AppAvatar(mentor.initials, tone: mentor.tone, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'With ${mentor.name} · 30 minutes',
                style: AppText.bodyS,
              ),
            ),
          ],
        ),
        const SectionLabel('What do you need?'),
        RadioCards<String>(
          options: _topics(first),
          value: form.topic,
          onChanged: (topic) {
            HapticFeedback.selectionClick();
            formNotifier.pickTopic(topic);
          },
        ),
        const SectionLabel('Pick a time'),
        if (slotsAsync.hasValue && slots.isEmpty)
          EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No open times right now',
            body: '$first has no free slots. Check back soon.',
          )
        else if (slotsAsync.hasValue) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                SelectChip(
                  label: slot.label,
                  selected: slot.startsAt == selected?.startsAt,
                  onTap: () => formNotifier.pickSlot(slot),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const MonoLabel('Times are in Kigali time (CAT).'),
        ] else if (slotsAsync.hasError)
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load times',
            body: mentorshipErrorText(slotsAsync.error!),
            action: 'Try again',
            onAction: _retry,
          )
        else
          const Shimmer(child: SkeletonBox(height: 96, radius: Radii.lg)),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Message to $first',
          trailingNote: 'Optional',
          controller: _note,
          maxLines: 4,
          minLines: 3,
          hint: 'What would you like to go through?',
        ),
      ],
    );
  }
}
