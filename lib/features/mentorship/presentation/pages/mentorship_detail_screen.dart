import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/prompt_sheet.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorshipDetailScreen extends ConsumerStatefulWidget {
  const MentorshipDetailScreen({super.key, required this.mentorshipId});

  final String mentorshipId;

  @override
  ConsumerState<MentorshipDetailScreen> createState() =>
      _MentorshipDetailScreenState();
}

class _MentorshipDetailScreenState
    extends ConsumerState<MentorshipDetailScreen> {
  bool _busy = false;

  Future<void> _openScheduleSheet(
    Mentorship mentorship,
    String actorUid,
  ) async {
    final scheduled = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _ScheduleSessionSheet(mentorship: mentorship, actorUid: actorUid),
    );
    if (scheduled == true && mounted) {
      showToast(context, 'Session scheduled');
    }
  }

  Future<void> _editNotes(MentorshipSession session) async {
    final notes = await showTextPromptSheet(
      context,
      title: 'Session notes',
      fieldLabel: 'Key takeaways & next actions',
      initialValue: session.notes,
      confirmLabel: 'Save notes',
      maxLines: 5,
    );
    if (notes == null || !mounted) return;
    try {
      await ref
          .read(sessionRepositoryProvider)
          .updateSessionNotes(sessionId: session.id, notes: notes);
      if (mounted) showToast(context, 'Notes saved');
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    }
  }

  Future<void> _updateSessionStatus(
    MentorshipSession session,
    SessionStatus nextStatus,
    String? actorUid,
  ) async {
    String cancelReason = '';
    if (nextStatus == SessionStatus.cancelled) {
      final entered = await showTextPromptSheet(
        context,
        title: 'Cancel "${session.topic}"?',
        fieldLabel: 'Reason (optional)',
        hint: 'Share a short explanation with your partner',
        confirmLabel: 'Cancel session',
        destructive: true,
      );
      if (entered == null || !mounted) return;
      cancelReason = entered;
    } else {
      final ok = await showAppDialog(
        context,
        title: 'Complete session?',
        body: 'Mark "${session.topic}" as completed?',
        confirmLabel: 'Complete',
      );
      if (!ok || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(sessionRepositoryProvider).transitionSession(
            sessionId: session.id,
            nextStatus: nextStatus,
            cancelReason: cancelReason,
            actorUid: actorUid,
          );
      if (mounted) {
        showToast(context, 'Session ${nextStatus.label.toLowerCase()}');
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishMentorship(
    Mentorship mentorship,
    String actorUid,
    bool isStudent,
  ) async {
    final result = await showModalBottomSheet<MentorshipStatus>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FinishMentorshipSheet(
        mentorship: mentorship,
        actorUid: actorUid,
        isStudent: isStudent,
      ),
    );
    if (result != null && mounted) {
      showToast(context, 'Mentorship ${result.label.toLowerCase()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final uid = ref.watch(appSessionProvider).asData?.value.uid;
    final mentorshipAsync = ref.watch(
      mentorshipDetailProvider(widget.mentorshipId),
    );
    final sessionsAsync = ref.watch(
      mentorshipSessionsProvider(widget.mentorshipId),
    );

    return mentorshipAsync.when(
      loading: () => const DetailPage(
        title: 'Mentorship workspace',
        backFallback: '/home',
        children: [SkeletonDetailPageLoader()],
      ),
      error: (error, _) => DetailPage(
        title: 'Mentorship workspace',
        backFallback: '/home',
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load mentorship',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () =>
                ref.invalidate(mentorshipDetailProvider(widget.mentorshipId)),
          ),
        ],
      ),
      data: (mentorship) {
        if (mentorship == null) {
          return const DetailPage(
            title: 'Mentorship workspace',
            backFallback: '/home',
            children: [
              EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'Mentorship not found',
                body:
                    'This mentorship record does not exist or is inaccessible.',
              ),
            ],
          );
        }

        final isStudent = uid == mentorship.studentUid;
        final isMentorOwner = uid == mentorship.mentorUid;
        final partnerName = isStudent
            ? mentorship.mentorName
            : mentorship.studentName;
        final partnerRoleLabel = isStudent ? 'Mentor' : 'Mentee';
        final isActive = mentorship.status == MentorshipStatus.active;

        return DetailPage(
          title: 'Mentorship workspace',
          backFallback: isMentorOwner ? '/m/mentees' : '/mentors',
          children: [
            const SizedBox(height: 8),
            SurfaceCard(
              accentEdge: isActive ? p.successText : p.textMuted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        initialsOf(partnerName),
                        tone: Tone.info,
                        size: 46,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partnerName, style: AppText.titleM),
                            Text(
                              '$partnerRoleLabel · Started ${DateFormat('d MMM y').format(mentorship.createdAt.toLocal())}',
                              style: AppText.caption.copyWith(
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        mentorship.status.label,
                        tone: isActive ? Tone.success : Tone.neutral,
                      ),
                    ],
                  ),
                  if (mentorship.goalSummary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Goal: ${mentorship.goalSummary}',
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                  ],
                  if (isActive && uid != null && (isStudent || isMentorOwner)) ...[
                    const SizedBox(height: 14),
                    AppButton(
                      'Schedule session',
                      icon: Icons.event_available_outlined,
                      loading: _busy,
                      onPressed: () => _openScheduleSheet(mentorship, uid),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      'Complete or end mentorship',
                      variant: ButtonVariant.secondary,
                      size: ButtonSize.small,
                      onPressed: () =>
                          _finishMentorship(mentorship, uid, isStudent),
                    ),
                  ],
                ],
              ),
            ),
            if (mentorship.feedbackRating != null ||
                mentorship.feedbackComment.isNotEmpty) ...[
              const SectionLabel('Feedback'),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mentorship.feedbackRating != null)
                      Text(
                        'Rating: ${mentorship.feedbackRating}/5',
                        style: AppText.bodySStrong,
                      ),
                    if (mentorship.feedbackComment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        mentorship.feedbackComment,
                        style: AppText.bodyS.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SectionLabel('Sessions'),
            sessionsAsync.when(
              loading: () => const SkeletonListLoader(rows: 2),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load sessions',
                body: errorMessage(error),
                action: l10n.retry,
                onAction: () => ref.invalidate(
                  mentorshipSessionsProvider(widget.mentorshipId),
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No sessions yet',
                    body: isActive
                        ? 'Schedule your first 1-on-1 session to set milestones.'
                        : 'No sessions were logged during this mentorship.',
                  );
                }
                return Column(
                  children: [
                    for (final session in sessions) ...[
                      _SessionTile(
                        session: session,
                        isMentor: isMentorOwner,
                        canCancel:
                            isActive &&
                            (isStudent || isMentorOwner) &&
                            session.status == SessionStatus.scheduled,
                        canCompleteOrEdit:
                            isActive &&
                            isMentorOwner &&
                            session.status == SessionStatus.scheduled,
                        onEditNotes: () => _editNotes(session),
                        onComplete: () => _updateSessionStatus(
                          session,
                          SessionStatus.completed,
                          uid,
                        ),
                        onCancel: () => _updateSessionStatus(
                          session,
                          SessionStatus.cancelled,
                          uid,
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
      },
    );
  }
}

class _ScheduleSessionSheet extends ConsumerStatefulWidget {
  const _ScheduleSessionSheet({
    required this.mentorship,
    required this.actorUid,
  });

  final Mentorship mentorship;
  final String actorUid;

  @override
  ConsumerState<_ScheduleSessionSheet> createState() =>
      _ScheduleSessionSheetState();
}

class _ScheduleSessionSheetState extends ConsumerState<_ScheduleSessionSheet> {
  final _topicCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  String _mode = 'Online';
  int _duration = 45;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 2, hours: 2));
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
      setState(() => _error = 'Enter a session topic (min 3 characters).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final now = DateTime.now().toUtc();
      await ref
          .read(sessionRepositoryProvider)
          .scheduleSession(
            MentorshipSession(
              id: '',
              ownerUid: widget.actorUid,
              mentorshipId: widget.mentorship.id,
              studentUid: widget.mentorship.studentUid,
              studentName: widget.mentorship.studentName,
              mentorUid: widget.mentorship.mentorUid,
              mentorName: widget.mentorship.mentorName,
              topic: topic,
              meetingMode: _mode,
              meetingLink: _linkCtrl.text.trim(),
              scheduledAt: _scheduledAt.toUtc(),
              durationMinutes: _duration,
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
            Text('Schedule 1-on-1 session', style: AppText.titleM),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Session topic',
              hint: 'e.g. Portfolio review & mock interview',
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
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _scheduledAt,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (pickedDate == null || !mounted) return;
                      setState(() {
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
              label: _mode == 'Online'
                  ? 'Meeting link (optional)'
                  : 'Location details (optional)',
              hint: _mode == 'Online'
                  ? 'https://meet.google.com/...'
                  : 'e.g. Kigali Innovation City hub',
              controller: _linkCtrl,
            ),
            const SizedBox(height: 16),
            AppButton('Schedule session', loading: _busy, onPressed: _submit),
            const SizedBox(height: 6),
            Text(
              'Both student and mentor see scheduled sessions in real time.',
              style: AppText.caption.copyWith(color: p.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishMentorshipSheet extends ConsumerStatefulWidget {
  const _FinishMentorshipSheet({
    required this.mentorship,
    required this.actorUid,
    required this.isStudent,
  });

  final Mentorship mentorship;
  final String actorUid;
  final bool isStudent;

  @override
  ConsumerState<_FinishMentorshipSheet> createState() =>
      _FinishMentorshipSheetState();
}

class _FinishMentorshipSheetState
    extends ConsumerState<_FinishMentorshipSheet> {
  final _commentCtrl = TextEditingController();
  MentorshipStatus _selectedStatus = MentorshipStatus.completed;
  int _rating = 5;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(mentorshipRepositoryProvider)
          .completeOrEndMentorship(
            mentorshipId: widget.mentorship.id,
            nextStatus: _selectedStatus,
            actorUid: widget.actorUid,
            feedbackRating: widget.isStudent ? _rating : null,
            feedbackComment: widget.isStudent ? _commentCtrl.text.trim() : '',
          );
      if (mounted) Navigator.of(context).pop(_selectedStatus);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
            Text('Close mentorship', style: AppText.titleM),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Mark completed'),
                  selected: _selectedStatus == MentorshipStatus.completed,
                  onSelected: (_) => setState(
                    () => _selectedStatus = MentorshipStatus.completed,
                  ),
                ),
                ChoiceChip(
                  label: const Text('End early'),
                  selected: _selectedStatus == MentorshipStatus.ended,
                  onSelected: (_) =>
                      setState(() => _selectedStatus = MentorshipStatus.ended),
                ),
              ],
            ),
            if (widget.isStudent) ...[
              const SizedBox(height: 14),
              Text('Optional mentor rating', style: AppText.bodySStrong),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (i) {
                  final value = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = value),
                    icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: p.warningText,
                    ),
                  );
                }),
              ),
              AppTextField(
                label: 'Optional feedback comment',
                hint: 'How did this mentorship help your growth?',
                controller: _commentCtrl,
                maxLines: 3,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: p.dangerText)),
            ],
            const SizedBox(height: 16),
            AppButton(
              _selectedStatus == MentorshipStatus.completed
                  ? 'Complete mentorship'
                  : 'End mentorship',
              variant: _selectedStatus == MentorshipStatus.ended
                  ? ButtonVariant.danger
                  : ButtonVariant.primary,
              loading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isMentor,
    required this.canCompleteOrEdit,
    required this.canCancel,
    required this.onEditNotes,
    required this.onComplete,
    required this.onCancel,
  });

  final MentorshipSession session;
  final bool isMentor;
  final bool canCompleteOrEdit;
  final bool canCancel;
  final VoidCallback onEditNotes;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tone = switch (session.status) {
      SessionStatus.scheduled => Tone.info,
      SessionStatus.completed => Tone.success,
      SessionStatus.cancelled => Tone.neutral,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(session.topic, style: AppText.titleS)),
              StatusBadge(session.status.label, tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('EEE d MMM y · HH:mm').format(session.scheduledAt.toLocal())} · ${session.durationMinutes} min · ${session.meetingMode}',
            style: AppText.caption.copyWith(color: p.textMuted),
          ),
          if (session.meetingLink.isNotEmpty) ...[
            const SizedBox(height: 6),
            TextLink(
              displayUrl(session.meetingLink),
              onTap: () => openLink(context, session.meetingLink),
            ),
          ],
          if (session.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${session.notes}',
              style: AppText.bodyS.copyWith(color: p.textSecondary),
            ),
          ],
          if (canCompleteOrEdit || canCancel) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (canCompleteOrEdit && isMentor) ...[
                  AppButton(
                    session.notes.isEmpty ? 'Add notes' : 'Edit notes',
                    size: ButtonSize.small,
                    variant: ButtonVariant.secondary,
                    expand: false,
                    onPressed: onEditNotes,
                  ),
                  AppButton(
                    'Complete',
                    size: ButtonSize.small,
                    variant: ButtonVariant.primary,
                    expand: false,
                    onPressed: onComplete,
                  ),
                ],
                if (canCancel)
                  AppButton(
                    'Cancel',
                    size: ButtonSize.small,
                    variant: ButtonVariant.dangerOutline,
                    expand: false,
                    onPressed: onCancel,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
