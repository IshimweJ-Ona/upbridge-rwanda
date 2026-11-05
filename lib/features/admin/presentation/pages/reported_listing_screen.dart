// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// AD8 · Reported listing ("Online typing job" — fee scam), and moderation of any listing.
class ReportedListingScreen extends ConsumerWidget {
  const ReportedListingScreen({super.key, required this.listingId});

  final String listingId;

  static const _reports = [
    ('Asked me to pay RWF 15,000 on mobile money before they send any work.', 'TODAY · 09:40'),
    ('There is no company name or address, only a WhatsApp number.', 'YESTERDAY · 18:12'),
    ('The same advert is in a Facebook group under a different name.', 'THU 15 OCT · 21:05'),
  ];

  Future<void> _remove(BuildContext context, WidgetRef ref, Opportunity o) async {
    final ok = await showAppDialog(
      context,
      title: 'Remove “${o.title}”?',
      body: 'It disappears for everyone. The ${o.applicants} people who applied get an SMS warning them not to pay any fee.',
      confirmLabel: 'Remove listing',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok) return;
    ref.read(appStoreProvider.notifier).setListingState(o.id, ListingState.removed);
    if (!context.mounted) return;
    showToast(context, 'Listing removed · ${o.applicants} applicants warned by SMS', icon: Icons.delete_outline_rounded, tone: Tone.warning);
    goBack(context, fallback: '/a/jobs?tab=reported');
  }

  Future<void> _close(BuildContext context, WidgetRef ref, Opportunity o) async {
    final ok = await showAppDialog(
      context,
      title: 'Close applications early?',
      body: 'Youth who already applied keep their applications. ${o.org} still has to reply by ${o.repliesBy}.',
      confirmLabel: 'Close listing',
      destructive: true,
      icon: Icons.lock_clock_outlined,
    );
    if (!ok) return;
    ref.read(appStoreProvider.notifier).setListingState(o.id, ListingState.closed);
    if (context.mounted) showToast(context, 'Listing closed', icon: Icons.lock_clock_outlined, tone: Tone.info);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = ref.watch(appStoreProvider.select((s) => s.opportunity(listingId)));
    if (o == null) {
      return const DetailPage(
        title: 'Listing',
        backFallback: '/a/jobs',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.work_off_outlined, title: 'Listing not found')],
      );
    }
    final reported = o.state == ListingState.reported;

    final footer = switch (o.state) {
      ListingState.reported => [
          AppButton('Remove listing', variant: ButtonVariant.danger, leadingIcon: Icons.delete_outline_rounded, onPressed: () => _remove(context, ref, o)),
          AppButton(
            'Keep listing',
            variant: ButtonVariant.secondary,
            onPressed: () {
              ref.read(appStoreProvider.notifier).setListingState(o.id, ListingState.open);
              showToast(context, 'Reports dismissed · listing stays open', icon: Icons.check_rounded);
              goBack(context, fallback: '/a/jobs');
            },
          ),
        ],
      ListingState.open => [
          AppButton('Close listing early', variant: ButtonVariant.dangerOutline, onPressed: () => _close(context, ref, o)),
        ],
      _ => <Widget>[],
    };

    return DetailPage(
      title: reported ? 'Reported listing' : 'Listing',
      backFallback: '/a/jobs',
      footer: footer.isEmpty ? null : footer,
      children: [
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: Motion.base,
          child: switch (o.state) {
            ListingState.reported => NoticeCard(
                key: const ValueKey('reported'),
                tone: Tone.danger,
                icon: Icons.flag_rounded,
                title: '${o.reports} reports · likely fee scam',
                body: o.reportReason,
              ),
            ListingState.removed => const NoticeCard(
                key: ValueKey('removed'),
                tone: Tone.neutral,
                icon: Icons.delete_outline_rounded,
                title: 'Removed today',
                body: 'Applicants were warned by SMS. The poster can’t list again.',
              ),
            ListingState.closed => const NoticeCard(key: ValueKey('closed'), icon: Icons.lock_clock_outlined, title: 'Applications closed'),
            _ => NoticeCard(key: const ValueKey('open'), tone: Tone.success, icon: Icons.check_circle_outline_rounded, title: 'Open · ${o.applicants} applicants', body: 'Closes ${o.closes}. Replies by ${o.repliesBy}.'),
          },
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrgTile(opportunity: o, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.title, style: AppText.titleL),
                  Text('${o.org} · ${o.place}', style: AppText.bodyS),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        KeyValueTable([
          ('Pay', o.pay),
          ('Posted', '${o.posted.replaceFirst('Posted ', '')} · ${o.postedBy}'),
          ('Applicants', '${o.applicants}'),
          ('Replies by', o.repliesBy),
        ]),
        const SectionLabel('Listing text'),
        SurfaceCard(child: Text(o.about, style: AppText.bodyM)),
        if (reported) ...[
          SectionLabel('Reports from youth · ${o.reports}'),
          ListGroup(
            children: [
              for (final r in _reports.take(o.reports))
                ListRow(
                  leading: const IconTile(Icons.flag_outlined, tone: Tone.danger),
                  title: '“${r.$1}”',
                  titleStyle: AppText.bodyS.copyWith(color: AppColors.textPrimary),
                  meta: '${r.$2} · anonymous',
                ),
            ],
          ),
          const SizedBox(height: 14),
          const NoticeCard(
            tone: Tone.info,
            icon: Icons.policy_outlined,
            title: 'UpBridge rule',
            body: 'No listing may ask applicants to pay to apply, train or start work.',
          ),
        ],
      ],
    );
  }
}
