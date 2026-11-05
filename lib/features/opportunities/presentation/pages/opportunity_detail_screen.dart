// Owner: Student 4 · Opportunities & applications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// J2 · Opportunity detail with an evidence match.
class OpportunityDetailScreen extends ConsumerStatefulWidget {
  const OpportunityDetailScreen({super.key, required this.oppId, this.heroTag});

  final String oppId;
  final Object? heroTag;

  @override
  ConsumerState<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends ConsumerState<OpportunityDetailScreen> {
  bool _saved = false;

  Future<void> _report(Opportunity o) async {
    final ok = await showAppDialog(
      context,
      title: 'Report this listing?',
      body: 'An admin will check it within a day. Tell us if a listing asks for money, seems fake or treats people unfairly.',
      confirmLabel: 'Report',
      destructive: true,
      icon: Icons.flag_outlined,
    );
    if (ok && mounted) showToast(context, 'Thanks — an admin will check “${o.title}”', icon: Icons.flag_outlined, tone: Tone.warning);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final o = data.opportunity(widget.oppId);
    if (o == null) {
      return const DetailPage(
        title: 'Opportunity',
        backFallback: '/jobs',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.work_off_outlined, title: 'This listing was removed', body: 'It may have closed or been taken down by an admin.')],
      );
    }
    final app = data.applicationFor(o.id);
    final closed = o.state != ListingState.open;
    final tile = OrgTile(opportunity: o, size: 60);

    return DetailPage(
      title: o.org,
      backFallback: '/jobs',
      actions: [
        CircleIconButton(
          icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          tooltip: _saved ? 'Saved' : 'Save',
          onTap: () {
            setState(() => _saved = !_saved);
            showToast(context, _saved ? 'Saved — we’ll remind you before it closes' : 'Removed from saved', icon: Icons.bookmark_rounded);
          },
        ),
        const SizedBox(width: 4),
      ],
      footer: [
        if (app != null)
          AppButton('View my application', icon: Icons.arrow_forward_rounded, onPressed: () => context.go('/jobs/applications/${app.id}'))
        else if (closed)
          const AppButton('Applications closed', onPressed: null)
        else
          AppButton('Apply with my portfolio', icon: Icons.arrow_forward_rounded, onPressed: () => context.push('/apply/${o.id}')),
      ],
      footerNote: app == null && !closed
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded, size: 15, color: AppColors.accentText),
                const SizedBox(width: 6),
                Text('Closes ${o.closes} · ${o.closesNote.toLowerCase()}', style: AppText.bodySStrong.copyWith(color: AppColors.accentText)),
              ],
            )
          : null,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.heroTag == null ? tile : Hero(tag: widget.heroTag!, child: tile),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.title, style: AppText.titleL),
                  const SizedBox(height: 4),
                  Text('${o.org} · ${o.place}', style: AppText.bodyM),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (o.matched) const StatusBadge('Matched to your evidence', tone: Tone.success, icon: Icons.auto_awesome_rounded),
            if (app != null) StatusBadge(app.status.label, tone: app.status.tone),
            StatusBadge(o.posted),
            StatusBadge('${o.applicants} applicants', icon: Icons.people_outline_rounded),
          ],
        ),
        const SizedBox(height: 18),
        KeyValueTable([
          ('Type', o.length.isEmpty ? _cap(o.kind) : '${_cap(o.kind)} · ${o.length.toLowerCase()}'),
          ('Pay', o.pay),
          ('Where', o.place),
          ('Closes', o.closes),
          ('Replies by', o.repliesBy),
          ('Starts', o.starts),
        ]),
        if (o.requirements.isNotEmpty) ...[
          SectionLabel('How your evidence matches · ${o.metCount} of ${o.requirements.length}'),
          ListGroup(children: [for (final r in o.requirements) _RequirementRow(r)]),
        ],
        const SectionLabel('About the role'),
        Text(o.about, style: AppText.bodyM),
        if (o.tasks.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final t in o.tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(margin: const EdgeInsets.only(top: 8, right: 10), width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                  Expanded(child: Text(t, style: AppText.bodyM)),
                ],
              ),
            ),
        ],
        SectionLabel('About ${o.org}'),
        Text(o.aboutOrg, style: AppText.bodyM),
        const SizedBox(height: 18),
        NoticeCard(
          tone: Tone.info,
          icon: Icons.mark_email_read_outlined,
          title: '${o.org} replies to everyone by ${o.repliesBy}',
          body: 'UpBridge only lists employers who commit to a reply-by date, so you’re never left waiting.',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: MonoLabel(o.postedBy, maxLines: 2)),
            TextLink('Report listing', color: AppColors.textMuted, onTap: () => _report(o)),
          ],
        ),
      ],
    );
  }

  static String _cap(String s) => s.isEmpty ? s : '${s[0]}${s.substring(1).toLowerCase()}';
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow(this.r);

  final Requirement r;

  @override
  Widget build(BuildContext context) {
    final (icon, tone, label) = switch (r.state) {
      ReqState.met => (Icons.check_circle_rounded, Tone.success, 'Met'),
      ReqState.partial => (Icons.change_circle_outlined, Tone.warning, 'Partly'),
      ReqState.unknown => (Icons.help_outline_rounded, Tone.neutral, 'Not shown yet'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tone == Tone.neutral ? AppColors.textMuted : tone.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.text, style: AppText.bodyMStrong),
                if (r.evidence.isNotEmpty) ...[const SizedBox(height: 2), Text(r.evidence, style: AppText.bodyS)],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(label, tone: tone),
        ],
      ),
    );
  }
}
