import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/admin/presentation/widgets/catalog_editor_sheets.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

/// Approved mentors author, preview, manage, and inspect learner engagement on their own courses.
class MentorCoursesScreen extends ConsumerStatefulWidget {
  const MentorCoursesScreen({super.key});

  @override
  ConsumerState<MentorCoursesScreen> createState() =>
      _MentorCoursesScreenState();
}

class _MentorCoursesScreenState extends ConsumerState<MentorCoursesScreen> {
  String _statusFilter = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openEditor(
    String uid,
    String ownerName, {
    Course? existing,
  }) async {
    final saved = await showCourseEditorSheet(
      context,
      adminUid: uid,
      ownerName: ownerName,
      isMentorAuthor: true,
      existing: existing,
    );
    if (saved == true && mounted) {
      showToast(context, 'Course saved');
    }
  }

  Future<void> _transitionCourse(Course course, CourseStatus nextStatus) async {
    if (_busy) return;
    if (nextStatus == CourseStatus.archived) {
      final ok = await showAppDialog(
        context,
        title: 'Archive "${course.title}"?',
        body:
            'Learners will no longer discover this course in the catalog. Existing progress remains preserved.',
        confirmLabel: 'Archive',
        destructive: true,
        icon: Icons.inventory_2_outlined,
      );
      if (!ok || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(courseRepositoryProvider)
          .transitionCourseStatus(courseId: course.id, nextStatus: nextStatus);
      if (mounted) {
        showToast(context, 'Course ${nextStatus.label.toLowerCase()}');
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDraft(Course course) async {
    if (_busy || course.status != CourseStatus.draft) return;
    final ok = await showAppDialog(
      context,
      title: 'Delete draft "${course.title}"?',
      body: 'This permanently deletes the draft course.',
      confirmLabel: 'Delete draft',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(courseRepositoryProvider).deleteCourse(course.id);
      if (mounted) showToast(context, 'Draft deleted');
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openEngagementSheet(Course course, String mentorUid) {
    showAppSheet<void>(
      context,
      title: '${course.title} · Engagement',
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final p = context.palette;
          final engagementAsync = ref.watch(
            courseEngagementProvider((
              courseId: course.id,
              mentorUid: mentorUid,
            )),
          );
          return engagementAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: Space.s4),
              child: SkeletonListLoader(rows: 3, showAvatar: false),
            ),
            error: (e, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load engagement',
              body: errorMessage(e),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'No learner activity yet',
                  body:
                      'Once students start modules or submit proof, their completion progress will appear here.',
                );
              }
              final completed = entries
                  .where((e) => e.status == CourseProgressStatus.completed)
                  .length;
              final avgPercent = entries.isEmpty
                  ? 0
                  : (entries.fold<int>(0, (s, e) => s + e.progressPercent) /
                            entries.length)
                        .round();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _EngagementStat(
                          value: '${entries.length}',
                          label: 'Learners',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EngagementStat(
                          value: '$completed',
                          label: 'Completed',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EngagementStat(
                          value: '$avgPercent%',
                          label: 'Avg progress',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.s4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final entry = entries[index];
                        final done =
                            entry.status == CourseProgressStatus.completed;
                        return SurfaceCard(
                          color: p.canvas,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Learner ${entry.ownerUid.length > 8 ? entry.ownerUid.substring(0, 8) : entry.ownerUid}',
                                      style: AppText.bodySStrong.copyWith(
                                        color: p.textPrimary,
                                      ),
                                    ),
                                  ),
                                  StatusBadge(
                                    done
                                        ? 'Completed'
                                        : '${entry.progressPercent}%',
                                    tone: done ? Tone.success : Tone.info,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ProgressLine(entry.progressPercent / 100),
                              if (entry.evidenceUrl.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                TextLink(
                                  'Open completion proof',
                                  onTap: () =>
                                      openLink(context, entry.evidenceUrl),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;
    final ownerName = session?.displayName ?? 'UpBridge Mentor';

    if (uid == null) {
      return PageFrame(
        largeTitle: l10n.mentorCoursesTitle,
        children: const [SizedBox(height: 16), SkeletonDashboardLoader()],
      );
    }

    final coursesAsync = ref.watch(mentorCoursesProvider(uid));

    return PageFrame(
      largeTitle: l10n.mentorCoursesTitle,
      subtitle: 'Author, publish & track learner engagement',
      actions: [
        CircleIconButton(
          icon: Icons.add_rounded,
          tooltip: l10n.createCourseLabel,
          onTap: () => _openEditor(uid, ownerName),
        ),
        const SizedBox(width: 4),
      ],
      onRefresh: () async => ref.invalidate(mentorCoursesProvider(uid)),
      children: [
        const SizedBox(height: 12),
        AppSearchField(
          controller: _searchCtrl,
          hint: 'Filter your courses by title or skill',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        ChipBar(
          options: const ['All', 'Published', 'Draft', 'Archived'],
          selected: _statusFilter,
          onSelected: (value) => setState(() => _statusFilter = value),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 14),
        coursesAsync.when(
          loading: () => const SkeletonListLoader(rows: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: l10n.errorLoadingTitle,
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(mentorCoursesProvider(uid)),
          ),
          data: (courses) {
            final q = _query.trim().toLowerCase();
            final filtered = courses.where((course) {
              final statusOk = switch (_statusFilter) {
                'Published' => course.status == CourseStatus.published,
                'Draft' => course.status == CourseStatus.draft,
                'Archived' => course.status == CourseStatus.archived,
                _ => true,
              };
              if (!statusOk) return false;
              if (q.isEmpty) return true;
              return course.title.toLowerCase().contains(q) ||
                  course.summary.toLowerCase().contains(q) ||
                  course.skills.any((s) => s.toLowerCase().contains(q));
            }).toList(growable: false);

            final publishedCount = courses
                .where((c) => c.status == CourseStatus.published)
                .length;
            final draftCount = courses
                .where((c) => c.status == CourseStatus.draft)
                .length;

            if (courses.isEmpty) {
              return EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No courses created yet',
                body:
                    'Create your first structured IT or career course with modules, objectives, and resources.',
                action: l10n.createCourseLabel,
                onAction: () => _openEditor(uid, ownerName),
              );
            }

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No courses match your filters',
                body: 'Try clearing your search or switching status filter.',
                action: 'Clear filters',
                onAction: () => setState(() {
                  _statusFilter = 'All';
                  _query = '';
                  _searchCtrl.clear();
                }),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      '$publishedCount Published',
                      tone: Tone.success,
                    ),
                    StatusBadge('$draftCount Draft', tone: Tone.info),
                  ],
                ),
                const SizedBox(height: 12),
                for (final course in filtered) ...[
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (course.coverAsset != null &&
                                course.coverAsset!.url.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: Radii.rMd,
                                child: CachedNetworkImage(
                                  imageUrl: course.coverAsset!.url,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(
                                    width: 68,
                                    height: 68,
                                    color: p.sunken,
                                  ),
                                  errorWidget: (_, _, _) => const IconTile(
                                    Icons.menu_book_rounded,
                                    tone: Tone.info,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              const IconTile(
                                Icons.menu_book_rounded,
                                tone: Tone.info,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          course.title,
                                          style: AppText.titleS.copyWith(
                                            color: p.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(
                                        course.status.label,
                                        tone: switch (course.status) {
                                          CourseStatus.published => Tone.success,
                                          CourseStatus.draft => Tone.info,
                                          CourseStatus.archived => Tone.neutral,
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${course.displayCategory} · ${course.level} · ${course.modules.length} modules · ${course.estimatedMinutes}m',
                                    style: AppText.caption.copyWith(
                                      color: p.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    course.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.bodyS.copyWith(
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (course.skills.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          TagWrap(
                            course.skills.take(4).toList(),
                            tone: Tone.neutral,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AppButton(
                              l10n.previewLabel,
                              leadingIcon: Icons.visibility_outlined,
                              size: ButtonSize.small,
                              variant: ButtonVariant.secondary,
                              expand: false,
                              onPressed: () =>
                                  context.push('/m/course/${course.id}'),
                            ),
                            const SizedBox(width: 8),
                            if (course.status == CourseStatus.draft ||
                                course.status == CourseStatus.archived)
                              AppButton(
                                course.status == CourseStatus.archived
                                    ? 'Restore draft'
                                    : l10n.publishLabel,
                                leadingIcon: Icons.publish_rounded,
                                size: ButtonSize.small,
                                expand: false,
                                onPressed: _busy
                                    ? null
                                    : () => _transitionCourse(
                                        course,
                                        course.status == CourseStatus.archived
                                            ? CourseStatus.draft
                                            : CourseStatus.published,
                                      ),
                              )
                            else
                              AppButton(
                                l10n.edit,
                                leadingIcon: Icons.edit_outlined,
                                size: ButtonSize.small,
                                variant: ButtonVariant.secondary,
                                expand: false,
                                onPressed: _busy
                                    ? null
                                    : () => _openEditor(
                                        uid,
                                        ownerName,
                                        existing: course,
                                      ),
                              ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              tooltip: 'Course options',
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: p.textSecondary,
                              ),
                              onSelected: (action) {
                                switch (action) {
                                  case 'edit':
                                    if (!_busy) {
                                      _openEditor(
                                        uid,
                                        ownerName,
                                        existing: course,
                                      );
                                    }
                                  case 'engagement':
                                    _openEngagementSheet(course, uid);
                                  case 'archive':
                                    if (!_busy) {
                                      _transitionCourse(
                                        course,
                                        CourseStatus.archived,
                                      );
                                    }
                                  case 'delete':
                                    if (!_busy) _deleteDraft(course);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l10n.edit),
                                ),
                                PopupMenuItem(
                                  value: 'engagement',
                                  child: Text(l10n.engagementLabel),
                                ),
                                if (course.status == CourseStatus.published)
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Text(l10n.archiveLabel),
                                  ),
                                if (course.status == CourseStatus.draft)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      l10n.delete,
                                      style: TextStyle(color: p.dangerText),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _EngagementStat extends StatelessWidget {
  const _EngagementStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      color: p.canvas,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.dataMonoL.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.caption.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}
