import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  String _categoryFilter = 'All';
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
    final coursesAsync = ref.watch(publishedCoursesProvider);
    final loadedCourses = coursesAsync.asData?.value ?? const <Course>[];
    final categoryOptions = <String>[
      'All',
      ...{for (final c in loadedCourses) c.displayCategory},
    ];
    final activeCategory = categoryOptions.contains(_categoryFilter)
        ? _categoryFilter
        : 'All';
    final progressMap = {
      for (final p
          in (uid == null
              ? const <CourseProgress>[]
              : ref.watch(userCourseProgressProvider(uid)).asData?.value ??
                    const <CourseProgress>[]))
        p.courseId: p,
    };

    return PageFrame(
      largeTitle: l10n.tabLearn,
      subtitle: 'Technical tracks, soft skills & workshops',
      onRefresh: () async {
        ref.invalidate(publishedCoursesProvider);
        if (uid != null) ref.invalidate(userCourseProgressProvider(uid));
      },
      children: [
        const SizedBox(height: 12),
        AppSearchField(
          controller: _searchCtrl,
          hint: 'Search courses by topic, category, or skill',
          onChanged: (v) => setState(() => _query = v),
        ),
        if (categoryOptions.length > 1) ...[
          const SizedBox(height: 12),
          ChipBar(
            options: categoryOptions,
            selected: activeCategory,
            padding: EdgeInsets.zero,
            onSelected: (v) => setState(() => _categoryFilter = v),
          ),
        ],
        const SizedBox(height: 16),
        coursesAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load courses',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(publishedCoursesProvider),
          ),
          data: (courses) {
            final q = _query.trim().toLowerCase();
            final filtered = courses
                .where((c) {
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
                  return catOk && qOk;
                })
                .toList(growable: false);

            if (courses.isEmpty) {
              return EmptyState(
                icon: Icons.school_outlined,
                title: l10n.noCoursesYet,
                body: l10n.noCoursesBody,
              );
            }
            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching courses',
                body: 'Clear your search or select another category.',
                action: 'Reset filters',
                onAction: () => setState(() {
                  _categoryFilter = 'All';
                  _query = '';
                  _searchCtrl.clear();
                }),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final course in filtered) ...[
                  _CourseCard(
                    course: course,
                    progress: progressMap[course.id],
                    onTap: () => context.push('/course/${course.id}'),
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

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.progress,
    required this.onTap,
  });

  final Course course;
  final CourseProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final status = progress?.status ?? CourseProgressStatus.notStarted;
    final (badgeLabel, tone) = switch (status) {
      CourseProgressStatus.completed => ('Completed', Tone.success),
      CourseProgressStatus.inProgress => (
        '${progress?.progressPercent ?? 0}%',
        Tone.info,
      ),
      CourseProgressStatus.notStarted => (course.displayCategory, Tone.neutral),
    };

    return SurfaceCard(
      onTap: onTap,
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
                        Icons.school_outlined,
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
                  course.title,
                  style: AppText.titleS.copyWith(color: p.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(badgeLabel, tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            course.summary,
            style: AppText.bodyS.copyWith(color: p.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          MonoLabel(
            '${course.displayCategory} · ${course.modules.length} modules · ${course.estimatedMinutes} min · ${course.level}',
          ),
          if (status == CourseProgressStatus.inProgress) ...[
            const SizedBox(height: 10),
            ProgressLine((progress?.progressPercent ?? 0) / 100),
          ],
        ],
      ),
    );
  }
}
