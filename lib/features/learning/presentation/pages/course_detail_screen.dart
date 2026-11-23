import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/cloudinary_media_picker.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.previewOnly = false,
  });

  final String courseId;
  final bool previewOnly;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final _evidenceUrl = TextEditingController();
  MediaAsset? _evidenceAsset;
  bool _hydratedEvidence = false;
  bool _hydrationScheduled = false;
  bool _builtOnce = false;
  bool _submitting = false;

  bool _isSettled<T>(AsyncValue<T> value) =>
      !value.isLoading || value.hasValue || value.hasError;

  void _applyEvidenceHydration(CourseProgress? progress) {
    if (_hydratedEvidence) return;
    _hydratedEvidence = true;
    _evidenceUrl.text = progress?.evidenceUrl ?? '';
    _evidenceAsset = progress?.evidenceAsset;
  }

  void _scheduleEvidenceHydration(CourseProgress? progress) {
    if (_hydratedEvidence || _hydrationScheduled) return;
    _hydrationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrationScheduled = false;
      if (!mounted || _hydratedEvidence) return;
      setState(() {
        _applyEvidenceHydration(progress);
      });
    });
  }

  @override
  void dispose() {
    _evidenceUrl.dispose();
    super.dispose();
  }

  Future<void> _toggleModule(String uid, Course course, String moduleId) async {
    try {
      await ref
          .read(courseRepositoryProvider)
          .toggleModuleCompletion(uid: uid, course: course, moduleId: moduleId);
    } catch (error) {
      if (mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    }
  }

  Future<void> _submitEvidence(String uid, Course course) async {
    final link = _evidenceUrl.text.trim();
    final urlError = Validators.optionalUrl(link);
    if (urlError != null) {
      showToast(context, urlError, tone: Tone.warning);
      return;
    }
    if (link.isEmpty && _evidenceAsset == null) {
      showToast(
        context,
        'Add a link or upload proof to complete this course.',
        tone: Tone.warning,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(courseRepositoryProvider)
          .submitCourseEvidence(
            uid: uid,
            course: course,
            evidenceUrl: link,
            evidenceAsset: _evidenceAsset,
          );
      if (mounted) showToast(context, 'Course completed and proof saved');
    } catch (error) {
      if (mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final progressAsync = (uid == null || widget.previewOnly)
        ? null
        : ref.watch(
            _singleCourseProgressProvider((
              uid: uid,
              courseId: widget.courseId,
            )),
          );
    final backRoute = widget.previewOnly
        ? (session?.role == UserRole.admin ? '/a/catalog' : '/m/courses')
        : '/learn';

    if (uid != null && !widget.previewOnly) {
      final progressProvider = _singleCourseProgressProvider((
        uid: uid,
        courseId: widget.courseId,
      ));
      ref.listen(progressProvider, (_, next) {
        if (!_hydratedEvidence && _isSettled(next) && mounted) {
          setState(() {
            _applyEvidenceHydration(next.asData?.value);
          });
        }
      });
      if (!_hydratedEvidence &&
          progressAsync != null &&
          _isSettled(progressAsync)) {
        if (!_builtOnce) {
          _applyEvidenceHydration(progressAsync.asData?.value);
        } else {
          _scheduleEvidenceHydration(progressAsync.asData?.value);
        }
      }
    }
    _builtOnce = true;

    return courseAsync.when(
      loading: () => DetailPage(
        title: 'Course',
        backFallback: backRoute,
        children: const [SkeletonDetailPageLoader()],
      ),
      error: (error, _) => DetailPage(
        title: 'Course',
        backFallback: backRoute,
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load course',
            body: errorMessage(error),
            action: 'Try again',
            onAction: () => ref.invalidate(courseDetailProvider(widget.courseId)),
          ),
        ],
      ),
      data: (course) {
        if (course == null) {
          return DetailPage(
            title: 'Course not found',
            backFallback: backRoute,
            children: const [
              EmptyState(
                icon: Icons.school_outlined,
                title: 'Course unavailable',
                body: 'This course may have been archived.',
              ),
            ],
          );
        }

        final progress = progressAsync?.asData?.value;
        final completedIds = progress?.completedModuleIds.toSet() ?? <String>{};
        final percent = progress?.progressPercent ?? 0;

        return DetailPage(
          title: course.title,
          backFallback: backRoute,
          children: [
            const SizedBox(height: 8),
            if (widget.previewOnly) ...[
              NoticeCard(
                tone: Tone.info,
                icon: Icons.visibility_outlined,
                title: 'Course preview (${course.status.label})',
                body:
                    'You are viewing how learners see this course. Module checkboxes and proof submission are disabled in preview mode.',
              ),
              const SizedBox(height: 12),
            ],
            if (course.coverAsset != null &&
                course.coverAsset!.url.isNotEmpty) ...[
              ClipRRect(
                borderRadius: Radii.rLg,
                child: CachedNetworkImage(
                  imageUrl: course.coverAsset!.url,
                  height: 168,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(height: 168, color: p.sunken),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            StatusBadge(
                              course.displayCategory,
                              tone: Tone.info,
                            ),
                            StatusBadge(course.level),
                            StatusBadge('${course.estimatedMinutes} min'),
                          ],
                        ),
                      ),
                      if (!widget.previewOnly) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: AppText.dataMonoStrong.copyWith(
                            color: p.accentText,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (course.ownerName.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Instructor: ${course.ownerName}',
                      style: AppText.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    course.summary,
                    style: AppText.bodyM.copyWith(color: p.textSecondary),
                  ),
                  if (!widget.previewOnly) ...[
                    const SizedBox(height: 12),
                    ProgressLine(percent / 100),
                  ],
                  if (course.skills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TagWrap(course.skills, tone: Tone.info),
                  ],
                ],
              ),
            ),
            if (course.learningObjectives.isNotEmpty) ...[
              const SectionLabel('What you will learn'),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final obj in course.learningObjectives) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: p.successText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              obj,
                              style: AppText.bodyS.copyWith(
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (obj != course.learningObjectives.last)
                        const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ],
            const SectionLabel('Modules'),
            if (course.modules.isEmpty)
              const EmptyState(
                icon: Icons.list_alt_outlined,
                title: 'No modules added yet',
              )
            else
              ListGroup(
                children: [
                  for (final m in course.modules)
                    ListRow(
                      leading: Icon(
                        completedIds.contains(m.id)
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: completedIds.contains(m.id)
                            ? p.successText
                            : p.borderStrong,
                      ),
                      title: m.title,
                      subtitle: m.summary,
                      meta: '${m.estimatedMinutes} min',
                      trailing: m.resourceUrl.isNotEmpty
                          ? IconButton(
                              tooltip: 'Open resource',
                              onPressed: () => openLink(context, m.resourceUrl),
                              icon: const Icon(Icons.open_in_new_rounded),
                            )
                          : null,
                      chevron: false,
                      onTap: (uid == null || widget.previewOnly)
                          ? null
                          : () => _toggleModule(uid, course, m.id),
                    ),
                ],
              ),
            if (course.resources.isNotEmpty) ...[
              const SectionLabel('Course resources'),
              ListGroup(
                children: [
                  for (final res in course.resources)
                    ListRow(
                      leading: Icon(Icons.link_rounded, color: p.infoText),
                      title: res.title,
                      subtitle: res.url,
                      onTap: () => openLink(context, res.url),
                    ),
                ],
              ),
            ],
            if (uid != null && !widget.previewOnly) ...[
              const SectionLabel('Submit completion proof'),
              AppTextField(
                label: 'Project or repository link',
                trailingNote: 'Optional if uploading file',
                hint: 'https://github.com/...',
                controller: _evidenceUrl,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              CloudinaryMediaPicker(
                ownerUid: uid,
                label: 'Supporting screenshot or certificate image',
                helperText: 'JPG, JPEG, PNG, or WebP image (max 10 MB).',
                category: 'course-evidence',
                imagesOnly: false,
                initialAsset: _evidenceAsset,
                onAssetChanged: (asset) =>
                    setState(() => _evidenceAsset = asset),
              ),
              const SizedBox(height: 16),
              AppButton(
                progress?.status == CourseProgressStatus.completed
                    ? 'Update completion proof'
                    : 'Submit & mark completed',
                loading: _submitting,
                onPressed: () => _submitEvidence(uid, course),
              ),
            ],
          ],
        );
      },
    );
  }
}

final _singleCourseProgressProvider = StreamProvider.autoDispose
    .family<CourseProgress?, ({String uid, String courseId})>(
      (ref, q) => ref
          .watch(courseRepositoryProvider)
          .watchCourseProgress(q.uid, q.courseId),
    );
