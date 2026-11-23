import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/mentorship/presentation/widgets/book_session_sheet.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorDetailScreen extends ConsumerStatefulWidget {
  const MentorDetailScreen({super.key, required this.mentorUid});

  final String mentorUid;

  @override
  ConsumerState<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends ConsumerState<MentorDetailScreen> {
  final _goalsCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _goalsCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest({
    required AppSession session,
    required UserProfile? studentProfile,
    required UserProfile mentor,
  }) async {
    FocusScope.of(context).unfocus();
    final goals = _goalsCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (message.length < 15) {
      setState(
        () => _error = 'Write at least 15 characters introducing yourself and what help you need.',
      );
      return;
    }

    final uid = session.uid;
    if (uid == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final now = DateTime.now().toUtc();
      await ref
          .read(mentorshipRepositoryProvider)
          .sendRequest(
            MentorRequest(
              id: '',
              ownerUid: uid,
              studentUid: uid,
              studentName: studentProfile?.displayName.isNotEmpty == true
                  ? studentProfile!.displayName
                  : session.displayLabel,
              studentPhotoUrl: studentProfile?.photoAsset?.url ?? '',
              mentorUid: mentor.ownerUid,
              mentorName: mentor.displayName.isEmpty
                  ? 'Mentor'
                  : mentor.displayName,
              mentorPhotoUrl: mentor.photoAsset?.url ?? '',
              message: message,
              goals: goals,
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (mounted) {
        _goalsCtrl.clear();
        _messageCtrl.clear();
        showToast(context, 'Mentorship request sent');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openBookSession({
    required AppSession session,
    required UserProfile? studentProfile,
    required UserProfile mentor,
    required Mentorship? activeMentorship,
  }) async {
    final uid = session.uid;
    if (uid == null) return;
    final actorName = studentProfile?.displayName.trim().isNotEmpty == true
        ? studentProfile!.displayName.trim()
        : session.displayLabel;
    final booked = await showBookSessionSheet(
      context,
      actorUid: uid,
      actorName: actorName,
      mentorship: activeMentorship,
      mentor: activeMentorship == null ? mentor : null,
      submitLabel: 'Book session',
      title: 'Book 1-on-1 session',
    );
    if (booked && mounted) {
      showToast(context, 'Session booked with ${mentor.displayName.isEmpty ? "mentor" : mentor.displayName}');
    }
  }

  Future<void> _cancelRequest(MentorRequest request) async {
    final confirm = await showAppDialog(
      context,
      title: 'Withdraw request?',
      body: 'Cancel your pending mentorship request to ${request.mentorName}?',
      confirmLabel: 'Withdraw',
      destructive: true,
    );
    if (!confirm || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(mentorshipRepositoryProvider).cancelRequest(request.id);
      if (mounted) {
        showToast(context, 'Request cancelled', tone: Tone.warning);
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final currentUid = session?.uid;

    final mentorAsync = ref.watch(userProfileProvider(widget.mentorUid));
    final studentProfile = currentUid == null
        ? null
        : ref.watch(userProfileProvider(currentUid)).asData?.value;
    final requests = currentUid == null
        ? const <MentorRequest>[]
        : ref.watch(studentRequestsProvider(currentUid)).asData?.value ??
              const <MentorRequest>[];
    final mentorships = currentUid == null
        ? const <Mentorship>[]
        : ref.watch(studentMentorshipsProvider(currentUid)).asData?.value ??
              const <Mentorship>[];
    final sessionsWithMentor = currentUid == null
        ? const <MentorshipSession>[]
        : (ref.watch(studentSessionsProvider(currentUid)).asData?.value ??
                  const <MentorshipSession>[])
              .where((s) => s.mentorUid == widget.mentorUid)
              .toList(growable: false);

    final activeMentorship = mentorships
        .where(
          (m) =>
              m.mentorUid == widget.mentorUid &&
              m.status == MentorshipStatus.active,
        )
        .firstOrNull;
    final pendingRequest = requests
        .where(
          (r) =>
              r.mentorUid == widget.mentorUid &&
              r.status == MentorRequestStatus.pending,
        )
        .firstOrNull;
    final latestDeclined = requests
        .where(
          (r) =>
              r.mentorUid == widget.mentorUid &&
              r.status == MentorRequestStatus.declined,
        )
        .firstOrNull;

    return mentorAsync.when(
      loading: () => const DetailPage(
        title: 'Mentor profile',
        backFallback: '/mentors',
        children: [SkeletonDashboardLoader(cards: 3)],
      ),
      error: (error, _) => DetailPage(
        title: 'Mentor profile',
        backFallback: '/mentors',
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load mentor',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () =>
                ref.invalidate(userProfileProvider(widget.mentorUid)),
          ),
        ],
      ),
      data: (mentor) {
        if (mentor == null) {
          return const DetailPage(
            title: 'Mentor profile',
            backFallback: '/mentors',
            children: [
              EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Mentor not found',
                body: 'This mentor profile may no longer be public.',
              ),
            ],
          );
        }

        final name = mentor.displayName.isEmpty
            ? 'Verified Mentor'
            : mentor.displayName;
        final photoUrl = mentor.photoAsset?.url;
        final bio = mentor.mentorBio.isNotEmpty
            ? mentor.mentorBio
            : mentor.about;
        final isSelf = currentUid != null && currentUid == mentor.ownerUid;

        return DetailPage(
          title: 'Mentor profile',
          backFallback: '/mentors',
          children: [
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        initialsOf(name),
                        imageUrl: photoUrl,
                        tone: Tone.info,
                        size: 58,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppText.titleM),
                            if (mentor.headline.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                mentor.headline,
                                style: AppText.bodyS.copyWith(
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (mentor.location.isNotEmpty) mentor.location,
                                if (mentor.mentorExperienceYears > 0)
                                  '${mentor.mentorExperienceYears} yrs experience',
                              ].join(' · '),
                              style: AppText.caption.copyWith(
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (mentor.mentorAvailability.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    StatusBadge(
                      'Availability: ${mentor.mentorAvailability}',
                      tone: Tone.info,
                    ),
                  ],
                ],
              ),
            ),
            if (bio.isNotEmpty) ...[
              const SectionLabel('About & mentoring focus'),
              SurfaceCard(
                child: Text(
                  bio,
                  style: AppText.bodyM.copyWith(color: p.textSecondary),
                ),
              ),
            ],
            if (mentor.mentorExpertise.isNotEmpty) ...[
              const SectionLabel('Expertise'),
              TagWrap(mentor.mentorExpertise, tone: Tone.info),
            ],
            if (mentor.skills.isNotEmpty) ...[
              const SectionLabel('Skills'),
              TagWrap(mentor.skills),
            ],
            if (mentor.professionalLinks.isNotEmpty) ...[
              const SectionLabel('Links'),
              ListGroup(
                children: [
                  for (final link in mentor.professionalLinks)
                    ListRow(
                      leading: const IconTile(
                        Icons.open_in_new_rounded,
                        tone: Tone.info,
                      ),
                      title: displayUrl(link),
                      onTap: () => openLink(context, link),
                    ),
                ],
              ),
            ],
            if (session != null &&
                !isSelf &&
                session.role == UserRole.student &&
                currentUid != null) ...[
              const SectionLabel('1-on-1 Sessions'),
              SurfaceCard(
                accentEdge: p.actionPrimary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book a 1-on-1 coaching session',
                      style: AppText.titleS,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mentor.mentorAvailability.isNotEmpty
                          ? 'Preferred availability: ${mentor.mentorAvailability}. Choose a topic, date, and format.'
                          : 'Pick a topic, date, time, and format (Online or In-person) with $name.',
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      'Book a session',
                      icon: Icons.event_available_outlined,
                      onPressed: () => _openBookSession(
                        session: session,
                        studentProfile: studentProfile,
                        mentor: mentor,
                        activeMentorship: activeMentorship,
                      ),
                    ),
                  ],
                ),
              ),
              if (sessionsWithMentor.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final s in sessionsWithMentor) ...[
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: ListRow(
                      onTap: () => showSessionDetailSheet(
                        context,
                        session: s,
                        actorUid: currentUid,
                        isMentor: false,
                      ),
                      leading: const IconTile(
                        Icons.videocam_outlined,
                        tone: Tone.info,
                      ),
                      title: s.topic,
                      subtitle:
                          '${DateFormat('EEE d MMM · HH:mm').format(s.scheduledAt.toLocal())} · ${s.durationMinutes} min · ${s.meetingMode}',
                      trailing: StatusBadge(
                        s.status.label,
                        tone: switch (s.status) {
                          SessionStatus.scheduled => Tone.info,
                          SessionStatus.completed => Tone.success,
                          SessionStatus.cancelled => Tone.neutral,
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
            const SectionLabel('Mentorship connection'),
            if (isSelf)
              const SurfaceCard(
                child: Text('This is your mentor directory profile.'),
              )
            else if (activeMentorship != null)
              SurfaceCard(
                accentEdge: p.successText,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusBadge(
                      'Active mentorship',
                      tone: Tone.success,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You already have an active mentorship with $name.',
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      'Open mentorship workspace',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          context.push('/mentorship/${activeMentorship.id}'),
                    ),
                  ],
                ),
              )
            else if (pendingRequest != null)
              SurfaceCard(
                accentEdge: p.warningText,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusBadge('Request pending', tone: Tone.warning),
                    const SizedBox(height: 8),
                    Text(
                      pendingRequest.message,
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                    if (pendingRequest.goals.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Goal: ${pendingRequest.goals}',
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                    ],
                    const SizedBox(height: 14),
                    AppButton(
                      'Withdraw request',
                      variant: ButtonVariant.dangerOutline,
                      loading: _submitting,
                      onPressed: () => _cancelRequest(pendingRequest),
                    ),
                  ],
                ),
              )
            else ...[
              if (latestDeclined != null) ...[
                SurfaceCard(
                  accentEdge: p.textMuted,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusBadge(
                        'Previous request declined',
                        tone: Tone.neutral,
                      ),
                      if (latestDeclined.responseNote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          latestDeclined.responseNote,
                          style: AppText.bodyS.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Your goal (optional)',
                      hint:
                          'e.g. Build a Flutter portfolio project for internships',
                      controller: _goalsCtrl,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Message to mentor',
                      hint:
                          'Share your background, current learning focus, and what you hope to achieve.',
                      controller: _messageCtrl,
                      maxLines: 4,
                      error: _error,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      'Request mentorship',
                      loading: _submitting,
                      onPressed: session == null
                          ? null
                          : () => _sendRequest(
                              session: session,
                              studentProfile: studentProfile,
                              mentor: mentor,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
