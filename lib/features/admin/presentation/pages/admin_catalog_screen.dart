import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/admin/presentation/widgets/catalog_editor_sheets.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class AdminCatalogScreen extends ConsumerStatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  ConsumerState<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends ConsumerState<AdminCatalogScreen> {
  String _section = 'Courses';
  String _statusFilter = 'All';
  String _categoryFilter = 'All';
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCourseEditor(String adminUid, {Course? existing}) async {
    final saved = await showCourseEditorSheet(
      context,
      adminUid: adminUid,
      existing: existing,
    );
    if (saved == true && mounted) {
      showToast(context, 'Course saved');
    }
  }

  Future<void> _openOpportunityEditor(
    String adminUid, {
    OpportunityListing? existing,
  }) async {
    final saved = await showOpportunityEditorSheet(
      context,
      adminUid: adminUid,
      existing: existing,
    );
    if (saved == true && mounted) {
      showToast(context, 'Opportunity saved');
    }
  }

  Future<void> _transitionCourse(
    String courseId,
    CourseStatus nextStatus,
  ) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(courseRepositoryProvider)
          .transitionCourseStatus(courseId: courseId, nextStatus: nextStatus);
      ref.invalidate(platformMetricsProvider);
      if (mounted) {
        showToast(context, 'Course ${nextStatus.label.toLowerCase()}');
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _transitionOpportunity(
    String oppId,
    OpportunityStatus nextStatus,
  ) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(opportunityRepositoryProvider)
          .transitionOpportunityStatus(
            opportunityId: oppId,
            nextStatus: nextStatus,
          );
      ref.invalidate(platformMetricsProvider);
      if (mounted) {
        showToast(context, 'Opportunity ${nextStatus.label.toLowerCase()}');
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switchSection(String nextSection) {
    if (_section == nextSection) return;
    setState(() {
      _section = nextSection;
      _statusFilter = 'All';
      _categoryFilter = 'All';
      _query = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adminUid = ref.watch(appSessionProvider).asData?.value.uid;
    final coursesAsync = ref.watch(allCoursesProvider);
    final oppsAsync = ref.watch(allOpportunitiesProvider);
    final courseCount = coursesAsync.asData?.value.length;
    final oppCount = oppsAsync.asData?.value.length;

    return PageFrame(
      largeTitle: l10n.tabAdminContent,
      subtitle: 'Courses, custom tracks, grants & career roles',
      actions: [
        if (adminUid != null)
          CircleIconButton(
            icon: Icons.add_rounded,
            tooltip: _section == 'Courses' ? 'New course' : 'New opportunity',
            onTap: () => _section == 'Courses'
                ? _openCourseEditor(adminUid)
                : _openOpportunityEditor(adminUid),
          ),
        const SizedBox(width: 4),
      ],
      onRefresh: () async {
        ref.invalidate(allCoursesProvider);
        ref.invalidate(allOpportunitiesProvider);
        ref.invalidate(platformMetricsProvider);
      },
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SelectChip(
                label: courseCount == null
                    ? 'Courses'
                    : 'Courses ($courseCount)',
                selected: _section == 'Courses',
                onTap: () => _switchSection('Courses'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SelectChip(
                label: oppCount == null
                    ? 'Opportunities'
                    : 'Opportunities ($oppCount)',
                selected: _section == 'Opportunities',
                onTap: () => _switchSection('Opportunities'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppSearchField(
          controller: _searchCtrl,
          hint: _section == 'Courses'
              ? 'Search courses by title, category, or skill'
              : 'Search opportunities by role, organization, or skill',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        ChipBar(
          options: _section == 'Courses'
              ? const ['All', 'Published', 'Draft', 'Archived']
              : const ['All', 'Published', 'Draft', 'Closed', 'Archived'],
          selected: _statusFilter,
          padding: EdgeInsets.zero,
          onSelected: (v) => setState(() => _statusFilter = v),
        ),
        const SizedBox(height: 14),
        if (_section == 'Courses')
          _CoursesCatalogSection(
            coursesAsync: coursesAsync,
            adminUid: adminUid,
            query: _query,
            statusFilter: _statusFilter,
            categoryFilter: _categoryFilter,
            busy: _busy,
            onCategorySelected: (v) => setState(() => _categoryFilter = v),
            onRetry: () => ref.invalidate(allCoursesProvider),
            onEdit: (course) => _openCourseEditor(adminUid!, existing: course),
            onCreate: adminUid == null
                ? null
                : () => _openCourseEditor(adminUid),
            onTransition: _transitionCourse,
          )
        else
          _OpportunitiesCatalogSection(
            oppsAsync: oppsAsync,
            adminUid: adminUid,
            query: _query,
            statusFilter: _statusFilter,
            typeFilter: _categoryFilter,
            busy: _busy,
            onTypeSelected: (v) => setState(() => _categoryFilter = v),
            onRetry: () => ref.invalidate(allOpportunitiesProvider),
            onEdit: (opp) => _openOpportunityEditor(adminUid!, existing: opp),
            onCreate: adminUid == null
                ? null
                : () => _openOpportunityEditor(adminUid),
            onTransition: _transitionOpportunity,
          ),
      ],
    );
  }
}

class _CoursesCatalogSection extends StatelessWidget {
  const _CoursesCatalogSection({
    required this.coursesAsync,
    required this.adminUid,
    required this.query,
    required this.statusFilter,
    required this.categoryFilter,
    required this.busy,
    required this.onCategorySelected,
    required this.onRetry,
    required this.onEdit,
    required this.onCreate,
    required this.onTransition,
  });

  final AsyncValue<List<Course>> coursesAsync;
  final String? adminUid;
  final String query;
  final String statusFilter;
  final String categoryFilter;
  final bool busy;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onRetry;
  final ValueChanged<Course> onEdit;
  final VoidCallback? onCreate;
  final Future<void> Function(String courseId, CourseStatus nextStatus)
  onTransition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;

    return coursesAsync.when(
      loading: () => const SkeletonDashboardLoader(cards: 3),
      error: (error, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load courses',
        body: errorMessage(error),
        action: l10n.retry,
        onAction: onRetry,
      ),
      data: (courses) {
        if (courses.isEmpty) {
          return EmptyState(
            icon: Icons.school_outlined,
            title: 'No courses created yet',
            body: 'Create any custom track, bootcamp, or technical course for students.',
            action: onCreate == null ? null : 'Create course',
            onAction: onCreate,
          );
        }

        final dynamicCategories = <String>{
          'All',
          for (final c in courses) c.displayCategory,
        }.toList(growable: false);
        final activeCategory = dynamicCategories.contains(categoryFilter)
            ? categoryFilter
            : 'All';

        final q = query.trim().toLowerCase();
        final filtered = courses
            .where((c) {
              final statusOk =
                  statusFilter == 'All' || c.status.label == statusFilter;
              final catOk =
                  activeCategory == 'All' ||
                  c.displayCategory == activeCategory;
              final qOk =
                  q.isEmpty ||
                  c.title.toLowerCase().contains(q) ||
                  c.summary.toLowerCase().contains(q) ||
                  c.displayCategory.toLowerCase().contains(q) ||
                  c.level.toLowerCase().contains(q) ||
                  c.skills.any((s) => s.toLowerCase().contains(q));
              return statusOk && catOk && qOk;
            })
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dynamicCategories.length > 2) ...[
              ChipBar(
                options: dynamicCategories,
                selected: activeCategory,
                padding: EdgeInsets.zero,
                onSelected: onCategorySelected,
              ),
              const SizedBox(height: 12),
            ],
            if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'No matching courses',
                body: 'Try another search query, category, or status filter.',
              )
            else
              for (final c in filtered) ...[
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.coverAsset != null &&
                              c.coverAsset!.url.isNotEmpty) ...[
                            _CatalogThumbnail(url: c.coverAsset!.url),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.title, style: AppText.titleS),
                                const SizedBox(height: 4),
                                Text(
                                  '${c.displayCategory} · ${c.level} · ${c.modules.length} modules · ${c.estimatedMinutes} min${c.ownerName.isNotEmpty ? ' · By ${c.ownerName}' : ''}',
                                  style: AppText.caption.copyWith(
                                    color: p.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            c.status.label,
                            tone: switch (c.status) {
                              CourseStatus.published => Tone.success,
                              CourseStatus.draft => Tone.warning,
                              CourseStatus.archived => Tone.neutral,
                            },
                          ),
                        ],
                      ),
                      if (c.skills.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        TagWrap(c.skills.take(4).toList(growable: false)),
                      ],
                      Divider(height: 20, color: p.borderSubtle),
                      Row(
                        children: [
                          AppButton(
                            l10n.previewLabel,
                            size: ButtonSize.small,
                            variant: ButtonVariant.ghost,
                            expand: false,
                            onPressed: () => context.push('/a/course/${c.id}'),
                          ),
                          if (adminUid != null) ...[
                            const SizedBox(width: 8),
                            AppButton(
                              'Edit',
                              size: ButtonSize.small,
                              variant: ButtonVariant.secondary,
                              expand: false,
                              onPressed: () => onEdit(c),
                            ),
                          ],
                          if ((StatusTransitions.course[c.status] ??
                                  const <CourseStatus>{})
                              .contains(CourseStatus.published)) ...[
                            const SizedBox(width: 8),
                            AppButton(
                              'Publish',
                              size: ButtonSize.small,
                              expand: false,
                              onPressed: busy
                                  ? null
                                  : () => onTransition(
                                        c.id,
                                        CourseStatus.published,
                                      ),
                            ),
                          ],
                          const Spacer(),
                          Builder(
                            builder: (_) {
                              final secondary =
                                  (StatusTransitions.course[c.status] ??
                                          const <CourseStatus>{})
                                      .where((s) => s != CourseStatus.published)
                                      .toList(growable: false);
                              if (secondary.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return PopupMenuButton<CourseStatus>(
                                enabled: !busy,
                                tooltip: 'More course actions',
                                icon: Icon(
                                  Icons.more_horiz_rounded,
                                  size: 20,
                                  color: p.textSecondary,
                                ),
                                onSelected: (next) => onTransition(c.id, next),
                                itemBuilder: (_) => [
                                  for (final next in secondary)
                                    PopupMenuItem<CourseStatus>(
                                      value: next,
                                      child: Text(switch (next) {
                                        CourseStatus.published => 'Publish',
                                        CourseStatus.draft => 'Move to draft',
                                        CourseStatus.archived => 'Archive',
                                      }),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _OpportunitiesCatalogSection extends StatelessWidget {
  const _OpportunitiesCatalogSection({
    required this.oppsAsync,
    required this.adminUid,
    required this.query,
    required this.statusFilter,
    required this.typeFilter,
    required this.busy,
    required this.onTypeSelected,
    required this.onRetry,
    required this.onEdit,
    required this.onCreate,
    required this.onTransition,
  });

  final AsyncValue<List<OpportunityListing>> oppsAsync;
  final String? adminUid;
  final String query;
  final String statusFilter;
  final String typeFilter;
  final bool busy;
  final ValueChanged<String> onTypeSelected;
  final VoidCallback onRetry;
  final ValueChanged<OpportunityListing> onEdit;
  final VoidCallback? onCreate;
  final Future<void> Function(String oppId, OpportunityStatus nextStatus)
  onTransition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;

    return oppsAsync.when(
      loading: () => const SkeletonDashboardLoader(cards: 3),
      error: (error, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load opportunities',
        body: errorMessage(error),
        action: l10n.retry,
        onAction: onRetry,
      ),
      data: (opps) {
        if (opps.isEmpty) {
          return EmptyState(
            icon: Icons.work_outline_rounded,
            title: 'No opportunities yet',
            body: 'Post jobs, internships, scholarships, fellowships, or custom programs.',
            action: onCreate == null ? null : 'Post opportunity',
            onAction: onCreate,
          );
        }

        final dynamicTypes = <String>{
          'All',
          for (final o in opps) o.displayType,
        }.toList(growable: false);
        final activeType = dynamicTypes.contains(typeFilter)
            ? typeFilter
            : 'All';

        final q = query.trim().toLowerCase();
        final filtered = opps
            .where((o) {
              final statusOk =
                  statusFilter == 'All' || o.status.label == statusFilter;
              final typeOk = activeType == 'All' || o.displayType == activeType;
              final qOk =
                  q.isEmpty ||
                  o.title.toLowerCase().contains(q) ||
                  o.organization.toLowerCase().contains(q) ||
                  o.location.toLowerCase().contains(q) ||
                  o.displayType.toLowerCase().contains(q) ||
                  o.workMode.toLowerCase().contains(q) ||
                  o.skills.any((s) => s.toLowerCase().contains(q));
              return statusOk && typeOk && qOk;
            })
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dynamicTypes.length > 2) ...[
              ChipBar(
                options: dynamicTypes,
                selected: activeType,
                padding: EdgeInsets.zero,
                onSelected: onTypeSelected,
              ),
              const SizedBox(height: 12),
            ],
            if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'No matching opportunities',
                body: 'Try another search query, type, or status filter.',
              )
            else
              for (final o in filtered) ...[
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (o.coverAsset != null &&
                              o.coverAsset!.url.isNotEmpty) ...[
                            _CatalogThumbnail(url: o.coverAsset!.url),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.title, style: AppText.titleS),
                                const SizedBox(height: 4),
                                Text(
                                  '${o.organization} · ${o.displayType} · Due ${DateFormat('d MMM y').format(o.deadline.toLocal())}',
                                  style: AppText.caption.copyWith(
                                    color: p.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            o.status.label,
                            tone: switch (o.status) {
                              OpportunityStatus.published => Tone.success,
                              OpportunityStatus.draft => Tone.warning,
                              OpportunityStatus.closed => Tone.danger,
                              OpportunityStatus.archived => Tone.neutral,
                            },
                          ),
                        ],
                      ),
                      if (o.workMode.isNotEmpty ||
                          o.compensation.isNotEmpty ||
                          o.skills.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (o.workMode.isNotEmpty)
                              StatusBadge(o.workMode, tone: Tone.info),
                            if (o.compensation.isNotEmpty)
                              StatusBadge(o.compensation, tone: Tone.info),
                            for (final s in o.skills.take(3)) StatusBadge(s),
                          ],
                        ),
                      ],
                      Divider(height: 20, color: p.borderSubtle),
                      Row(
                        children: [
                          AppButton(
                            'Applicants',
                            leadingIcon: Icons.assignment_ind_outlined,
                            size: ButtonSize.small,
                            variant: ButtonVariant.ghost,
                            expand: false,
                            onPressed: () => _showOpportunityApplicantsSheet(
                              context,
                              o,
                            ),
                          ),
                          if (adminUid != null) ...[
                            const SizedBox(width: 8),
                            AppButton(
                              'Edit',
                              size: ButtonSize.small,
                              variant: ButtonVariant.secondary,
                              expand: false,
                              onPressed: () => onEdit(o),
                            ),
                          ],
                          if ((StatusTransitions.opportunity[o.status] ??
                                  const <OpportunityStatus>{})
                              .contains(OpportunityStatus.published)) ...[
                            const SizedBox(width: 8),
                            AppButton(
                              'Publish',
                              size: ButtonSize.small,
                              expand: false,
                              onPressed: busy
                                  ? null
                                  : () => onTransition(
                                        o.id,
                                        OpportunityStatus.published,
                                      ),
                            ),
                          ],
                          const Spacer(),
                          Builder(
                            builder: (_) {
                              final secondary =
                                  (StatusTransitions.opportunity[o.status] ??
                                          const <OpportunityStatus>{})
                                      .where(
                                        (s) =>
                                            s != OpportunityStatus.published,
                                      )
                                      .toList(growable: false);
                              if (secondary.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return PopupMenuButton<OpportunityStatus>(
                                enabled: !busy,
                                tooltip: 'More opportunity actions',
                                icon: Icon(
                                  Icons.more_horiz_rounded,
                                  size: 20,
                                  color: p.textSecondary,
                                ),
                                onSelected: (next) => onTransition(o.id, next),
                                itemBuilder: (_) => [
                                  for (final next in secondary)
                                    PopupMenuItem<OpportunityStatus>(
                                      value: next,
                                      child: Text(switch (next) {
                                        OpportunityStatus.published =>
                                          'Publish',
                                        OpportunityStatus.closed => 'Close',
                                        OpportunityStatus.archived => 'Archive',
                                        OpportunityStatus.draft =>
                                          'Move to draft',
                                      }),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _CatalogThumbnail extends StatelessWidget {
  const _CatalogThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: Radii.rMd,
      child: CachedNetworkImage(
        imageUrl: url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            Container(width: 52, height: 52, color: p.sunken),
        errorWidget: (_, _, _) => Container(
          width: 52,
          height: 52,
          color: p.sunken,
          child: Icon(Icons.image_outlined, size: 20, color: p.textMuted),
        ),
      ),
    );
  }
}

void _showOpportunityApplicantsSheet(
  BuildContext context,
  OpportunityListing opportunity,
) {
  showAppSheet<void>(
    context,
    title: '${opportunity.title} · Applicants',
    builder: (_) => _OpportunityApplicantsSheetBody(opportunity: opportunity),
  );
}

class _OpportunityApplicantsSheetBody extends ConsumerStatefulWidget {
  const _OpportunityApplicantsSheetBody({required this.opportunity});

  final OpportunityListing opportunity;

  @override
  ConsumerState<_OpportunityApplicantsSheetBody> createState() =>
      _OpportunityApplicantsSheetBodyState();
}

class _OpportunityApplicantsSheetBodyState
    extends ConsumerState<_OpportunityApplicantsSheetBody> {
  final Set<String> _busyAppIds = {};

  Future<void> _setStatus(
    String applicationId,
    OpportunityApplicationStatus next,
  ) async {
    setState(() => _busyAppIds.add(applicationId));
    try {
      await ref.read(opportunityRepositoryProvider).reviewApplication(
            applicationId: applicationId,
            nextStatus: next,
          );
      if (mounted) showToast(context, 'Application ${next.label.toLowerCase()}');
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busyAppIds.remove(applicationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final appsAsync = ref.watch(
      opportunityApplicationsProvider(widget.opportunity.id),
    );

    return appsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: SkeletonListLoader(rows: 3),
      ),
      error: (e, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load applicants',
        body: errorMessage(e),
      ),
      data: (apps) {
        if (apps.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No applications yet',
            body: 'Student applications for this opportunity will appear here.',
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: apps.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final app = apps[index];
              final busy = _busyAppIds.contains(app.id);
              final allowedNext =
                  StatusTransitions.opportunityApplication[app.status]
                      ?.where((s) => s != OpportunityApplicationStatus.withdrawn)
                      .toList(growable: false) ??
                  const <OpportunityApplicationStatus>[];
              return SurfaceCard(
                color: p.canvas,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.studentName.isEmpty
                                ? app.ownerUid
                                : app.studentName,
                            style: AppText.bodyMStrong.copyWith(
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        StatusBadge(
                          app.status.label,
                          tone: switch (app.status) {
                            OpportunityApplicationStatus.accepted =>
                              Tone.success,
                            OpportunityApplicationStatus.rejected =>
                              Tone.danger,
                            OpportunityApplicationStatus.underReview =>
                              Tone.info,
                            OpportunityApplicationStatus.withdrawn =>
                              Tone.neutral,
                            OpportunityApplicationStatus.submitted =>
                              Tone.warning,
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      app.coverNote,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppButton(
                          'View profile',
                          size: ButtonSize.small,
                          variant: ButtonVariant.ghost,
                          expand: false,
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/user-profile/${app.ownerUid}');
                          },
                        ),
                        if (app.cvAsset != null)
                          AppButton(
                            'Open CV',
                            size: ButtonSize.small,
                            variant: ButtonVariant.ghost,
                            expand: false,
                            onPressed: () =>
                                openLink(context, app.cvAsset!.url),
                          ),
                        for (final next in allowedNext)
                          AppButton(
                            next == OpportunityApplicationStatus.underReview
                                ? 'Shortlist'
                                : next.label,
                            size: ButtonSize.small,
                            variant:
                                next == OpportunityApplicationStatus.rejected
                                ? ButtonVariant.dangerOutline
                                : ButtonVariant.secondary,
                            expand: false,
                            loading: busy,
                            onPressed: () => _setStatus(app.id, next),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
