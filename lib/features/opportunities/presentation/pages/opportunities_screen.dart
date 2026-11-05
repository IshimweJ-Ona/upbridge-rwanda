// Owner: Student 4 · Opportunities & applications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// J1 · Opportunities, J1a · loading (shimmer) and J1b · offline.
class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  static const _filters = ['All', 'Internships', 'Jobs', 'Gigs', 'Trainee'];
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    final data = ref.watch(appStoreProvider);
    final loading = feed.isLoading && !feed.hasValue;
    final offline = feed.hasError && !feed.isLoading && !feed.hasValue;

    final Widget body;
    if (loading) {
      body = const _LoadingList(key: ValueKey('loading'));
    } else if (offline) {
      body = _Offline(key: const ValueKey('offline'), onRetry: () => ref.invalidate(feedProvider), applications: data.myApplications.length);
    } else {
      body = KeyedSubtree(key: const ValueKey('list'), child: _list(context, data));
    }

    return PageFrame(
      largeTitle: 'Opportunities',
      eyebrow: 'Jobs, internships and paid gigs',
      actions: [
        CircleIconButton(icon: Icons.inventory_2_outlined, tooltip: 'My applications', onTap: () => context.go('/jobs/applications')),
        const SizedBox(width: 4),
      ],
      onRefresh: feed.hasValue ? () => ref.refresh(feedProvider.future) : null,
      children: [
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.curve,
          switchOutCurve: Motion.exit,
          layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
          child: body,
        ),
      ],
    );
  }

  Widget _list(BuildContext context, AppData data) {
    final open = data.openOpportunities.where((o) => _filter == 'All' || o.category == _filter).toList();
    final matched = open.where((o) => o.matched).toList();
    final rest = open.where((o) => !o.matched).toList();
    final apps = data.myApplications.where((a) => a.status.isActive).toList();

    Widget card(Opportunity o, int i) {
      final tag = 'opp-${o.id}-jobs';
      return Reveal(
        index: i,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OpportunityCard(
            opportunity: o,
            heroTag: tag,
            applied: data.applicationFor(o.id)?.status,
            onTap: () => context.push('/opportunity/${o.id}', extra: tag),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          onTap: () => context.go('/jobs/applications'),
          child: Row(
            children: [
              const IconTile(Icons.send_outlined, tone: Tone.info),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My applications', style: AppText.bodyMStrong),
                    Text(apps.isEmpty ? 'Nothing in progress' : '${apps.length} in progress · ${apps.first.status.label.toLowerCase()}', style: AppText.bodyS),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ChipBar(options: _filters, selected: _filter, padding: EdgeInsets.zero, onSelected: (v) => setState(() => _filter = v)),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: Motion.base,
          child: Column(
            key: ValueKey(_filter),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (open.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: EmptyState(icon: Icons.work_off_outlined, title: 'Nothing here right now', body: 'New listings are checked by an admin before they appear. Pull down to refresh.'),
                ),
              if (matched.isNotEmpty) ...[
                const SectionLabel('Matched to your evidence', top: 18),
                for (var i = 0; i < matched.length; i++) card(matched[i], i),
              ],
              if (rest.isNotEmpty) ...[
                SectionLabel(matched.isEmpty ? 'Open now' : 'More opportunities', top: 14),
                for (var i = 0; i < rest.length; i++) card(rest[i], matched.length + i),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        const NoticeCard(
          tone: Tone.info,
          icon: Icons.verified_user_outlined,
          title: 'Every listing is checked',
          body: 'Employers commit to a reply-by date, and no listing may ask you to pay a fee.',
        ),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text('Loading opportunities…', style: AppText.bodyS),
          ],
        ),
        const SizedBox(height: 16),
        Column(
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.rLg, border: Border.all(color: AppColors.borderSubtle)),
                  child: const Shimmer(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonBox(width: 44, height: 44, radius: 12),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 180, height: 14),
                                SizedBox(height: 8),
                                SkeletonBox(width: 120, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SkeletonBox(width: 220, height: 10),
                      SizedBox(height: 14),
                      SkeletonBox(height: 12),
                    ],
                  )),
                ),
            ],
          ),
        Text('On a slow connection this can take a few seconds.', style: AppText.caption, textAlign: TextAlign.center),
      ],
    );
  }
}

class _Offline extends StatelessWidget {
  const _Offline({super.key, required this.onRetry, required this.applications});

  final VoidCallback onRetry;
  final int applications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'You’re offline',
          body: 'Opportunities need a connection to load. Check your mobile data or Wi-Fi.',
          action: 'Try again',
          onAction: onRetry,
        ),
        const SizedBox(height: 16),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.inventory_2_outlined, tone: Tone.info),
              title: 'My applications',
              subtitle: '$applications saved on this phone · available offline',
              onTap: () => context.go('/jobs/applications'),
            ),
          ],
        ),
      ],
    );
  }
}
