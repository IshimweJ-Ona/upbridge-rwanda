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
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorRequestsScreen extends ConsumerStatefulWidget {
  const MentorRequestsScreen({super.key});

  @override
  ConsumerState<MentorRequestsScreen> createState() =>
      _MentorRequestsScreenState();
}

class _MentorRequestsScreenState extends ConsumerState<MentorRequestsScreen> {
  String _filter = 'Pending';
  final Set<String> _busyIds = {};

  Future<void> _accept(MentorRequest request) async {
    setState(() => _busyIds.add(request.id));
    try {
      final mentorshipId = await ref
          .read(mentorshipRepositoryProvider)
          .acceptRequest(requestId: request.id);
      if (!mounted) return;
      showToast(context, 'Mentorship active with ${request.studentName}');
      context.push('/mentorship/$mentorshipId');
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  Future<void> _decline(MentorRequest request) async {
    final note = await showTextPromptSheet(
      context,
      title: 'Decline request',
      fieldLabel: 'Response note (optional)',
      hint: 'Let the student know why or suggest another timeframe',
      confirmLabel: 'Confirm decline',
      destructive: true,
    );
    if (note == null || !mounted) return;

    setState(() => _busyIds.add(request.id));
    try {
      await ref
          .read(mentorshipRepositoryProvider)
          .declineRequest(requestId: request.id, responseNote: note);
      if (mounted) showToast(context, 'Request declined', tone: Tone.warning);
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final uid = ref.watch(appSessionProvider).asData?.value.uid;

    if (uid == null) {
      return PageFrame(
        largeTitle: l10n.tabMentorRequests,
        children: const [SizedBox(height: 16), SkeletonDashboardLoader()],
      );
    }

    final requestsAsync = ref.watch(mentorRequestsProvider(uid));

    return PageFrame(
      largeTitle: l10n.tabMentorRequests,
      subtitle: 'Review incoming student mentorship requests',
      onRefresh: () async => ref.invalidate(mentorRequestsProvider(uid)),
      children: [
        const SizedBox(height: 12),
        ChipBar(
          options: const ['Pending', 'Accepted', 'Declined', 'All'],
          selected: _filter,
          padding: EdgeInsets.zero,
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 16),
        requestsAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load requests',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(mentorRequestsProvider(uid)),
          ),
          data: (items) {
            final filtered = items
                .where(
                  (r) => switch (_filter) {
                    'Pending' => r.status == MentorRequestStatus.pending,
                    'Accepted' => r.status == MentorRequestStatus.accepted,
                    'Declined' =>
                      r.status == MentorRequestStatus.declined ||
                          r.status == MentorRequestStatus.cancelled,
                    _ => true,
                  },
                )
                .toList(growable: false);

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No ${_filter.toLowerCase()} requests',
                body: 'New requests from students appear here in real time.',
              );
            }

            return Column(
              children: [
                for (final req in filtered) ...[
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(
                              initialsOf(req.studentName),
                              tone: Tone.info,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req.studentName, style: AppText.titleS),
                                  Text(
                                    DateFormat('d MMM y')
                                        .format(req.createdAt.toLocal()),
                                    style: AppText.caption.copyWith(
                                      color: p.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              req.status.label,
                              tone: switch (req.status) {
                                MentorRequestStatus.pending => Tone.warning,
                                MentorRequestStatus.accepted => Tone.success,
                                MentorRequestStatus.declined => Tone.danger,
                                MentorRequestStatus.cancelled => Tone.neutral,
                              },
                            ),
                          ],
                        ),
                        if (req.goals.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Goal: ${req.goals}',
                            style: AppText.bodySStrong,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          req.message,
                          style: AppText.bodyS.copyWith(color: p.textSecondary),
                        ),
                        if (req.responseNote.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Your note: ${req.responseNote}',
                            style: AppText.caption.copyWith(color: p.textMuted),
                          ),
                        ],
                        Divider(height: 20, color: p.borderSubtle),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppButton(
                              'View student CV',
                              size: ButtonSize.small,
                              variant: ButtonVariant.ghost,
                              expand: false,
                              onPressed: () => context.push(
                                '/user-profile/${req.studentUid}',
                              ),
                            ),
                            if (req.status == MentorRequestStatus.pending) ...[
                              AppButton(
                                'Accept',
                                size: ButtonSize.small,
                                expand: false,
                                loading: _busyIds.contains(req.id),
                                onPressed: () => _accept(req),
                              ),
                              AppButton(
                                'Decline',
                                size: ButtonSize.small,
                                variant: ButtonVariant.dangerOutline,
                                expand: false,
                                onPressed: _busyIds.contains(req.id)
                                    ? null
                                    : () => _decline(req),
                              ),
                            ] else if (req.status ==
                                MentorRequestStatus.accepted)
                              AppButton(
                                'Open mentorship',
                                size: ButtonSize.small,
                                variant: ButtonVariant.secondary,
                                expand: false,
                                onPressed: () =>
                                    context.push('/mentorship/${req.id}'),
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
