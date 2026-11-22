import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorMenteesScreen extends ConsumerStatefulWidget {
  const MentorMenteesScreen({super.key});

  @override
  ConsumerState<MentorMenteesScreen> createState() =>
      _MentorMenteesScreenState();
}

class _MentorMenteesScreenState extends ConsumerState<MentorMenteesScreen> {
  String _filter = 'Active';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final uid = ref.watch(appSessionProvider).asData?.value.uid;

    if (uid == null) {
      return PageFrame(
        largeTitle: l10n.tabMentorMentees,
        children: const [SizedBox(height: 16), SkeletonDashboardLoader()],
      );
    }

    final mentorshipsAsync = ref.watch(mentorMentorshipsProvider(uid));

    return PageFrame(
      largeTitle: l10n.tabMentorMentees,
      subtitle: 'Active & completed mentorship pairings',
      onRefresh: () async => ref.invalidate(mentorMentorshipsProvider(uid)),
      children: [
        const SizedBox(height: 12),
        ChipBar(
          options: const ['Active', 'Completed', 'Ended', 'All'],
          selected: _filter,
          padding: EdgeInsets.zero,
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 16),
        mentorshipsAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load mentees',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(mentorMentorshipsProvider(uid)),
          ),
          data: (items) {
            final filtered = items
                .where(
                  (m) => switch (_filter) {
                    'Active' => m.status == MentorshipStatus.active,
                    'Completed' => m.status == MentorshipStatus.completed,
                    'Ended' => m.status == MentorshipStatus.ended,
                    _ => true,
                  },
                )
                .toList(growable: false);

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No ${_filter.toLowerCase()} mentees',
                body:
                    'Accepted mentorship requests become active mentees here.',
              );
            }

            return Column(
              children: [
                for (final m in filtered) ...[
                  SurfaceCard(
                    onTap: () => context.push('/mentorship/${m.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(
                              initialsOf(m.studentName),
                              tone: Tone.info,
                              size: 42,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.studentName, style: AppText.titleS),
                                  Text(
                                    'Started ${DateFormat('d MMM y').format(m.createdAt.toLocal())}',
                                    style: AppText.caption.copyWith(
                                      color: p.textMuted,
                                    ),
                                  ),
                                ],
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
                          const SizedBox(height: 8),
                          Text(
                            m.goalSummary,
                            style: AppText.bodyS.copyWith(
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                        Divider(height: 20, color: p.borderSubtle),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppButton(
                              'Workspace & sessions',
                              size: ButtonSize.small,
                              expand: false,
                              onPressed: () =>
                                  context.push('/mentorship/${m.id}'),
                            ),
                            AppButton(
                              'View student CV',
                              size: ButtonSize.small,
                              variant: ButtonVariant.secondary,
                              expand: false,
                              onPressed: () =>
                                  context.push('/user-profile/${m.studentUid}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
