import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/prompt_sheet.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorSessionsScreen extends ConsumerStatefulWidget {
  const MentorSessionsScreen({super.key});

  @override
  ConsumerState<MentorSessionsScreen> createState() =>
      _MentorSessionsScreenState();
}

class _MentorSessionsScreenState extends ConsumerState<MentorSessionsScreen> {
  String _filter = 'Scheduled';
  bool _busy = false;

  Future<void> _scheduleOrRescheduleSession(
    String mentorUid,
    List<Mentorship> activeMentees, {
    MentorshipSession? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MentorScheduleSessionSheet(
        mentorUid: mentorUid,
        activeMentees: activeMentees,
        existing: existing,
      ),
    );
    if (saved == true && mounted) {
      showToast(
        context,
        existing == null ? 'Session scheduled' : 'Session rescheduled',
      );
    }
  }

  Future<void> _completeSession(MentorshipSession session) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionRepositoryProvider).transitionSession(
            sessionId: session.id,
            nextStatus: SessionStatus.completed,
            actorUid: session.mentorUid,
          );
      if (mounted) {
        showToast(context, 'Session completed');
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelSession(MentorshipSession session) async {
    if (_busy) return;
    final reason = await showTextPromptSheet(
      context,
      title: 'Cancel "${session.topic}"?',
      fieldLabel: 'Cancellation reason (optional)',
      hint: 'Let your mentee know why or propose a new slot',
      confirmLabel: 'Cancel session',
      destructive: true,
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionRepositoryProvider).transitionSession(
            sessionId: session.id,
            nextStatus: SessionStatus.cancelled,
            cancelReason: reason,
            actorUid: session.mentorUid,
          );
      if (mounted) {
        showToast(context, 'Session cancelled', tone: Tone.warning);
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final uid = ref.watch(appSessionProvider).asData?.value.uid;

    if (uid == null) {
      return PageFrame(
        largeTitle: l10n.tabMentorSessions,
        children: const [SizedBox(height: 16), SkeletonDashboardLoader()],
      );
    }

    final sessionsAsync = ref.watch(mentorSessionsProvider(uid));
    final activeMentees =
        (ref.watch(mentorMentorshipsProvider(uid)).asData?.value ??
                const <Mentorship>[])
            .where((m) => m.status == MentorshipStatus.active)
            .toList(growable: false);

    return PageFrame(
      largeTitle: l10n.tabMentorSessions,
      subtitle: '1-on-1 coaching schedule',
      showBack: true,
      backFallback: '/m/home',
      actions: [
        if (activeMentees.isNotEmpty)
          CircleIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Schedule session',
            onTap: () => _scheduleOrRescheduleSession(uid, activeMentees),
          ),
        const SizedBox(width: 4),
      ],
      onRefresh: () async {
        ref.invalidate(mentorSessionsProvider(uid));
        ref.invalidate(mentorMentorshipsProvider(uid));
      },
      children: [
        const SizedBox(height: 12),
        ChipBar(
          options: const ['Scheduled', 'Completed', 'Cancelled', 'All'],
          selected: _filter,
          padding: EdgeInsets.zero,
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 16),
        sessionsAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load sessions',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(mentorSessionsProvider(uid)),
          ),
          data: (items) {
            final filtered = items
                .where(
                  (s) => switch (_filter) {
                    'Scheduled' => s.status == SessionStatus.scheduled,
                    'Completed' => s.status == SessionStatus.completed,
                    'Cancelled' => s.status == SessionStatus.cancelled,
                    _ => true,
                  },
                )
                .toList(growable: false);

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.event_outlined,
                title: 'No ${_filter.toLowerCase()} sessions',
                body: activeMentees.isEmpty
                    ? 'Accept a mentee request first to schedule sessions.'
                    : 'Schedule a 1-on-1 session with one of your active mentees.',
                action: activeMentees.isEmpty ? null : 'Schedule session',
                onAction: activeMentees.isEmpty
                    ? null
                    : () => _scheduleOrRescheduleSession(uid, activeMentees),
              );
            }

            return Column(
              children: [
                for (final s in filtered) ...[
                  SurfaceCard(
                    onTap: () => context.push('/mentorship/${s.mentorshipId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.topic, style: AppText.titleS),
                            ),
                            StatusBadge(
                              s.status.label,
                              tone: switch (s.status) {
                                SessionStatus.scheduled => Tone.info,
                                SessionStatus.completed => Tone.success,
                                SessionStatus.cancelled => Tone.neutral,
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'With ${s.studentName} · ${DateFormat('EEE d MMM · HH:mm').format(s.scheduledAt.toLocal())} · ${s.meetingMode}',
                          style: AppText.caption.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                        if (s.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Notes: ${s.notes}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyS.copyWith(color: p.textMuted),
                          ),
                        ],
                        if (s.status == SessionStatus.scheduled) ...[
                          Divider(height: 20, color: p.borderSubtle),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppButton(
                                'Mark completed',
                                size: ButtonSize.small,
                                expand: false,
                                loading: _busy,
                                onPressed: () => _completeSession(s),
                              ),
                              AppButton(
                                l10n.rescheduleLabel,
                                size: ButtonSize.small,
                                variant: ButtonVariant.secondary,
                                expand: false,
                                onPressed: _busy
                                    ? null
                                    : () => _scheduleOrRescheduleSession(
                                        uid,
                                        activeMentees,
                                        existing: s,
                                      ),
                              ),
                              AppButton(
                                'Cancel',
                                size: ButtonSize.small,
                                variant: ButtonVariant.dangerOutline,
                                expand: false,
                                onPressed: _busy ? null : () => _cancelSession(s),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MentorScheduleSessionSheet extends ConsumerStatefulWidget {
  const _MentorScheduleSessionSheet({
    required this.mentorUid,
    required this.activeMentees,
    this.existing,
  });

  final String mentorUid;
  final List<Mentorship> activeMentees;
  final MentorshipSession? existing;

  @override
  ConsumerState<_MentorScheduleSessionSheet> createState() =>
      _MentorScheduleSessionSheetState();
}

class _MentorScheduleSessionSheetState
    extends ConsumerState<_MentorScheduleSessionSheet> {
  late final TextEditingController _topicCtrl = TextEditingController(
    text: widget.existing?.topic ?? '',
  );
  late final TextEditingController _linkCtrl = TextEditingController(
    text: widget.existing?.meetingLink ?? '',
  );
  late Mentorship? _selected = widget.activeMentees.isEmpty
      ? null
      : widget.activeMentees.firstWhere(
          (m) => m.id == widget.existing?.mentorshipId,
          orElse: () => widget.activeMentees.first,
        );
  late DateTime _scheduledAt =
      widget.existing?.scheduledAt.toLocal() ??
      DateTime.now().add(const Duration(days: 2, hours: 2));
  late String _mode = widget.existing?.meetingMode ?? 'Online';
  late int _duration = widget.existing?.durationMinutes ?? 45;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _topicCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final topic = _topicCtrl.text.trim();
    if (topic.length < 3) {
      setState(() => _error = 'Enter a session topic.');
      return;
    }
    if (_mode == 'Online') {
      final linkErr = Validators.optionalUrl(_linkCtrl.text);
      if (linkErr != null) {
        setState(() => _error = linkErr);
        return;
      }
    }
    final existing = widget.existing;
    final selected = _selected;
    if (existing == null && selected == null) {
      setState(() => _error = 'Select a mentee first.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(sessionRepositoryProvider);
      if (existing != null) {
        await repo.rescheduleSession(
          sessionId: existing.id,
          scheduledAt: _scheduledAt.toUtc(),
          durationMinutes: _duration,
          meetingMode: _mode,
          meetingLink: _linkCtrl.text.trim(),
          topic: topic,
          actorUid: widget.mentorUid,
        );
      } else {
        final now = DateTime.now().toUtc();
        await repo.scheduleSession(
          MentorshipSession(
            id: '',
            ownerUid: widget.mentorUid,
            mentorshipId: selected!.id,
            studentUid: selected.studentUid,
            studentName: selected.studentName,
            mentorUid: selected.mentorUid,
            mentorName: selected.mentorName,
            topic: topic,
            meetingMode: _mode,
            meetingLink: _linkCtrl.text.trim(),
            scheduledAt: _scheduledAt.toUtc(),
            durationMinutes: _duration,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        20,
        Space.gutter,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Reschedule session' : 'Schedule session',
              style: AppText.titleM,
            ),
            const SizedBox(height: 12),
            if (!isEditing && _selected != null) ...[
              DropdownButtonFormField<Mentorship>(
                initialValue: _selected,
                decoration: const InputDecoration(labelText: 'Mentee'),
                items: [
                  for (final m in widget.activeMentees)
                    DropdownMenuItem(value: m, child: Text(m.studentName)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selected = v);
                },
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(
              label: 'Session topic',
              hint: 'e.g. Resume review & portfolio feedback',
              controller: _topicCtrl,
              error: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SurfaceCard(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _scheduledAt,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked == null || !mounted) return;
                      setState(() {
                        _scheduledAt = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _scheduledAt.hour,
                          _scheduledAt.minute,
                        );
                      });
                    },
                    child: ListRow(
                      padding: EdgeInsets.zero,
                      title: 'Date',
                      subtitle: DateFormat('EEE d MMM').format(_scheduledAt),
                      chevron: false,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SurfaceCard(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                      );
                      if (picked == null || !mounted) return;
                      setState(() {
                        _scheduledAt = DateTime(
                          _scheduledAt.year,
                          _scheduledAt.month,
                          _scheduledAt.day,
                          picked.hour,
                          picked.minute,
                        );
                      });
                    },
                    child: ListRow(
                      padding: EdgeInsets.zero,
                      title: 'Time',
                      subtitle: DateFormat('HH:mm').format(_scheduledAt),
                      chevron: false,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final opt in ['Online', 'In-person'])
                  ChoiceChip(
                    label: Text(opt),
                    selected: _mode == opt,
                    onSelected: (_) => setState(() => _mode = opt),
                  ),
                for (final mins in [30, 45, 60])
                  ChoiceChip(
                    label: Text('$mins min'),
                    selected: _duration == mins,
                    onSelected: (_) => setState(() => _duration = mins),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: _mode == 'Online' ? 'Meeting link' : 'Location',
              hint: _mode == 'Online'
                  ? 'https://meet.google.com/...'
                  : 'Kigali Innovation City',
              controller: _linkCtrl,
            ),
            const SizedBox(height: 16),
            AppButton('Create session', loading: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
