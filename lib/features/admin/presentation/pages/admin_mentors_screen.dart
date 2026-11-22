import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class AdminMentorsScreen extends ConsumerStatefulWidget {
  const AdminMentorsScreen({super.key});

  @override
  ConsumerState<AdminMentorsScreen> createState() => _AdminMentorsScreenState();
}

class _AdminMentorsScreenState extends ConsumerState<AdminMentorsScreen> {
  int _tabIndex = 0;
  String _appFilter = 'Pending';
  MentorshipStatus? _mentorshipFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final appsAsync = ref.watch(allMentorApplicationsProvider);
    final mentorshipsAsync = ref.watch(
      adminMentorshipsProvider(_mentorshipFilter),
    );
    final pendingCount = (appsAsync.asData?.value ?? const [])
        .where((a) => a.status == MentorApplicationStatus.pending)
        .length;

    return PageFrame(
      largeTitle: l10n.tabAdminMentors,
      subtitle: 'Mentor verification & mentorship monitoring',
      onRefresh: () async {
        ref.invalidate(allMentorApplicationsProvider);
        ref.invalidate(adminMentorshipsProvider(_mentorshipFilter));
      },
      children: [
        const SizedBox(height: 12),
        SegmentedTabs(
          tabs: const ['Applications', 'Mentorships'],
          counts: [pendingCount > 0 ? pendingCount : null, null],
          index: _tabIndex,
          onChanged: (i) => setState(() => _tabIndex = i),
        ),
        const SizedBox(height: 12),
        if (_tabIndex == 0) ...[
          ChipBar(
            options: const ['Pending', 'Approved', 'Rejected', 'Revoked', 'All'],
            selected: _appFilter,
            padding: EdgeInsets.zero,
            onSelected: (v) => setState(() => _appFilter = v),
          ),
          const SizedBox(height: 16),
          appsAsync.when(
            loading: () => const SkeletonListLoader(rows: 3),
            error: (error, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load mentor applications',
              body: errorMessage(error),
              action: l10n.retry,
              onAction: () => ref.invalidate(allMentorApplicationsProvider),
            ),
            data: (apps) {
              final filtered = apps
                  .where(
                    (a) => switch (_appFilter) {
                      'Pending' => a.status == MentorApplicationStatus.pending,
                      'Approved' =>
                        a.status == MentorApplicationStatus.approved,
                      'Rejected' =>
                        a.status == MentorApplicationStatus.rejected,
                      'Revoked' => a.status == MentorApplicationStatus.revoked,
                      _ => true,
                    },
                  )
                  .toList(growable: false);

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.how_to_reg_outlined,
                  title: 'No ${_appFilter.toLowerCase()} applications',
                  body:
                      'Submitted mentor applications appear here for admin review.',
                );
              }

              return Column(
                children: [
                  for (final app in filtered) ...[
                    SurfaceCard(
                      onTap: () => context.push('/a-applicant/${app.ownerUid}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppAvatar(
                                initialsOf(app.applicantName),
                                tone: Tone.info,
                                size: 42,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.applicantName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.titleS.copyWith(
                                        color: p.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      app.headline,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.bodyS.copyWith(
                                        color: p.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                app.status.label,
                                tone: switch (app.status) {
                                  MentorApplicationStatus.pending =>
                                    Tone.warning,
                                  MentorApplicationStatus.approved =>
                                    Tone.success,
                                  MentorApplicationStatus.rejected =>
                                    Tone.danger,
                                  MentorApplicationStatus.revoked =>
                                    Tone.warning,
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${app.experienceYears} yrs · ${app.expertise.take(3).join(', ')} · Submitted ${DateFormat('d MMM y').format(app.createdAt.toLocal())}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.caption.copyWith(
                                    color: p.textMuted,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: p.textMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ] else ...[
          ChipBar(
            options: [
              'All',
              MentorshipStatus.active.label,
              MentorshipStatus.completed.label,
              MentorshipStatus.ended.label,
            ],
            selected: _mentorshipFilter == null
                ? 'All'
                : _mentorshipFilter!.label,
            padding: EdgeInsets.zero,
            onSelected: (label) => setState(() {
              _mentorshipFilter = switch (label) {
                'Active' => MentorshipStatus.active,
                'Completed' => MentorshipStatus.completed,
                'Ended' => MentorshipStatus.ended,
                _ => null,
              };
            }),
          ),
          const SizedBox(height: 16),
          mentorshipsAsync.when(
            loading: () => const SkeletonListLoader(rows: 3),
            error: (error, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load mentorships',
              body: errorMessage(error),
              action: l10n.retry,
              onAction: () =>
                  ref.invalidate(adminMentorshipsProvider(_mentorshipFilter)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.handshake_outlined,
                  title: 'No mentorship records found',
                  body:
                      'Active, completed, and ended student-mentor pairings appear here.',
                );
              }
              return Column(
                children: [
                  for (final m in items) ...[
                    SurfaceCard(
                      onTap: () => context.push('/mentorship/${m.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${m.studentName} ↔ ${m.mentorName}',
                                  style: AppText.titleS.copyWith(
                                    color: p.textPrimary,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                m.status.label,
                                tone: switch (m.status) {
                                  MentorshipStatus.active => Tone.success,
                                  MentorshipStatus.completed => Tone.info,
                                  MentorshipStatus.ended => Tone.neutral,
                                },
                              ),
                            ],
                          ),
                          if (m.goalSummary.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              m.goalSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyS.copyWith(
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Updated ${DateFormat('d MMM y').format(m.updatedAt.toLocal())}${m.feedbackRating != null ? ' · Rated ${m.feedbackRating}/5' : ''}',
                            style: AppText.caption.copyWith(color: p.textMuted),
                          ),
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
      ],
    );
  }
}
