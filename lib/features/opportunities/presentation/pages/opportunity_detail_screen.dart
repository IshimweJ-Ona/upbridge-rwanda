import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/cloudinary_media_picker.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/features/opportunities/domain/opportunity_filters.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class OpportunityDetailScreen extends ConsumerStatefulWidget {
  const OpportunityDetailScreen({super.key, required this.oppId});

  final String oppId;

  @override
  ConsumerState<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState
    extends ConsumerState<OpportunityDetailScreen> {
  final _coverNote = TextEditingController();
  final Set<String> _selectedProjectIds = {};
  MediaAsset? _cvAsset;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _coverNote.dispose();
    super.dispose();
  }

  Future<void> _submit({
    required AppSession session,
    required OpportunityListing opp,
  }) async {
    FocusScope.of(context).unfocus();
    final note = _coverNote.text.trim();
    if (note.length < 20) {
      setState(
        () => _error = 'Write at least 20 characters explaining why you fit.',
      );
      return;
    }
    final uid = session.uid;
    if (uid == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final now = DateTime.now().toUtc();
      await ref
          .read(opportunityRepositoryProvider)
          .submitApplication(
            OpportunityApplication(
              id: OpportunityApplication.docId(uid, opp.id),
              ownerUid: uid,
              opportunityId: opp.id,
              opportunityTitle: opp.title,
              organization: opp.organization,
              studentName: session.displayLabel,
              projectIds: _selectedProjectIds.toList(growable: false),
              coverNote: note,
              cvAsset: _cvAsset,
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (mounted) showToast(context, 'Application submitted');
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _withdraw(String uid, String oppId) async {
    final ok = await showAppDialog(
      context,
      title: 'Withdraw application?',
      body: 'You can apply again before the deadline if needed.',
      confirmLabel: 'Withdraw',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(opportunityRepositoryProvider)
          .withdrawApplication(uid, oppId);
      if (mounted) {
        showToast(context, 'Application withdrawn', tone: Tone.warning);
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;
    final oppAsync = ref.watch(opportunityDetailProvider(widget.oppId));
    final appAsync = uid == null
        ? null
        : ref.watch(_oppAppProvider((uid: uid, oppId: widget.oppId)));
    final projects = uid == null
        ? const <PortfolioProject>[]
        : ref.watch(userProjectsProvider(uid)).asData?.value ??
              const <PortfolioProject>[];

    return oppAsync.when(
      loading: () => const DetailPage(
        title: 'Opportunity',
        backFallback: '/jobs',
        children: [SkeletonDetailPageLoader()],
      ),
      error: (error, _) => DetailPage(
        title: 'Opportunity',
        backFallback: '/jobs',
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load listing',
            body: errorMessage(error),
          ),
        ],
      ),
      data: (opp) {
        if (opp == null) {
          return const DetailPage(
            title: 'Opportunity not found',
            backFallback: '/jobs',
            children: [
              EmptyState(
                icon: Icons.work_off_outlined,
                title: 'Opportunity unavailable',
                body: 'This listing may have closed or been removed.',
              ),
            ],
          );
        }

        final existingApp = appAsync?.asData?.value;
        final isActiveApp =
            existingApp != null &&
            existingApp.status != OpportunityApplicationStatus.withdrawn;

        final soon = closingSoonLabel(opp);

        return DetailPage(
          title: opp.title,
          backFallback: '/jobs',
          children: [
            const SizedBox(height: 8),
            if (opp.coverAsset != null && opp.coverAsset!.url.isNotEmpty) ...[
              ClipRRect(
                borderRadius: Radii.rLg,
                child: CachedNetworkImage(
                  imageUrl: opp.coverAsset!.url,
                  height: 168,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(height: 168, color: context.palette.sunken),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusBadge(opp.displayType, tone: Tone.info),
                      if (soon != null)
                        StatusBadge(
                          soon,
                          tone: Tone.warning,
                          icon: Icons.schedule_rounded,
                        ),
                      if (opp.location.isNotEmpty) StatusBadge(opp.location),
                      if (opp.workMode.isNotEmpty) StatusBadge(opp.workMode),
                      if (opp.compensation.isNotEmpty)
                        StatusBadge(opp.compensation, tone: Tone.accent),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    opp.organization,
                    style: AppText.titleM.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  MonoLabel(
                    'Closes ${DateFormat('EEE d MMM yyyy').format(opp.deadline.toLocal())}',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    opp.description,
                    style: AppText.bodyM.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  if (opp.skills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TagWrap(opp.skills),
                  ],
                ],
              ),
            ),
            if (opp.requirements.isNotEmpty) ...[
              const SectionLabel('Requirements'),
              ListGroup(
                children: [
                  for (final r in opp.requirements)
                    ListRow(
                      leading: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      title: r,
                      chevron: false,
                    ),
                ],
              ),
            ],
            if (opp.applyUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppButton(
                'Open external link',
                variant: ButtonVariant.secondary,
                leadingIcon: Icons.open_in_new_rounded,
                onPressed: () => openLink(context, opp.applyUrl),
              ),
            ],
            if (session != null && uid != null) ...[
              const SectionLabel('Your application'),
              if (isActiveApp) ...[
                NoticeCard(
                  tone: Tone.success,
                  icon: Icons.check_circle_outline_rounded,
                  title:
                      'Application status: ${applicationStatusLabel(existingApp.status)}',
                  body: existingApp.coverNote,
                ),
                const SizedBox(height: 12),
                if (existingApp.status ==
                        OpportunityApplicationStatus.submitted ||
                    existingApp.status ==
                        OpportunityApplicationStatus.underReview)
                  AppButton(
                    'Withdraw application',
                    variant: ButtonVariant.dangerOutline,
                    loading: _submitting,
                    onPressed: () => _withdraw(uid, opp.id),
                  ),
              ] else ...[
                if (_error != null) ...[
                  NoticeCard(
                    tone: Tone.danger,
                    icon: Icons.error_outline_rounded,
                    title: 'Check your application',
                    body: _error!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (projects.isNotEmpty) ...[
                  Text(
                    'Attach portfolio projects',
                    style: AppText.bodySStrong.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in projects)
                        SelectChip(
                          label: p.title,
                          selected: _selectedProjectIds.contains(p.id),
                          onTap: () => setState(() {
                            if (_selectedProjectIds.contains(p.id)) {
                              _selectedProjectIds.remove(p.id);
                            } else {
                              _selectedProjectIds.add(p.id);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                AppTextField(
                  label: 'Cover note',
                  hint: 'Share why you are interested and which projects demonstrate your skills (min 20 chars).',
                  controller: _coverNote,
                  minLines: 4,
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                CloudinaryMediaPicker(
                  ownerUid: uid,
                  label: 'Attach CV or portfolio image snapshot (optional)',
                  category: 'applications',
                  imagesOnly: false,
                  helperText: 'JPG, JPEG, PNG, or WebP image (max 10 MB).',
                  initialAsset: _cvAsset,
                  onAssetChanged: (asset) => _cvAsset = asset,
                ),
                const SizedBox(height: 16),
                AppButton(
                  'Submit application',
                  loading: _submitting,
                  onPressed: () => _submit(session: session, opp: opp),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

final _oppAppProvider = StreamProvider.autoDispose
    .family<OpportunityApplication?, ({String uid, String oppId})>(
      (ref, q) => ref
          .watch(opportunityRepositoryProvider)
          .watchApplicationFor(q.uid, q.oppId),
    );
