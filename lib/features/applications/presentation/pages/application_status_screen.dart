// Owner: Student 4 · Opportunities & applications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// J8 · Application status timeline (e.g. BK TecHouse, under review).
class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({super.key, required this.appId});

  final String appId;

  Future<void> _withdraw(BuildContext context, WidgetRef ref, Opportunity? o) async {
    final ok = await showAppDialog(
      context,
      title: 'Withdraw this application?',
      body: '${o?.org ?? 'The employer'} won’t see it any more. You can’t undo this, but you can apply again while the listing is open.',
      confirmLabel: 'Withdraw',
      cancelLabel: 'Keep it',
      destructive: true,
      icon: Icons.undo_rounded,
    );
    if (!ok) return;
    ref.read(appStoreProvider.notifier).withdraw(appId);
    if (context.mounted) showToast(context, 'Application withdrawn', icon: Icons.undo_rounded, tone: Tone.warning);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final app = data.application(appId);
    if (app == null) {
      return const DetailPage(
        title: 'Application',
        backFallback: '/jobs/applications',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.search_off_rounded, title: 'Application not found')],
      );
    }
    final o = data.opportunity(app.oppId);
    final projects = [for (final id in app.projectIds) data.project(id)].whereType<Project>().toList();
    final tone = app.status.tone;

    return PageFrame(
      title: o?.org ?? 'Application',
      showBack: true,
      backFallback: '/jobs/applications',
      footer: [
        if (o != null) AppButton('View listing', variant: ButtonVariant.secondary, onPressed: () => context.push('/opportunity/${o.id}')),
        if (app.status.isActive)
          AppButton('Withdraw application', variant: ButtonVariant.dangerOutline, onPressed: () => _withdraw(context, ref, o))
        else
          AppButton('Find similar opportunities', onPressed: () => context.go('/jobs')),
      ],
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (o != null) ...[OrgTile(opportunity: o, size: 52), const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o?.title ?? 'Application', style: AppText.titleL),
                  const SizedBox(height: 4),
                  Text(o == null ? '' : '${o.org} · ${o.place}', style: AppText.bodyS),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.base,
          child: NoticeCard(
            key: ValueKey(app.status),
            tone: tone,
            icon: switch (app.status) {
              AppStatus.shortlisted => Icons.star_rounded,
              AppStatus.notSelected => Icons.info_outline_rounded,
              AppStatus.withdrawn => Icons.undo_rounded,
              _ => Icons.hourglass_top_rounded,
            },
            title: app.status.label,
            body: app.statusNote,
          ),
        ),
        const SectionLabel('Progress'),
        SurfaceCard(child: TimelineList(events: app.timeline)),
        const SectionLabel('What you sent'),
        KeyValueTable([
          ('Reference', app.ref),
          ('Sent', app.sentOn.replaceFirst('Sent ', '')),
          ('Evidence', '${app.projectIds.length} project${app.projectIds.length == 1 ? '' : 's'}'),
        ]),
        if (projects.isNotEmpty) ...[
          const SizedBox(height: 12),
          ListGroup(
            children: [
              for (final p in projects)
                ListRow(
                  leading: IconTile(p.icon, tone: p.tone),
                  title: p.title,
                  meta: p.verified ? 'Mentor-approved' : 'Self-added',
                  onTap: () => context.push('/project/${p.id}'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MonoLabel('Your note'),
              const SizedBox(height: 6),
              Text(app.note, style: AppText.bodyM),
            ],
          ),
        ),
      ],
    );
  }
}
