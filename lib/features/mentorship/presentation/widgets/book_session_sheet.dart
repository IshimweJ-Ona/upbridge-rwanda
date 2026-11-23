import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/widgets/prompt_sheet.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

/// Opens the reusable booking / scheduling / rescheduling modal sheet.
Future<bool> showBookSessionSheet(
  BuildContext context, {
  required String actorUid,
  String actorName = '',
  Mentorship? mentorship,
  UserProfile? mentor,
  List<UserProfile> availableMentors = const [],
  Map<String, Mentorship> activeMentorshipsByMentor = const {},
  MentorshipSession? existing,
  String submitLabel = 'Book session',
  String title = 'Book 1-on-1 session',
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BookSessionSheet(
      actorUid: actorUid,
      actorName: actorName,
      mentorship: mentorship,
      mentor: mentor,
      availableMentors: availableMentors,
      activeMentorshipsByMentor: activeMentorshipsByMentor,
      existing: existing,
      submitLabel: submitLabel,
      title: title,
    ),
  );
  return saved == true;
}

/// Opens a session detail sheet with view links and role-appropriate actions.
Future<void> showSessionDetailSheet(
  BuildContext context, {
  required MentorshipSession session,
  required String actorUid,
  required bool isMentor,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SessionDetailSheet(
      session: session,
      actorUid: actorUid,
      isMentor: isMentor,
    ),
  );
}

class BookSessionSheet extends ConsumerStatefulWidget {
  const BookSessionSheet({
    super.key,
    required this.actorUid,
    this.actorName = '',
    this.mentorship,
    this.mentor,
    this.availableMentors = const [],
    this.activeMentorshipsByMentor = const {},
    this.existing,
    this.submitLabel = 'Book session',
    this.title = 'Book 1-on-1 session',
  });

  final String actorUid;
  final String actorName;
  final Mentorship? mentorship;
  final UserProfile? mentor;
  final List<UserProfile> availableMentors;
  final Map<String, Mentorship> activeMentorshipsByMentor;
  final MentorshipSession? existing;
  final String submitLabel;
  final String title;

  @override
  ConsumerState<BookSessionSheet> createState() => _BookSessionSheetState();
}

class _BookSessionSheetState extends ConsumerState<BookSessionSheet> {
  late final TextEditingController _topicCtrl = TextEditingController(
    text: widget.existing?.topic ?? '',
  );
  late final TextEditingController _linkCtrl = TextEditingController(
    text: widget.existing?.meetingLink ?? '',
  );
  late final TextEditingController _notesCtrl = TextEditingController(
    text: widget.existing?.notes ?? '',
  );

  late UserProfile? _selectedMentor =
      widget.mentor ??
      (widget.availableMentors.isNotEmpty
          ? widget.availableMentors.first
          : null);
  late DateTime _scheduledAt =
      widget.existing?.scheduledAt.toLocal() ??
      DateTime.now().add(const Duration(days: 2, hours: 2));
  late String _mode = widget.existing?.meetingMode.isNotEmpty == true
      ? widget.existing!.meetingMode
      : 'Online';
  late int _duration = widget.existing?.durationMinutes ?? 45;
  bool _busy = false;
  String? _topicError;
  String? _linkError;
  String? _notesError;
  String? _submitError;

  @override
  void dispose() {
    _topicCtrl.dispose();
    _linkCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _resolvedMentorName() {
    if (widget.existing != null) return widget.existing!.mentorName;
    if (widget.mentorship != null) return widget.mentorship!.mentorName;
    final m = _selectedMentor;
    if (m != null) {
      return m.displayName.trim().isEmpty ? 'Mentor' : m.displayName.trim();
    }
    return 'Mentor';
  }

  String _resolvedAvailability() {
    final m = _selectedMentor ?? widget.mentor;
    return m?.mentorAvailability.trim() ?? '';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final topic = _topicCtrl.text.trim();
    final link = _linkCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    String? topicErr;
    String? linkErr;
    String? notesErr;
    String? generalErr;

    if (topic.length < 3) {
      topicErr = 'Enter a session topic (min 3 characters).';
    } else if (topic.length > 200) {
      topicErr = 'Keep the session topic under 200 characters.';
    }

    if (_mode == 'Online' && link.isNotEmpty) {
      linkErr = Validators.optionalUrl(link);
    } else if (link.length > 500) {
      linkErr = 'Keep details under 500 characters.';
    }

    if (notes.length > 1000) {
      notesErr = 'Keep session notes under 1000 characters.';
    }

    if (!_scheduledAt.isAfter(DateTime.now())) {
      generalErr = 'Choose a future date and time for this session.';
    }

    final existing = widget.existing;
    if (existing == null &&
        widget.mentorship == null &&
        _selectedMentor == null) {
      generalErr ??= 'Select a mentor for this session.';
    }

    if (topicErr != null ||
        linkErr != null ||
        notesErr != null ||
        generalErr != null) {
      setState(() {
        _topicError = topicErr;
        _linkError = linkErr;
        _notesError = notesErr;
        _submitError = generalErr;
      });
      return;
    }

    setState(() {
      _busy = true;
      _topicError = null;
      _linkError = null;
      _notesError = null;
      _submitError = null;
    });

    try {
      final repo = ref.read(sessionRepositoryProvider);
      if (existing != null) {
        await repo.rescheduleSession(
          sessionId: existing.id,
          scheduledAt: _scheduledAt.toUtc(),
          durationMinutes: _duration,
          meetingMode: _mode,
          meetingLink: link,
          topic: topic,
          notes: notes,
          actorUid: widget.actorUid,
        );
      } else {
        final ms = widget.mentorship;
        final chosenMentor = _selectedMentor;
        final linkedMs =
            ms ??
            (chosenMentor == null
                ? null
                : widget.activeMentorshipsByMentor[chosenMentor.ownerUid]);
        final studentUid = ms?.studentUid ?? widget.actorUid;
        final studentName =
            ms?.studentName ??
            (widget.actorName.trim().isNotEmpty
                ? widget.actorName.trim()
                : 'Student');
        final mentorUid = ms?.mentorUid ?? chosenMentor!.ownerUid;
        final mentorName = _resolvedMentorName();
        final now = DateTime.now().toUtc();

        await repo.scheduleSession(
          MentorshipSession(
            id: '',
            ownerUid: widget.actorUid,
            mentorshipId: linkedMs?.id ?? '',
            studentUid: studentUid,
            studentName: studentName,
            mentorUid: mentorUid,
            mentorName: mentorName,
            topic: topic,
            notes: notes,
            meetingMode: _mode,
            meetingLink: link,
            scheduledAt: _scheduledAt.toUtc(),
            durationMinutes: _duration,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _submitError = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isEditing = widget.existing != null;
    final showMentorPicker =
        !isEditing &&
        widget.mentorship == null &&
        widget.mentor == null &&
        widget.availableMentors.isNotEmpty;
    final availability = _resolvedAvailability();

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
              isEditing ? 'Reschedule session' : widget.title,
              style: AppText.titleM,
            ),
            if (!showMentorPicker) ...[
              const SizedBox(height: 4),
              Text(
                'With ${_resolvedMentorName()}',
                style: AppText.bodyS.copyWith(color: p.textSecondary),
              ),
            ],
            if (availability.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge('Availability: $availability', tone: Tone.info),
              ),
            ],
            const SizedBox(height: 14),
            if (showMentorPicker) ...[
              DropdownButtonFormField<UserProfile>(
                initialValue: _selectedMentor,
                decoration: const InputDecoration(labelText: 'Select mentor'),
                items: [
                  for (final m in widget.availableMentors)
                    DropdownMenuItem(
                      value: m,
                      child: Text(
                        m.displayName.trim().isEmpty
                            ? 'Verified Mentor'
                            : m.displayName.trim(),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMentor = value);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(
              label: 'Session topic',
              hint: 'e.g. Portfolio review & mock interview',
              controller: _topicCtrl,
              error: _topicError,
              onChanged: (_) {
                if (_topicError != null || _submitError != null) {
                  setState(() {
                    _topicError = null;
                    _submitError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SurfaceCard(
                    onTap: () async {
                      final now = DateTime.now();
                      final initialDate = _scheduledAt.isBefore(now)
                          ? now
                          : _scheduledAt;
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 180)),
                      );
                      if (pickedDate == null || !mounted) return;
                      setState(() {
                        _submitError = null;
                        _scheduledAt = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          _scheduledAt.hour,
                          _scheduledAt.minute,
                        );
                      });
                    },
                    child: ListRow(
                      padding: EdgeInsets.zero,
                      title: 'Date',
                      subtitle: DateFormat('EEE, d MMM').format(_scheduledAt),
                      chevron: false,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SurfaceCard(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                      );
                      if (pickedTime == null || !mounted) return;
                      setState(() {
                        _submitError = null;
                        _scheduledAt = DateTime(
                          _scheduledAt.year,
                          _scheduledAt.month,
                          _scheduledAt.day,
                          pickedTime.hour,
                          pickedTime.minute,
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
              runSpacing: 6,
              children: [
                for (final opt in ['Online', 'In-person'])
                  ChoiceChip(
                    label: Text(opt),
                    selected: _mode == opt,
                    onSelected: (_) => setState(() {
                      _mode = opt;
                      _linkError = null;
                    }),
                  ),
                for (final mins in [30, 45, 60, 90])
                  ChoiceChip(
                    label: Text('$mins min'),
                    selected: _duration == mins,
                    onSelected: (_) => setState(() => _duration = mins),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: _mode == 'Online'
                  ? 'Meeting link (optional)'
                  : 'Location details (optional)',
              hint: _mode == 'Online'
                  ? 'https://meet.google.com/...'
                  : 'e.g. Kigali Innovation City hub',
              controller: _linkCtrl,
              error: _linkError,
              onChanged: (_) {
                if (_linkError != null) setState(() => _linkError = null);
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Goals or agenda (optional)',
              hint: 'Share what you want to cover or prepare ahead of time.',
              controller: _notesCtrl,
              maxLines: 3,
              error: _notesError,
              onChanged: (_) {
                if (_notesError != null) setState(() => _notesError = null);
              },
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 10),
              Text(
                _submitError!,
                style: AppText.caption.copyWith(color: p.dangerText),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              isEditing ? 'Save new time' : widget.submitLabel,
              loading: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 6),
            Text(
              'Both student and mentor see booked sessions in real time.',
              style: AppText.caption.copyWith(color: p.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionDetailSheet extends ConsumerStatefulWidget {
  const _SessionDetailSheet({
    required this.session,
    required this.actorUid,
    required this.isMentor,
  });

  final MentorshipSession session;
  final String actorUid;
  final bool isMentor;

  @override
  ConsumerState<_SessionDetailSheet> createState() =>
      _SessionDetailSheetState();
}

class _SessionDetailSheetState extends ConsumerState<_SessionDetailSheet> {
  bool _busy = false;

  Tone _toneFor(SessionStatus status) => switch (status) {
    SessionStatus.scheduled => Tone.info,
    SessionStatus.completed => Tone.success,
    SessionStatus.cancelled => Tone.neutral,
  };

  Future<void> _reschedule() async {
    final s = widget.session;
    final saved = await showBookSessionSheet(
      context,
      actorUid: widget.actorUid,
      existing: s,
      title: 'Reschedule session',
    );
    if (saved && mounted) {
      showToast(context, 'Session rescheduled');
      Navigator.of(context).pop();
    }
  }

  Future<void> _editNotes() async {
    final s = widget.session;
    final notes = await showTextPromptSheet(
      context,
      title: 'Session notes',
      fieldLabel: 'Key takeaways & next actions',
      initialValue: s.notes,
      confirmLabel: 'Save notes',
      maxLines: 5,
    );
    if (notes == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(sessionRepositoryProvider)
          .updateSessionNotes(sessionId: s.id, notes: notes);
      if (mounted) {
        showToast(context, 'Notes saved');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _transition(SessionStatus nextStatus) async {
    final s = widget.session;
    var cancelReason = '';
    if (nextStatus == SessionStatus.cancelled) {
      final entered = await showTextPromptSheet(
        context,
        title: 'Cancel "${s.topic}"?',
        fieldLabel: 'Reason (optional)',
        hint: 'Let your partner know why or propose a new slot',
        confirmLabel: 'Cancel session',
        destructive: true,
      );
      if (entered == null || !mounted) return;
      cancelReason = entered;
    } else {
      final confirmed = await showAppDialog(
        context,
        title: 'Complete session?',
        body: 'Mark "${s.topic}" as completed?',
        confirmLabel: 'Complete',
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(sessionRepositoryProvider).transitionSession(
        sessionId: s.id,
        nextStatus: nextStatus,
        cancelReason: cancelReason,
        actorUid: widget.actorUid,
      );
      if (mounted) {
        showToast(
          context,
          'Session ${nextStatus.label.toLowerCase()}',
          tone: nextStatus == SessionStatus.cancelled
              ? Tone.warning
              : Tone.success,
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = widget.session;
    final isScheduled = s.status == SessionStatus.scheduled;
    final isUrl =
        s.meetingLink.startsWith('https://') ||
        s.meetingLink.startsWith('http://');
    final partnerLabel = widget.isMentor
        ? 'Student: ${s.studentName}'
        : 'Mentor: ${s.mentorName}';

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(Icons.event_note_outlined, tone: Tone.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.topic, style: AppText.titleM),
                      const SizedBox(height: 2),
                      Text(
                        partnerLabel,
                        style: AppText.bodyS.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                StatusBadge(s.status.label, tone: _toneFor(s.status)),
              ],
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('EEE d MMM y · HH:mm').format(s.scheduledAt.toLocal())} · ${s.durationMinutes} min',
                    style: AppText.bodyMStrong,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mode: ${s.meetingMode}',
                    style: AppText.bodyS.copyWith(color: p.textSecondary),
                  ),
                  if (s.meetingLink.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    if (isUrl)
                      TextLink(
                        displayUrl(s.meetingLink),
                        onTap: () => openLink(context, s.meetingLink),
                      )
                    else
                      Text(
                        'Location: ${s.meetingLink}',
                        style: AppText.bodyS.copyWith(color: p.textSecondary),
                      ),
                  ],
                  if (s.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notes: ${s.notes}',
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                  ],
                  if (s.status == SessionStatus.cancelled &&
                      s.cancelReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cancellation reason: ${s.cancelReason}',
                      style: AppText.bodyS.copyWith(color: p.dangerText),
                    ),
                  ],
                ],
              ),
            ),
            if (isScheduled) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.isMentor) ...[
                    AppButton(
                      'Mark completed',
                      size: ButtonSize.small,
                      expand: false,
                      loading: _busy,
                      onPressed: () => _transition(SessionStatus.completed),
                    ),
                    AppButton(
                      s.notes.isEmpty ? 'Add notes' : 'Edit notes',
                      size: ButtonSize.small,
                      variant: ButtonVariant.secondary,
                      expand: false,
                      onPressed: _busy ? null : _editNotes,
                    ),
                  ],
                  AppButton(
                    'Reschedule',
                    size: ButtonSize.small,
                    variant: ButtonVariant.secondary,
                    expand: false,
                    onPressed: _busy ? null : _reschedule,
                  ),
                  AppButton(
                    'Cancel session',
                    size: ButtonSize.small,
                    variant: ButtonVariant.dangerOutline,
                    expand: false,
                    onPressed: _busy
                        ? null
                        : () => _transition(SessionStatus.cancelled),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (s.mentorshipId.isNotEmpty)
              AppButton(
                'Open mentorship workspace',
                variant: ButtonVariant.ghost,
                size: ButtonSize.small,
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push('/mentorship/${s.mentorshipId}');
                },
              )
            else if (!widget.isMentor && s.mentorUid.isNotEmpty)
              AppButton(
                'View mentor profile',
                variant: ButtonVariant.ghost,
                size: ButtonSize.small,
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push('/mentor/${s.mentorUid}');
                },
              )
            else if (widget.isMentor && s.studentUid.isNotEmpty)
              AppButton(
                'View student CV',
                variant: ButtonVariant.ghost,
                size: ButtonSize.small,
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push('/user-profile/${s.studentUid}');
                },
              ),
          ],
        ),
      ),
    );
  }
}
