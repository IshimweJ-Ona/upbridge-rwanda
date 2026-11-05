// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// M3 · Request a session — pick a slot and a topic.
class RequestSessionScreen extends ConsumerStatefulWidget {
  const RequestSessionScreen({super.key, required this.mentorId});

  final String mentorId;

  @override
  ConsumerState<RequestSessionScreen> createState() => _RequestSessionScreenState();
}

class _RequestSessionScreenState extends ConsumerState<RequestSessionScreen> {
  SessionSlot? _slot;
  String? _topic;
  final _note = TextEditingController();
  bool _sending = false;

  static const _topics = [
    RadioOption(value: 'Review my work', title: 'Review my work', subtitle: 'Go through a task or project together', icon: Icons.rate_review_outlined),
    RadioOption(value: 'Portfolio feedback', title: 'Portfolio feedback', subtitle: 'Get it ready to send to employers', icon: Icons.folder_special_outlined),
    RadioOption(value: 'Career advice', title: 'Career advice', subtitle: 'Choosing roles, CVs, first-job questions', icon: Icons.explore_outlined),
    RadioOption(value: 'Interview practice', title: 'Interview practice', subtitle: 'A short mock interview with feedback', icon: Icons.record_voice_over_outlined),
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final id = ref.read(appStoreProvider.notifier).requestSession(mentorId: widget.mentorId, slot: _slot!, topic: _topic!, note: _note.text.trim());
    context.pushReplacement('/request-sent/$id');
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(appStoreProvider.select((s) => s.mentor(widget.mentorId)));
    final first = m.name.split(' ').first;
    final days = <String, List<SessionSlot>>{};
    for (final s in m.slots) {
      days.putIfAbsent(s.day, () => []).add(s);
    }

    return DetailPage(
      title: 'Request a session',
      backFallback: '/mentor/${m.id}',
      footerNote: AnimatedSwitcher(
        duration: Motion.base,
        child: Text(
          _slot == null ? 'Choose a time and a topic' : '${_slot!.label} · ${_topic ?? 'choose a topic'}',
          key: ValueKey('${_slot?.label}$_topic'),
          style: AppText.bodySStrong,
          textAlign: TextAlign.center,
        ),
      ),
      footer: [AppButton('Send request', icon: Icons.send_rounded, loading: _sending, onPressed: _slot != null && _topic != null ? _send : null)],
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            AppAvatar(m.initials, tone: m.tone, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('With ${m.name}', style: AppText.titleS),
                  const SizedBox(height: 2),
                  MonoLabel(m.availability),
                ],
              ),
            ),
          ],
        ),
        const SectionLabel('Choose a time'),
        for (final entry in days.entries) ...[
          MonoLabel(entry.key, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in entry.value)
                SelectChip(
                  label: s.time,
                  icon: Icons.schedule_rounded,
                  selected: _slot == s,
                  onTap: () => setState(() => _slot = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const SectionLabel('What do you want to talk about?', top: 8),
        RadioCards<String>(
          options: _topics,
          value: _topic,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _topic = v);
          },
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Anything $first should know?',
          trailingNote: 'Optional',
          controller: _note,
          maxLines: 4,
          minLines: 3,
          hint: 'e.g. I want to apply to Irembo and would like feedback on my homepage first.',
        ),
        const SizedBox(height: 16),
        NoticeCard(
          tone: Tone.info,
          icon: Icons.videocam_outlined,
          title: '30 minutes on Google Meet',
          body: '$first confirms within a day. You’ll get the link by SMS and in the app.',
        ),
      ],
    );
  }
}
