// Groups listing moderation, reports, and forwarding work for admins.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// AD6 · Listings, AD9 · applications to forward, plus reported listings.
class AdminJobsScreen extends ConsumerStatefulWidget {
  const AdminJobsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends ConsumerState<AdminJobsScreen> {
  late int _tab = widget.initialTab;

  @override
  void didUpdateWidget(AdminJobsScreen old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final listings = data.opportunities.where((o) => o.state != ListingState.reported).toList();
    final forwards = data.forwards;
    final waiting = forwards.where((f) => !f.forwarded).length;
    final reported = data.opportunities.where((o) => o.state == ListingState.reported).toList();

    final Widget body = switch (_tab) {
      0 => _Listings(listings: listings),
      1 => _Forwards(items: forwards, data: data),
      _ => _Reported(items: reported),
    };

    return PageFrame(
      largeTitle: 'Jobs',
      eyebrow: '${listings.where((o) => o.state == ListingState.open).length} shown of 27 open · $waiting to forward',
      actions: [
        CircleIconButton(icon: Icons.add_rounded, tooltip: 'Add listing', onTap: () => context.push('/a-new-listing')),
        const SizedBox(width: 4),
      ],
      children: [
        const SizedBox(height: 12),
        SegmentedTabs(
          tabs: const ['Listings', 'To forward', 'Reported'],
          counts: [null, waiting, reported.length],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        TabBodySwitcher(index: _tab, child: body),
      ],
    );
  }
}

class _Listings extends StatelessWidget {
  const _Listings({required this.listings});

  final List<Opportunity> listings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListGroup(
          children: [
            for (final o in listings)
              ListRow(
                leading: OrgTile(opportunity: o, size: 40),
                title: o.title,
                subtitle: '${o.org} · ${o.place}',
                meta: '${o.applicants} applicants · closes ${o.closes}',
                trailing: StatusBadge(
                  switch (o.state) {
                    ListingState.open => 'Open',
                    ListingState.draft => 'Draft',
                    ListingState.closed => 'Closed',
                    ListingState.removed => 'Removed',
                    ListingState.reported => 'Reported',
                  },
                  tone: switch (o.state) {
                    ListingState.open => Tone.success,
                    ListingState.removed => Tone.danger,
                    _ => Tone.neutral,
                  },
                ),
                onTap: () => context.push('/a-listing/${o.id}'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppButton('Add listing', variant: ButtonVariant.secondary, leadingIcon: Icons.add_rounded, onPressed: () => context.push('/a-new-listing')),
      ],
    );
  }
}

class _Forwards extends StatelessWidget {
  const _Forwards({required this.items, required this.data});

  final List<ForwardItem> items;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.forward_to_inbox_outlined, title: 'Nothing to forward', body: 'Applications appear here after youth send them.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NoticeCard(
          tone: Tone.info,
          icon: Icons.fact_check_outlined,
          title: 'Check, then forward',
          body: 'Confirm the evidence is mentor-approved and the contact details work before the employer sees it.',
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < items.length; i++)
          Reveal(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ForwardCard(f: items[i], opp: data.opportunity(items[i].oppId)),
            ),
          ),
      ],
    );
  }
}

class _ForwardCard extends StatelessWidget {
  const _ForwardCard({required this.f, required this.opp});

  final ForwardItem f;
  final Opportunity? opp;

  @override
  Widget build(BuildContext context) {
    final passed = f.checks.where((c) => c.passed).length;
    return SurfaceCard(
      onTap: () => context.push('/a-forward/${f.id}'),
      accentEdge: f.forwarded ? AppColors.successText : (passed == f.checks.length ? AppColors.infoText : AppColors.warningText),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(f.initials, tone: Tone.accent, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.youthName, style: AppText.bodyMStrong),
                    Text('→ ${opp?.org ?? ''} · ${opp?.title ?? ''}', style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StatusBadge(
                f.forwarded ? 'Forwarded' : (passed == f.checks.length ? 'Ready' : 'Check needed'),
                tone: f.forwarded ? Tone.success : (passed == f.checks.length ? Tone.info : Tone.warning),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(f.evidence, style: AppText.bodyS),
          const SizedBox(height: 6),
          MonoLabel('$passed of ${f.checks.length} checks · ${f.sentOn}'),
        ],
      ),
    );
  }
}

class _Reported extends StatelessWidget {
  const _Reported({required this.items});

  final List<Opportunity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.verified_user_outlined, title: 'No reported listings', body: 'Youth can report a listing from its detail page.');
    }
    return Column(
      children: [
        for (final o in items)
          SurfaceCard(
            accentEdge: AppColors.dangerText,
            onTap: () => context.push('/a-listing/${o.id}'),
            child: Row(
              children: [
                OrgTile(opportunity: o, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.title, style: AppText.bodyMStrong),
                      Text(o.org, style: AppText.bodyS),
                      const SizedBox(height: 4),
                      MonoLabel('${o.reports} reports · ${o.applicants} applicants', color: AppColors.dangerText),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
      ],
    );
  }
}
