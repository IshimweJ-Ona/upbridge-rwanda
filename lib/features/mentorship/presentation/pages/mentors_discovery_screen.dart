import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorsDiscoveryScreen extends ConsumerStatefulWidget {
  const MentorsDiscoveryScreen({super.key});

  @override
  ConsumerState<MentorsDiscoveryScreen> createState() =>
      _MentorsDiscoveryScreenState();
}

class _MentorsDiscoveryScreenState
    extends ConsumerState<MentorsDiscoveryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _expertiseFilter = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelPendingRequest(MentorRequest request) async {
    final confirm = await showAppDialog(
      context,
      title: 'Cancel request?',
      body: 'Withdraw your mentorship request to ${request.mentorName}?',
      confirmLabel: 'Cancel request',
      destructive: true,
    );
    if (!confirm || !mounted) return;
    try {
      await ref.read(mentorshipRepositoryProvider).cancelRequest(request.id);
      if (mounted) {
        showToast(context, 'Request cancelled', tone: Tone.warning);
      }
    } catch (error) {
      if (mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;

    final mentorsAsync = ref.watch(approvedMentorsProvider);
    final requests = uid == null
        ? const <MentorRequest>[]
        : ref.watch(studentRequestsProvider(uid)).asData?.value ??
              const <MentorRequest>[];
    final mentorships = uid == null
        ? const <Mentorship>[]
        : ref.watch(studentMentorshipsProvider(uid)).asData?.value ??
              const <Mentorship>[];

    final activeMentorshipByMentor = <String, Mentorship>{
      for (final m in mentorships)
        if (m.status == MentorshipStatus.active) m.mentorUid: m,
    };
    final pendingRequestByMentor = <String, MentorRequest>{
      for (final r in requests)
        if (r.status == MentorRequestStatus.pending) r.mentorUid: r,
    };
    final activeMentorships = mentorships
        .where((m) => m.status == MentorshipStatus.active)
        .toList(growable: false);
    final pendingRequests = requests
        .where((r) => r.status == MentorRequestStatus.pending)
        .toList(growable: false);

    return PageFrame(
      largeTitle: l10n.tabMentors,
      subtitle: 'Verified IT & career mentors in Rwanda',
      onRefresh: () async {
        ref.invalidate(approvedMentorsProvider);
        if (uid != null) {
          ref.invalidate(studentRequestsProvider(uid));
          ref.invalidate(studentMentorshipsProvider(uid));
        }
      },
      children: [
        const SizedBox(height: 12),
        if (activeMentorships.isNotEmpty) ...[
          for (final m in activeMentorships) ...[
            SurfaceCard(
              padding: EdgeInsets.zero,
              accentEdge: context.palette.successText,
              child: ListRow(
                onTap: () => context.push('/mentorship/${m.id}'),
                leading: AppAvatar(
                  initialsOf(m.mentorName),
                  tone: Tone.success,
                  size: 40,
                ),
                title: 'Active mentorship with ${m.mentorName}',
                subtitle: m.goalSummary.isEmpty
                    ? 'Open workspace to schedule 1-on-1 sessions'
                    : m.goalSummary,
                trailing: const StatusBadge('Active', tone: Tone.success),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (pendingRequests.isNotEmpty) ...[
          SectionLabel('Pending requests (${pendingRequests.length})', top: 8),
          for (final req in pendingRequests) ...[
            SurfaceCard(
              onTap: () => context.push('/mentor/${req.mentorUid}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        initialsOf(req.mentorName),
                        tone: Tone.warning,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req.mentorName, style: AppText.bodyMStrong),
                            Text(
                              req.goals.isEmpty ? req.message : req.goals,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyS.copyWith(
                                color: context.palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const StatusBadge('Pending', tone: Tone.warning),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      'Withdraw',
                      size: ButtonSize.small,
                      variant: ButtonVariant.ghost,
                      expand: false,
                      onPressed: () => _cancelPendingRequest(req),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
        ],
        AppSearchField(
          controller: _searchCtrl,
          hint: 'Search mentor name, expertise, skill, or city',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        mentorsAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load mentors',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(approvedMentorsProvider),
          ),
          data: (mentors) {
            final expertiseOptions = _buildExpertiseFilters(mentors);
            final selectedChip = expertiseOptions.contains(_expertiseFilter)
                ? _expertiseFilter
                : 'All';
            final q = _query.trim().toLowerCase();

            final filtered = mentors
                .where((m) {
                  if (uid != null && m.ownerUid == uid) return false;
                  final expertiseMatch =
                      selectedChip == 'All' ||
                      m.mentorExpertise.any(
                        (e) => e.toLowerCase() == selectedChip.toLowerCase(),
                      );
                  if (!expertiseMatch) return false;
                  if (q.isEmpty) return true;
                  return m.displayName.toLowerCase().contains(q) ||
                      m.headline.toLowerCase().contains(q) ||
                      m.location.toLowerCase().contains(q) ||
                      m.mentorExpertise.any(
                        (e) => e.toLowerCase().contains(q),
                      ) ||
                      m.skills.any((s) => s.toLowerCase().contains(q));
                })
                .toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (expertiseOptions.length > 1) ...[
                  ChipBar(
                    options: expertiseOptions,
                    selected: selectedChip,
                    padding: EdgeInsets.zero,
                    onSelected: (v) => setState(() => _expertiseFilter = v),
                  ),
                  const SizedBox(height: 14),
                ],
                if (mentors.isEmpty)
                  EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: l10n.noMentorsYet,
                    body: l10n.noMentorsBody,
                  )
                else if (filtered.isEmpty)
                  EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching mentors',
                    body: 'Try another keyword or clear your expertise filter.',
                    action: 'Clear filters',
                    onAction: () {
                      _searchCtrl.clear();
                      setState(() {
                        _query = '';
                        _expertiseFilter = 'All';
                      });
                    },
                  )
                else
                  for (final mentor in filtered) ...[
                    _MentorDirectoryCard(
                      mentor: mentor,
                      activeMentorship:
                          activeMentorshipByMentor[mentor.ownerUid],
                      pendingRequest: pendingRequestByMentor[mentor.ownerUid],
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
        if (mentorships.any((m) => m.status != MentorshipStatus.active)) ...[
          const SectionLabel('Past mentorships'),
          for (final past in mentorships.where(
            (m) => m.status != MentorshipStatus.active,
          )) ...[
            SurfaceCard(
              onTap: () => context.push('/mentorship/${past.id}'),
              child: ListRow(
                padding: EdgeInsets.zero,
                leading: AppAvatar(initialsOf(past.mentorName), size: 40),
                title: past.mentorName,
                subtitle: past.goalSummary.isEmpty
                    ? 'View sessions & feedback'
                    : past.goalSummary,
                trailing: StatusBadge(
                  past.status.label,
                  tone: past.status == MentorshipStatus.completed
                      ? Tone.info
                      : Tone.neutral,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  List<String> _buildExpertiseFilters(List<UserProfile> mentors) {
    final seen = <String>{};
    for (final m in mentors) {
      for (final e in m.mentorExpertise) {
        final trimmed = e.trim();
        if (trimmed.isNotEmpty) seen.add(trimmed);
      }
    }
    return ['All', ...seen.take(10)];
  }
}

class _MentorDirectoryCard extends StatelessWidget {
  const _MentorDirectoryCard({
    required this.mentor,
    required this.activeMentorship,
    required this.pendingRequest,
  });

  final UserProfile mentor;
  final Mentorship? activeMentorship;
  final MentorRequest? pendingRequest;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = mentor.displayName.isEmpty
        ? 'Verified Mentor'
        : mentor.displayName;
    final photoUrl = mentor.photoAsset?.url;

    return SurfaceCard(
      onTap: () => context.push('/mentor/${mentor.ownerUid}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (photoUrl != null && photoUrl.isNotEmpty)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        AppAvatar(initialsOf(name), size: 48),
                  ),
                )
              else
                AppAvatar(initialsOf(name), tone: Tone.accent, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.titleS),
                    if (mentor.headline.isNotEmpty)
                      Text(
                        mentor.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyS.copyWith(color: p.textSecondary),
                      ),
                    Text(
                      [
                        if (mentor.location.isNotEmpty) mentor.location,
                        if (mentor.mentorExperienceYears > 0)
                          '${mentor.mentorExperienceYears} yrs exp',
                      ].join(' · '),
                      style: AppText.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              if (activeMentorship != null)
                const StatusBadge('Mentoring', tone: Tone.success)
              else if (pendingRequest != null)
                const StatusBadge('Requested', tone: Tone.warning)
              else
                Icon(Icons.chevron_right_rounded, color: p.textMuted),
            ],
          ),
          if (mentor.mentorExpertise.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: mentor.mentorExpertise
                  .take(4)
                  .map((item) => StatusBadge(item, tone: Tone.neutral))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}
