// Owner: Student 4 · Opportunities & applications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/applications/presentation/providers/application_providers.dart';
import 'package:upbridge/features/applications/presentation/state/failure_message.dart';
import 'package:upbridge/features/opportunities/domain/usecases/filter_opportunities.dart';
import 'package:upbridge/features/opportunities/presentation/providers/opportunity_providers.dart';
import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/models/models.dart';

/// J1 · Opportunities, J1a · loading (shimmer) and J1b · offline.
class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  String _filter = 'All';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(opportunitiesProvider);
    final mine = ref.watch(myApplicationsProvider).value ?? const <Application>[];
    final loading = listings.isLoading && !listings.hasValue;
    final failed = listings.hasError && !listings.hasValue;

    final Widget body;
    if (loading) {
      body = const _LoadingList(key: ValueKey('loading'));
    } else if (failed) {
      final error = listings.error!;
      body = _LoadFailed(
        key: const ValueKey('failed'),
        offline: error is NetworkFailure,
        message: failureMessage(error),
        onRetry: () => ref.invalidate(opportunitiesProvider),
      );
    } else {
      body = KeyedSubtree(key: const ValueKey('list'), child: _list(context, listings.value ?? const <Opportunity>[], mine));
    }

    return PageFrame(
      largeTitle: 'Opportunities',
      eyebrow: 'Jobs, internships and paid gigs',
      actions: [
        CircleIconButton(icon: Icons.inventory_2_outlined, tooltip: 'My applications', onTap: () => context.go('/jobs/applications')),
        const SizedBox(width: 4),
      ],
      onRefresh: listings.hasValue
          ? () async {
              ref.invalidate(opportunitiesProvider);
              await ref.read(opportunitiesProvider.future);
            }
          : null,
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

  Widget _list(BuildContext context, List<Opportunity> all, List<Application> mine) {
    final open = filterOpportunities(all, category: _filter, search: _search);
    final matched = open.where((o) => o.matched).toList();
    final rest = open.where((o) => !o.matched).toList();
    final apps = mine.where((a) => a.status.isActive).toList();

    // A withdrawn application does not count as applied
    AppStatus? appliedStatus(String oppId) {
      for (final a in mine) {
        if (a.oppId == oppId && a.status != AppStatus.withdrawn) return a.status;
      }
      return null;
    }

    Widget card(Opportunity o, int i) {
      final tag = 'opp-${o.id}-jobs';
      return Reveal(
        index: i,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OpportunityCard(
            opportunity: o,
            heroTag: tag,
            applied: appliedStatus(o.id),
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
        AppTextField(
          label: 'Search',
          hint: 'Title, employer or category',
          suffixIcon: Icons.search_rounded,
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 12),
        ChipBar(options: opportunityCategories, selected: _filter, padding: EdgeInsets.zero, onSelected: (v) => setState(() => _filter = v)),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: Motion.base,
          child: Column(
            key: ValueKey(_filter),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (open.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: EmptyState(
                    icon: Icons.work_off_outlined,
                    title: 'Nothing here right now',
                    body: _search.trim().isEmpty ? 'New listings are checked by an admin before they appear. Pull down to refresh.' : 'No listing matches your search. Try another word or filter.',
                  ),
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

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({super.key, required this.offline, required this.message, required this.onRetry});

  final bool offline;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        EmptyState(
          icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
          title: offline ? 'You’re offline' : 'Couldn’t load opportunities',
          body: message,
          action: 'Try again',
          onAction: onRetry,
        ),
        const SizedBox(height: 16),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.inventory_2_outlined, tone: Tone.info),
              title: 'My applications',
              subtitle: 'Track what you have sent',
              onTap: () => context.go('/jobs/applications'),
            ),
          ],
        ),
      ],
    );
  }
}
