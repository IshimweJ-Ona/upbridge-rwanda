// Shows the admin pilot overview with clearly labeled sample statistics and live user count when authenticated.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/admin/presentation/providers/admin_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/shared/shared.dart';

/// AD1 · Pilot overview — objectives and what needs attention.
class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final session = ref.watch(verifiedSessionProvider).asData?.value;
    final isLiveAdmin =
        session != null &&
        session.firebaseInitialized &&
        session.signedIn &&
        session.emailVerified &&
        session.role == Role.admin;
    final liveUserCountAsync = isLiveAdmin
        ? ref.watch(adminUserCountProvider)
        : null;

    final pendingMentors = data.applicants
        .where((a) => a.state == ApplicantState.pending)
        .length;
    final toForward = data.forwards.where((f) => !f.forwarded).length;
    final reported = data.opportunities
        .where((o) => o.state == ListingState.reported)
        .toList();
    final youth = 412;
    final mentors =
        18 +
        data.applicants.where((a) => a.state == ApplicantState.approved).length;
    final listings =
        27 -
        data.opportunities
            .where((o) => o.state == ListingState.removed)
            .length +
        (data.opportunities.length - SampleData.opportunities.length);
    const daysLeft = SampleData.pilotDays - SampleData.pilotDay;

    return PageFrame(
      largeTitle: 'Pilot overview',
      eyebrow: 'Day ${SampleData.pilotDay} of ${SampleData.pilotDays}',
      onRefresh: () async {
        if (isLiveAdmin) {
          ref.invalidate(adminUserCountProvider);
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      children: [
        const SizedBox(height: 14),
        const NoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Demonstration data',
          body: 'These sample figures are not live platform statistics.',
        ),
        if (isLiveAdmin) ...[
          const SizedBox(height: 12),
          ListGroup(
            children: [
              ListRow(
                leading: const IconTile(
                  Icons.cloud_done_outlined,
                  tone: Tone.info,
                ),
                title: 'Live Firestore accounts',
                subtitle: switch (liveUserCountAsync) {
                  AsyncData(:final value) =>
                    '$value registered users currently stored in Firestore',
                  AsyncError() => 'Could not fetch live Firestore user count',
                  _ => 'Loading live Firestore user count…',
                },
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/a/users'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Kigali · Huye · Musanze · Rubavu',
                style: AppText.bodyS,
              ),
            ),
            const MonoLabel('$daysLeft days left · ends 2 Nov'),
          ],
        ),
        const SizedBox(height: 8),
        const ProgressLine(
          SampleData.pilotDay / SampleData.pilotDays,
          color: AppColors.inverse,
        ),
        const SectionLabel('Needs your attention'),
        ListGroup(
          children: [
            _AttentionRow(
              icon: Icons.verified_user_outlined,
              tone: Tone.accent,
              title: 'Mentor applications',
              count: pendingMentors,
              detail: pendingMentors == 0
                  ? 'All checked'
                  : 'Background checks ready to review',
              onTap: () => context.go('/a/mentors'),
            ),
            _AttentionRow(
              icon: Icons.forward_to_inbox_outlined,
              tone: Tone.info,
              title: 'Applications to forward',
              count: toForward,
              detail: toForward == 0
                  ? 'Nothing waiting'
                  : 'Check evidence, then send to employers',
              onTap: () => context.go('/a/jobs?tab=forward'),
            ),
            _AttentionRow(
              icon: Icons.flag_outlined,
              tone: Tone.danger,
              title: 'Reported listing',
              count: reported.length,
              detail: reported.isEmpty
                  ? 'No open reports'
                  : '“${reported.first.title}” · ${reported.first.reports} reports',
              onTap: reported.isEmpty
                  ? () => context.go('/a/jobs?tab=reported')
                  : () => context.push('/a-listing/${reported.first.id}'),
            ),
          ],
        ),
        const SectionLabel('Pilot objectives'),
        ListGroup(
          children: [
            for (final o in SampleData.objectives) ObjectiveMeter(objective: o),
          ],
        ),
        const SectionLabel('People and listings (sample)'),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                value: youth,
                label: 'Youth',
                icon: Icons.school_outlined,
                tone: Tone.accent,
                onTap: () => context.go('/a/users'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                value: mentors,
                label: 'Verified mentors',
                icon: Icons.verified_user_outlined,
                tone: Tone.info,
                onTap: () => context.go('/a/mentors'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                value: listings,
                label: 'Open listings',
                icon: Icons.work_outline_rounded,
                tone: Tone.success,
                onTap: () => context.go('/a/jobs'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                value: youth + mentors + 3,
                label: 'All users (sample)',
                icon: Icons.groups_outlined,
                onTap: () => context.go('/a/users'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Sample figures shown above for pilot walkthrough',
            style: AppText.caption,
          ),
        ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.count,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Tone tone;
  final String title;
  final int count;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      leading: IconTile(icon, tone: count == 0 ? Tone.neutral : tone),
      title: title,
      subtitle: detail,
      trailing: AnimatedSwitcher(
        duration: Motion.base,
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: count == 0
            ? const Icon(
                Icons.check_circle_rounded,
                key: ValueKey('ok'),
                size: 20,
                color: AppColors.successText,
              )
            : Container(
                key: ValueKey(count),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tone.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: AppText.dataMonoStrong.copyWith(
                    color: tone.foreground,
                  ),
                ),
              ),
      ),
      onTap: onTap,
    );
  }
}
