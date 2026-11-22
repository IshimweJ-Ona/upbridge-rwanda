import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  String _typeFilter = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(appSessionProvider).asData?.value.uid;
    final oppsAsync = ref.watch(publishedOpportunitiesProvider);
    final loadedListings =
        oppsAsync.asData?.value ?? const <OpportunityListing>[];
    final typeOptions = <String>[
      'All',
      ...{for (final o in loadedListings) o.displayType},
    ];
    final activeType = typeOptions.contains(_typeFilter) ? _typeFilter : 'All';
    final apps = uid == null
        ? const <OpportunityApplication>[]
        : ref.watch(userApplicationsProvider(uid)).asData?.value ??
              const <OpportunityApplication>[];
    final appByOpp = {for (final a in apps) a.opportunityId: a};

    return PageFrame(
      largeTitle: l10n.tabJobs,
      subtitle: 'Jobs, internships, grants & fellowships',
      onRefresh: () async {
        ref.invalidate(publishedOpportunitiesProvider);
        if (uid != null) ref.invalidate(userApplicationsProvider(uid));
      },
      children: [
        const SizedBox(height: 12),
        if (apps.isNotEmpty) ...[
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: ListRow(
              leading: const IconTile(Icons.send_outlined, tone: Tone.info),
              title: 'Your applications',
              subtitle:
                  '${apps.where((a) => a.status != OpportunityApplicationStatus.withdrawn).length} active submissions',
              chevron: false,
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppSearchField(
          controller: _searchCtrl,
          hint: 'Search opportunities by title, organization, or skill',
          onChanged: (v) => setState(() => _query = v),
        ),
        if (typeOptions.length > 1) ...[
          const SizedBox(height: 12),
          ChipBar(
            options: typeOptions,
            selected: activeType,
            padding: EdgeInsets.zero,
            onSelected: (v) => setState(() => _typeFilter = v),
          ),
        ],
        const SizedBox(height: 16),
        oppsAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load opportunities',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(publishedOpportunitiesProvider),
          ),
          data: (listings) {
            final q = _query.trim().toLowerCase();
            final filtered = listings
                .where((o) {
                  final typeOk =
                      activeType == 'All' || o.displayType == activeType;
                  final qOk =
                      q.isEmpty ||
                      o.title.toLowerCase().contains(q) ||
                      o.organization.toLowerCase().contains(q) ||
                      o.location.toLowerCase().contains(q) ||
                      o.displayType.toLowerCase().contains(q) ||
                      o.workMode.toLowerCase().contains(q) ||
                      o.skills.any((s) => s.toLowerCase().contains(q));
                  return typeOk && qOk;
                })
                .toList(growable: false);

            if (listings.isEmpty) {
              return EmptyState(
                icon: Icons.work_outline_rounded,
                title: l10n.noOpportunitiesYet,
                body: l10n.noOpportunitiesBody,
              );
            }
            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching opportunities',
                body: 'Try another filter or clear your search.',
                action: 'Reset filters',
                onAction: () => setState(() {
                  _typeFilter = 'All';
                  _query = '';
                  _searchCtrl.clear();
                }),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final o in filtered) ...[
                  _OpportunityListingCard(
                    listing: o,
                    application: appByOpp[o.id],
                    onTap: () => context.push('/opportunity/${o.id}'),
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

class _OpportunityListingCard extends StatelessWidget {
  const _OpportunityListingCard({
    required this.listing,
    required this.application,
    required this.onTap,
  });

  final OpportunityListing listing;
  final OpportunityApplication? application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (listing.coverAsset != null &&
                  listing.coverAsset!.url.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: Radii.rMd,
                  child: CachedNetworkImage(
                    imageUrl: listing.coverAsset!.url,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(width: 48, height: 48, color: p.sunken),
                    errorWidget: (_, _, _) => Container(
                      width: 48,
                      height: 48,
                      color: p.sunken,
                      child: Icon(
                        Icons.work_outline_rounded,
                        size: 20,
                        color: p.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  listing.title,
                  style: AppText.titleS.copyWith(color: p.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              if (application != null)
                StatusBadge(
                  application!.status.name,
                  tone:
                      application!.status ==
                          OpportunityApplicationStatus.withdrawn
                      ? Tone.neutral
                      : Tone.success,
                )
              else
                StatusBadge(listing.displayType, tone: Tone.info),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${listing.organization} · ${listing.location}${listing.workMode.isNotEmpty ? ' · ${listing.workMode}' : ''}',
            style: AppText.bodyS.copyWith(color: p.textSecondary),
          ),
          if (listing.compensation.isNotEmpty || listing.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (listing.compensation.isNotEmpty)
                  StatusBadge(listing.compensation, tone: Tone.accent),
                for (final s in listing.skills.take(4)) StatusBadge(s),
              ],
            ),
          ],
          const SizedBox(height: 10),
          MonoLabel(
            'Deadline ${DateFormat('d MMM yyyy').format(listing.deadline.toLocal())}',
          ),
        ],
      ),
    );
  }
}
