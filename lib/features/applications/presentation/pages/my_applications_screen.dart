// Owner: Student 4 · Opportunities & applications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// J7 · My applications (Active / Closed).
class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final all = data.myApplications;
    final active = all.where((a) => a.status.isActive).toList();
    final closed = all.where((a) => !a.status.isActive).toList();
    final list = _tab == 0 ? active : closed;

    return PageFrame(
      largeTitle: 'My applications',
      showBack: true,
      backFallback: '/jobs',
      children: [
        const SizedBox(height: 4),
        Text('Every employer has committed to a reply-by date.', style: AppText.bodyS),
        const SizedBox(height: 12),
        SegmentedTabs(tabs: const ['Active', 'Closed'], counts: [active.length, closed.length], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: 16),
        TabBodySwitcher(
          index: _tab,
          child: list.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: _tab == 0 ? 'Nothing in progress' : 'No closed applications',
                  body: _tab == 0 ? 'Apply with your portfolio and track every step here.' : 'Withdrawn and finished applications appear here.',
                  action: _tab == 0 ? 'Browse opportunities' : null,
                  onAction: () => context.go('/jobs'),
                )
              : Column(
                  children: [
                    for (var i = 0; i < list.length; i++)
                      Reveal(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ApplicationCard(app: list[i], opp: data.opportunity(list[i].oppId)),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.app, required this.opp});

  final Application app;
  final Opportunity? opp;

  @override
  Widget build(BuildContext context) {
    final o = opp;
    final done = app.timeline.where((e) => e.done).length;
    return SurfaceCard(
      onTap: () => context.go('/jobs/applications/${app.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (o != null) ...[OrgTile(opportunity: o, size: 40), const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o?.title ?? 'Application', style: AppText.titleS),
                    Text(o?.org ?? '', style: AppText.bodyS),
                  ],
                ),
              ),
              StatusBadge(app.status.label, tone: app.status.tone),
            ],
          ),
          const SizedBox(height: 12),
          if (app.status.isActive) ...[
            ProgressLine(app.timeline.isEmpty ? 0 : done / app.timeline.length, color: app.status == AppStatus.shortlisted ? AppColors.successText : AppColors.infoText, height: 4),
            const SizedBox(height: 10),
          ],
          MonoLabel('${app.ref} · ${app.sentOn}'),
          if (app.status == AppStatus.shortlisted) ...[
            const SizedBox(height: 8),
            Text(app.statusNote, style: AppText.bodySStrong.copyWith(color: AppColors.successText)),
          ],
        ],
      ),
    );
  }
}
