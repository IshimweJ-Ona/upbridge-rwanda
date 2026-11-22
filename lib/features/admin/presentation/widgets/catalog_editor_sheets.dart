import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/widgets/cloudinary_media_picker.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

/// Opens the rich, extensible course creation/edit modal sheet for admins and approved mentors.
Future<bool?> showCourseEditorSheet(
  BuildContext context, {
  required String adminUid,
  String ownerName = '',
  bool isMentorAuthor = false,
  Course? existing,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => CourseEditorSheet(
    adminUid: adminUid,
    ownerName: ownerName,
    isMentorAuthor: isMentorAuthor,
    existing: existing,
  ),
);

/// Opens the rich, extensible opportunity creation/edit modal sheet.
Future<bool?> showOpportunityEditorSheet(
  BuildContext context, {
  required String adminUid,
  OpportunityListing? existing,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      OpportunityEditorSheet(adminUid: adminUid, existing: existing),
);

const List<String> _courseLevelPresets = [
  'Beginner',
  'Intermediate',
  'Advanced',
  'All levels',
  'Bootcamp',
  'Certificate prep',
];

const List<String> _courseSkillSuggestions = [
  'Dart',
  'Flutter',
  'Python',
  'JavaScript',
  'React',
  'SQL',
  'UI/UX',
  'Git',
  'Cloud',
  'Communication',
  'Leadership',
  'Public Speaking',
  'CV Writing',
  'Interviewing',
];

const List<String> _opportunityWorkModes = ['Onsite', 'Remote', 'Hybrid'];

const List<String> _opportunityCompensationPresets = [
  'Paid',
  'Monthly Stipend',
  'Scholarship',
  'Unpaid / Credit',
];

const List<String> _opportunitySkillSuggestions = [
  'Flutter',
  'Dart',
  'Python',
  'JavaScript',
  'Data Analysis',
  'UI/UX Design',
  'Project Management',
  'Communication',
  'Research',
  'Kinyarwanda',
  'English',
  'French',
];

class CourseEditorSheet extends ConsumerStatefulWidget {
  const CourseEditorSheet({
    super.key,
    required this.adminUid,
    this.ownerName = '',
    this.isMentorAuthor = false,
    this.existing,
  });

  final String adminUid;
  final String ownerName;
  final bool isMentorAuthor;
  final Course? existing;

  @override
  ConsumerState<CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends ConsumerState<CourseEditorSheet> {
  late final TextEditingController _titleCtrl = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _summaryCtrl = TextEditingController(
    text: widget.existing?.summary ?? '',
  );
  late final TextEditingController _objectivesCtrl = TextEditingController(
    text: widget.existing?.learningObjectives.join('\n') ?? '',
  );
  late final TextEditingController _customCategoryCtrl = TextEditingController(
    text: widget.existing?.customCategory ?? '',
  );
  late final TextEditingController _customLevelCtrl = TextEditingController();
  late final TextEditingController _minsCtrl = TextEditingController(
    text: '${widget.existing?.estimatedMinutes ?? 60}',
  );
  late final TextEditingController _bulkModulesCtrl = TextEditingController();

  late CourseCategory _category = _resolveInitialCategory(widget.existing);
  late String _levelSelection = _resolveInitialLevel(widget.existing?.level);
  late List<String> _skills = List<String>.from(
    widget.existing?.skills ?? const [],
  );
  late MediaAsset? _coverAsset = widget.existing?.coverAsset;
  late CourseStatus _selectedStatus =
      widget.existing?.status ??
      (widget.isMentorAuthor ? CourseStatus.draft : CourseStatus.published);
  late final List<_ModuleDraft> _modules = _buildInitialModules(
    widget.existing,
  );
  late final List<_ResourceDraft> _resources = _buildInitialResources(
    widget.existing,
  );

  bool _showBulkImport = false;
  bool _busy = false;
  String? _error;

  static List<_ResourceDraft> _buildInitialResources(Course? existing) {
    if (existing == null || existing.resources.isEmpty) {
      return [];
    }
    return [
      for (var i = 0; i < existing.resources.length; i++)
        _ResourceDraft(
          id: existing.resources[i].id,
          title: existing.resources[i].title,
          url: existing.resources[i].url,
        ),
    ];
  }

  static CourseCategory _resolveInitialCategory(Course? existing) {
    if (existing == null) return CourseCategory.it;
    if (existing.customCategory.trim().isNotEmpty) {
      return CourseCategory.custom;
    }
    return existing.category;
  }

  String _resolveInitialLevel(String? raw) {
    final normalized = (raw ?? 'Beginner').trim();
    if (normalized.isEmpty) return 'Beginner';
    for (final preset in _courseLevelPresets) {
      if (preset.toLowerCase() == normalized.toLowerCase()) {
        return preset;
      }
    }
    _customLevelCtrl.text = normalized;
    return 'Custom';
  }

  static List<_ModuleDraft> _buildInitialModules(Course? existing) {
    if (existing == null || existing.modules.isEmpty) {
      return [_ModuleDraft(id: 'mod_1')];
    }
    return [
      for (var i = 0; i < existing.modules.length; i++)
        _ModuleDraft.fromModule(existing.modules[i], fallbackIndex: i + 1),
    ];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _objectivesCtrl.dispose();
    _customCategoryCtrl.dispose();
    _customLevelCtrl.dispose();
    _minsCtrl.dispose();
    _bulkModulesCtrl.dispose();
    for (final m in _modules) {
      m.dispose();
    }
    for (final r in _resources) {
      r.dispose();
    }
    super.dispose();
  }

  void _addResource() {
    setState(() {
      _resources.add(_ResourceDraft(id: 'res_${_resources.length + 1}'));
    });
  }

  void _removeResource(int index) {
    setState(() {
      final removed = _resources.removeAt(index);
      removed.dispose();
    });
  }

  void _addModule() {
    setState(() {
      _modules.add(_ModuleDraft(id: 'mod_${_modules.length + 1}'));
    });
  }

  void _removeModule(int index) {
    setState(() {
      final removed = _modules.removeAt(index);
      removed.dispose();
    });
  }

  void _moveModule(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _modules.length) return;
    setState(() {
      final item = _modules.removeAt(index);
      _modules.insert(target, item);
    });
  }

  void _applyBulkImport() {
    final lines = _bulkModulesCtrl.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) return;
    setState(() {
      // Replace a single pristine placeholder module rather than leaving an empty row above imports.
      if (_modules.length == 1 && _modules.first.isBlank) {
        _modules.first.dispose();
        _modules.clear();
      }
      for (final line in lines) {
        _modules.add(
          _ModuleDraft(id: 'mod_${_modules.length + 1}', title: line),
        );
      }
      _bulkModulesCtrl.clear();
      _showBulkImport = false;
    });
  }

  int get _moduleTotalMinutes => _modules.fold<int>(
    0,
    (sum, m) => sum + (int.tryParse(m.minsCtrl.text.trim()) ?? 20),
  );

  void _syncDurationFromModules() {
    final total = _moduleTotalMinutes;
    if (total > 0) {
      setState(() => _minsCtrl.text = '$total');
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final summary = _summaryCtrl.text.trim();
    if (title.length < 3 || summary.length < 10) {
      setState(
        () => _error = 'Provide a title and summary (min 10 characters).',
      );
      return;
    }

    final customCat = _customCategoryCtrl.text.trim();
    if (_category == CourseCategory.custom && customCat.isEmpty) {
      setState(
        () => _error =
            'Enter a custom category name or choose one of the presets.',
      );
      return;
    }

    final resolvedLevel = _levelSelection == 'Custom'
        ? _customLevelCtrl.text.trim()
        : _levelSelection;
    if (resolvedLevel.isEmpty) {
      setState(
        () =>
            _error = 'Enter a custom level name or choose one of the presets.',
      );
      return;
    }

    final modules = <CourseModule>[];
    for (var i = 0; i < _modules.length; i++) {
      final draft = _modules[i];
      final moduleTitle = draft.titleCtrl.text.trim();
      if (moduleTitle.isEmpty) continue;
      final urlErr = Validators.optionalUrl(draft.urlCtrl.text);
      if (urlErr != null) {
        setState(() => _error = 'Module ${i + 1}: $urlErr');
        return;
      }
      modules.add(
        CourseModule(
          id: draft.id.trim().isEmpty ? 'mod_${i + 1}' : draft.id.trim(),
          title: moduleTitle,
          summary: draft.summaryCtrl.text.trim(),
          resourceUrl: draft.urlCtrl.text.trim(),
          estimatedMinutes: (int.tryParse(draft.minsCtrl.text.trim()) ?? 20)
              .clamp(1, 600),
        ),
      );
    }

    final resources = <CourseResource>[];
    for (var i = 0; i < _resources.length; i++) {
      final r = _resources[i];
      final rTitle = r.titleCtrl.text.trim();
      final rUrl = r.urlCtrl.text.trim();
      if (rTitle.isEmpty && rUrl.isEmpty) continue;
      final urlErr = Validators.url(rUrl);
      if (urlErr != null || rTitle.isEmpty) {
        setState(
          () => _error =
              'Resource ${i + 1}: Provide a title and valid https:// URL.',
        );
        return;
      }
      resources.add(
        CourseResource(
          id: r.id.trim().isEmpty ? 'res_${i + 1}' : r.id.trim(),
          title: rTitle,
          url: rUrl,
        ),
      );
    }

    final objectives = _objectivesCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final estimatedMinutes =
        int.tryParse(_minsCtrl.text.trim()) ??
        (modules.isEmpty ? 60 : _moduleTotalMinutes.clamp(5, 1200));
    final now = DateTime.now().toUtc();
    final repo = ref.read(courseRepositoryProvider);

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final existing = widget.existing;
      final resolvedOwnerName =
          (existing != null && existing.ownerName.trim().isNotEmpty)
          ? existing.ownerName
          : widget.ownerName.trim();
      final savedId = await repo.saveCourse(
        Course(
          id: existing?.id ?? '',
          ownerUid: existing?.ownerUid ?? widget.adminUid,
          ownerName: resolvedOwnerName,
          title: title,
          summary: summary,
          category: _category,
          customCategory: _category == CourseCategory.custom ? customCat : '',
          level: resolvedLevel,
          estimatedMinutes: estimatedMinutes.clamp(5, 1200),
          learningObjectives: objectives,
          resources: resources,
          modules: modules,
          skills: _skills,
          coverAsset: _coverAsset,
          status: existing?.status ?? _selectedStatus,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );

      if (existing != null && _selectedStatus != existing.status) {
        await repo.transitionCourseStatus(
          courseId: savedId,
          nextStatus: _selectedStatus,
        );
      }

      if (!widget.isMentorAuthor) {
        ref.invalidate(platformMetricsProvider);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final availableStatuses = widget.existing == null
        ? const [CourseStatus.published, CourseStatus.draft]
        : [
            widget.existing!.status,
            ...(StatusTransitions.course[widget.existing!.status] ??
                const <CourseStatus>{}),
          ];

    return _EditorSheetShell(
      title: widget.existing == null ? 'Create course' : 'Edit course',
      subtitle: 'Choose any category, custom track, level, unlimited skills, and detailed modules.',
      error: _error,
      busy: _busy,
      primaryLabel: widget.existing == null
          ? (_selectedStatus == CourseStatus.published
                ? 'Publish course'
                : 'Save course draft')
          : 'Update course',
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Course title',
            hint: 'e.g. Flutter Mobile Foundations or AgriTech Sensors 101',
            controller: _titleCtrl,
            onChanged: (_) => _clearError(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Summary',
            hint: 'Explain what learners will build, tools covered, and outcomes.',
            controller: _summaryCtrl,
            maxLines: 3,
            onChanged: (_) => _clearError(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Learning objectives (one per line)',
            hint: 'Design layered Flutter apps\nWrite Firestore security rules',
            controller: _objectivesCtrl,
            maxLines: 3,
            onChanged: (_) => _clearError(),
          ),
          const SizedBox(height: 16),
          const MonoLabel('Category (preset or custom)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in CourseCategory.values)
                SelectChip(
                  label: cat.label,
                  selected: _category == cat,
                  onTap: () => setState(() {
                    _category = cat;
                    _error = null;
                  }),
                ),
            ],
          ),
          if (_category == CourseCategory.custom) ...[
            const SizedBox(height: 12),
            AppTextField(
              label: 'Custom category name',
              hint: 'e.g. Robotics, AgriTech, French for Tech, Blockchain',
              controller: _customCategoryCtrl,
              onChanged: (_) => _clearError(),
            ),
          ],
          const SizedBox(height: 16),
          const MonoLabel('Difficulty / Track level'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in [..._courseLevelPresets, 'Custom'])
                SelectChip(
                  label: preset,
                  selected: _levelSelection == preset,
                  onTap: () => setState(() {
                    _levelSelection = preset;
                    _error = null;
                  }),
                ),
            ],
          ),
          if (_levelSelection == 'Custom') ...[
            const SizedBox(height: 12),
            AppTextField(
              label: 'Custom level name',
              hint: 'e.g. Executive, Capstone, Youth Cohort',
              controller: _customLevelCtrl,
              onChanged: (_) => _clearError(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Total duration (minutes)',
                  controller: _minsCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              if (_modules.isNotEmpty) ...[
                const SizedBox(width: 8),
                AppButton(
                  'Use modules (${_moduleTotalMinutes}m)',
                  size: ButtonSize.medium,
                  variant: ButtonVariant.secondary,
                  expand: false,
                  onPressed: _syncDurationFromModules,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _SkillSelectorSection(
            selectedSkills: _skills,
            suggestedSkills: _courseSkillSuggestions,
            onChanged: (next) => setState(() => _skills = next),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: MonoLabel('Curriculum modules')),
              TextLink(
                _showBulkImport ? 'Hide bulk import' : 'Bulk paste lines',
                onTap: () => setState(() => _showBulkImport = !_showBulkImport),
              ),
            ],
          ),
          if (_showBulkImport) ...[
            const SizedBox(height: 8),
            SurfaceCard(
              color: p.canvas,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Module titles (one per line)',
                    hint: 'Intro & Setup\nCore Architecture\nCapstone Project',
                    controller: _bulkModulesCtrl,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    'Append listed modules',
                    size: ButtonSize.small,
                    variant: ButtonVariant.secondary,
                    onPressed: _applyBulkImport,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < _modules.length; i++) ...[
            _ModuleCard(
              index: i,
              total: _modules.length,
              draft: _modules[i],
              onMoveUp: i > 0 ? () => _moveModule(i, -1) : null,
              onMoveDown: i < _modules.length - 1
                  ? () => _moveModule(i, 1)
                  : null,
              onRemove: () => _removeModule(i),
            ),
            const SizedBox(height: 10),
          ],
          AppButton(
            'Add module',
            leadingIcon: Icons.add_rounded,
            variant: ButtonVariant.secondary,
            size: ButtonSize.medium,
            onPressed: _addModule,
          ),
          const SizedBox(height: 16),
          const MonoLabel('Supporting resources (links)'),
          const SizedBox(height: 8),
          for (var i = 0; i < _resources.length; i++) ...[
            SurfaceCard(
              color: p.canvas,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: MonoLabel('Resource ${i + 1}')),
                      IconButton(
                        tooltip: 'Remove resource',
                        icon: Icon(Icons.delete_outline_rounded, color: p.dangerText),
                        onPressed: () => _removeResource(i),
                      ),
                    ],
                  ),
                  AppTextField(
                    label: 'Resource title',
                    hint: 'Official documentation or workbook',
                    controller: _resources[i].titleCtrl,
                    onChanged: (_) => _clearError(),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    label: 'Resource URL',
                    hint: 'https://...',
                    controller: _resources[i].urlCtrl,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => _clearError(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          AppButton(
            'Add resource link',
            leadingIcon: Icons.link_rounded,
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
            onPressed: _addResource,
          ),
          const SizedBox(height: 16),
          CloudinaryMediaPicker(
            ownerUid: widget.adminUid,
            label: 'Cover image (optional)',
            helperText: 'JPG, JPEG, PNG, or WebP image (max 10 MB).',
            category: 'course-covers',
            initialAsset: _coverAsset,
            onAssetChanged: (asset) => setState(() => _coverAsset = asset),
          ),
          const SizedBox(height: 16),
          const MonoLabel('Publishing status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in availableStatuses)
                SelectChip(
                  label: status == CourseStatus.published
                      ? 'Published (visible to students)'
                      : status.label,
                  selected: _selectedStatus == status,
                  onTap: () => setState(() => _selectedStatus = status),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }
}

class OpportunityEditorSheet extends ConsumerStatefulWidget {
  const OpportunityEditorSheet({
    super.key,
    required this.adminUid,
    this.existing,
  });

  final String adminUid;
  final OpportunityListing? existing;

  @override
  ConsumerState<OpportunityEditorSheet> createState() =>
      _OpportunityEditorSheetState();
}

class _OpportunityEditorSheetState
    extends ConsumerState<OpportunityEditorSheet> {
  late final TextEditingController _titleCtrl = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _orgCtrl = TextEditingController(
    text: widget.existing?.organization ?? '',
  );
  late final TextEditingController _locationCtrl = TextEditingController(
    text: widget.existing?.location ?? 'Kigali, Rwanda',
  );
  late final TextEditingController _customTypeCtrl = TextEditingController(
    text: widget.existing?.customType ?? '',
  );
  late final TextEditingController _customWorkModeCtrl =
      TextEditingController();
  late final TextEditingController _compCtrl = TextEditingController(
    text: widget.existing?.compensation ?? '',
  );
  late final TextEditingController _descCtrl = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final TextEditingController _reqCtrl = TextEditingController(
    text: widget.existing?.requirements.join('\n') ?? '',
  );
  late final TextEditingController _urlCtrl = TextEditingController(
    text: widget.existing?.applyUrl ?? '',
  );

  late OpportunityType _type = _resolveInitialType(widget.existing);
  late String _workModeSelection = _resolveInitialWorkMode(
    widget.existing?.workMode,
  );
  late List<String> _skills = List<String>.from(
    widget.existing?.skills ?? const [],
  );
  late MediaAsset? _coverAsset = widget.existing?.coverAsset;
  late DateTime _deadline =
      widget.existing?.deadline ?? DateTime.now().add(const Duration(days: 30));
  late OpportunityStatus _selectedStatus =
      widget.existing?.status ?? OpportunityStatus.published;

  bool _busy = false;
  String? _error;

  static OpportunityType _resolveInitialType(OpportunityListing? existing) {
    if (existing == null) return OpportunityType.internship;
    if (existing.customType.trim().isNotEmpty) {
      return OpportunityType.custom;
    }
    return existing.type;
  }

  String _resolveInitialWorkMode(String? raw) {
    final normalized = (raw ?? '').trim();
    if (normalized.isEmpty) return '';
    for (final preset in _opportunityWorkModes) {
      if (preset.toLowerCase() == normalized.toLowerCase()) {
        return preset;
      }
    }
    _customWorkModeCtrl.text = normalized;
    return 'Custom';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    _locationCtrl.dispose();
    _customTypeCtrl.dispose();
    _customWorkModeCtrl.dispose();
    _compCtrl.dispose();
    _descCtrl.dispose();
    _reqCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final org = _orgCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.length < 3 || org.isEmpty || desc.length < 10) {
      setState(
        () => _error =
            'Provide title, organization, and description (min 10 chars).',
      );
      return;
    }

    final customType = _customTypeCtrl.text.trim();
    if (_type == OpportunityType.custom && customType.isEmpty) {
      setState(
        () => _error =
            'Enter a custom opportunity type or select one of the presets.',
      );
      return;
    }

    final resolvedWorkMode = _workModeSelection == 'Custom'
        ? _customWorkModeCtrl.text.trim()
        : _workModeSelection;

    final now = DateTime.now().toUtc();
    final repo = ref.read(opportunityRepositoryProvider);

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final existing = widget.existing;
      final savedId = await repo.saveOpportunity(
        OpportunityListing(
          id: existing?.id ?? '',
          ownerUid: existing?.ownerUid ?? widget.adminUid,
          title: title,
          organization: org,
          location: _locationCtrl.text.trim(),
          type: _type,
          customType: _type == OpportunityType.custom ? customType : '',
          workMode: resolvedWorkMode,
          compensation: _compCtrl.text.trim(),
          coverAsset: _coverAsset,
          description: desc,
          requirements: _reqCtrl.text
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false),
          skills: _skills,
          applyUrl: _urlCtrl.text.trim(),
          deadline: _deadline.toUtc(),
          status: existing?.status ?? _selectedStatus,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );

      if (existing != null && _selectedStatus != existing.status) {
        await repo.transitionOpportunityStatus(
          opportunityId: savedId,
          nextStatus: _selectedStatus,
        );
      }

      ref.invalidate(platformMetricsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableStatuses = widget.existing == null
        ? const [OpportunityStatus.published, OpportunityStatus.draft]
        : [
            widget.existing!.status,
            ...(StatusTransitions.opportunity[widget.existing!.status] ??
                const <OpportunityStatus>{}),
          ];

    return _EditorSheetShell(
      title: widget.existing == null ? 'Post opportunity' : 'Edit opportunity',
      subtitle: 'Publish any program, grant, fellowship, gig, or custom role with flexible terms.',
      error: _error,
      busy: _busy,
      primaryLabel: widget.existing == null
          ? (_selectedStatus == OpportunityStatus.published
                ? 'Publish opportunity'
                : 'Save opportunity draft')
          : 'Update opportunity',
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Role or program title',
            hint: 'e.g. Junior Mobile Engineer or Youth AI Fellowship',
            controller: _titleCtrl,
            onChanged: (_) => _clearError(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Organization / host',
            hint: 'e.g. Kigali Tech Studio',
            controller: _orgCtrl,
            onChanged: (_) => _clearError(),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Location', controller: _locationCtrl),
          const SizedBox(height: 14),
          const MonoLabel('Work / Attendance mode (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in [..._opportunityWorkModes, 'Custom'])
                SelectChip(
                  label: mode,
                  selected: _workModeSelection == mode,
                  onTap: () => setState(() {
                    _workModeSelection = _workModeSelection == mode ? '' : mode;
                  }),
                ),
            ],
          ),
          if (_workModeSelection == 'Custom') ...[
            const SizedBox(height: 10),
            AppTextField(
              label: 'Custom work mode',
              hint: 'e.g. Cohort Residential, Self-paced online',
              controller: _customWorkModeCtrl,
            ),
          ],
          const SizedBox(height: 16),
          const MonoLabel('Opportunity type (preset or custom)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in OpportunityType.values)
                SelectChip(
                  label: t.label,
                  selected: _type == t,
                  onTap: () => setState(() {
                    _type = t;
                    _error = null;
                  }),
                ),
            ],
          ),
          if (_type == OpportunityType.custom) ...[
            const SizedBox(height: 12),
            AppTextField(
              label: 'Custom opportunity type',
              hint: 'e.g. Incubator, Venture Grant, Residency, Study Tour',
              controller: _customTypeCtrl,
              onChanged: (_) => _clearError(),
            ),
          ],
          const SizedBox(height: 16),
          const MonoLabel('Compensation / Stipend (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _opportunityCompensationPresets)
                SelectChip(
                  label: preset,
                  selected: _compCtrl.text.trim() == preset,
                  onTap: () => setState(() {
                    _compCtrl.text = _compCtrl.text.trim() == preset
                        ? ''
                        : preset;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: 'Compensation details (optional)',
            hint: 'e.g. RWF 250,000/month, Full travel stipend, Equity grant',
            controller: _compCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          const MonoLabel('Application deadline'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final days in const [14, 30, 90, 180, 365])
                SelectChip(
                  label: days >= 365
                      ? '+1 yr'
                      : days >= 180
                      ? '+6 mo'
                      : '+$days d',
                  showCheck: false,
                  selected: false,
                  onTap: () => setState(
                    () => _deadline = DateTime.now().add(Duration(days: days)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SurfaceCard(
            onTap: () async {
              final now = DateTime.now();
              final lastDate = now.add(const Duration(days: 365 * 5));
              final safeInitial = _deadline.isBefore(now)
                  ? now
                  : (_deadline.isAfter(lastDate) ? lastDate : _deadline);
              final picked = await showDatePicker(
                context: context,
                initialDate: safeInitial,
                firstDate: now,
                lastDate: lastDate,
              );
              if (picked != null && mounted) {
                setState(() => _deadline = picked);
              }
            },
            child: ListRow(
              padding: EdgeInsets.zero,
              leading: const IconTile(
                Icons.calendar_today_outlined,
                tone: Tone.info,
              ),
              title: 'Application deadline',
              subtitle: DateFormat('d MMM y').format(_deadline.toLocal()),
              chevron: false,
              trailing: Text(
                'Change',
                style: AppText.bodySStrong.copyWith(
                  color: context.palette.link,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Description',
            hint: 'Responsibilities, program format, and how youth benefit.',
            controller: _descCtrl,
            maxLines: 3,
            onChanged: (_) => _clearError(),
          ),
          const SizedBox(height: 14),
          _SkillSelectorSection(
            selectedSkills: _skills,
            suggestedSkills: _opportunitySkillSuggestions,
            onChanged: (next) => setState(() => _skills = next),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Requirements (one per line)',
            hint: 'Portfolio link or GitHub profile\nAvailable 20 hrs/week',
            controller: _reqCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'External application URL (optional)',
            hint: 'https://...',
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          CloudinaryMediaPicker(
            ownerUid: widget.adminUid,
            label: 'Partner / banner image (optional)',
            helperText: 'JPG, JPEG, PNG, or WebP image (max 10 MB).',
            category: 'opportunity-covers',
            initialAsset: _coverAsset,
            onAssetChanged: (asset) => setState(() => _coverAsset = asset),
          ),
          const SizedBox(height: 16),
          const MonoLabel('Publishing status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in availableStatuses)
                SelectChip(
                  label: status == OpportunityStatus.published
                      ? 'Published (visible to students)'
                      : status.label,
                  selected: _selectedStatus == status,
                  onTap: () => setState(() => _selectedStatus = status),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }
}

class _EditorSheetShell extends StatelessWidget {
  const _EditorSheetShell({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onSubmit,
    required this.child,
    this.error,
    this.busy = false,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onSubmit;
  final Widget child;
  final String? error;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                16,
                Space.s2,
                12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.titleM.copyWith(color: p.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppText.bodyS.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: p.borderSubtle),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  16,
                  Space.gutter,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      NoticeCard(
                        title: error!,
                        tone: Tone.danger,
                        icon: Icons.error_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],
                    child,
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: p.borderSubtle),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  12,
                  Space.gutter,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        'Cancel',
                        variant: ButtonVariant.secondary,
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        primaryLabel,
                        loading: busy,
                        onPressed: onSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillSelectorSection extends StatefulWidget {
  const _SkillSelectorSection({
    required this.selectedSkills,
    required this.suggestedSkills,
    required this.onChanged,
  });

  final List<String> selectedSkills;
  final List<String> suggestedSkills;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_SkillSelectorSection> createState() => _SkillSelectorSectionState();
}

class _SkillSelectorSectionState extends State<_SkillSelectorSection> {
  final TextEditingController _customSkillCtrl = TextEditingController();

  @override
  void dispose() {
    _customSkillCtrl.dispose();
    super.dispose();
  }

  void _toggleSkill(String skill) {
    final lower = skill.toLowerCase();
    final updated = List<String>.from(widget.selectedSkills);
    final idx = updated.indexWhere((s) => s.toLowerCase() == lower);
    if (idx >= 0) {
      updated.removeAt(idx);
    } else {
      updated.add(skill);
    }
    widget.onChanged(updated);
  }

  void _addCustomSkills() {
    final entries = _customSkillCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    final updated = List<String>.from(widget.selectedSkills);
    for (final entry in entries) {
      final exists = updated.any(
        (existing) => existing.toLowerCase() == entry.toLowerCase(),
      );
      if (!exists) {
        updated.add(entry);
      }
    }
    _customSkillCtrl.clear();
    widget.onChanged(updated);
  }

  bool _isSelected(String skill) =>
      widget.selectedSkills.any((s) => s.toLowerCase() == skill.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoLabel('Skills & tags (${widget.selectedSkills.length} selected)'),
        const SizedBox(height: 8),
        if (widget.selectedSkills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in widget.selectedSkills)
                InputChip(
                  label: Text(
                    skill,
                    style: AppText.caption.copyWith(color: p.textPrimary),
                  ),
                  backgroundColor: p.accentSubtle,
                  deleteIconColor: p.accentText,
                  side: BorderSide(color: p.borderSubtle),
                  onDeleted: () => _toggleSkill(skill),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in widget.suggestedSkills)
              SelectChip(
                label: suggestion,
                selected: _isSelected(suggestion),
                onTap: () => _toggleSkill(suggestion),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Add custom skill(s)',
                hint: 'Comma-separated or single skill',
                controller: _customSkillCtrl,
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              'Add',
              size: ButtonSize.medium,
              variant: ButtonVariant.secondary,
              expand: false,
              onPressed: _addCustomSkills,
            ),
          ],
        ),
      ],
    );
  }
}

class _ModuleDraft {
  _ModuleDraft({
    required this.id,
    String title = '',
    String summary = '',
    String resourceUrl = '',
    int estimatedMinutes = 20,
  }) : titleCtrl = TextEditingController(text: title),
       summaryCtrl = TextEditingController(text: summary),
       urlCtrl = TextEditingController(text: resourceUrl),
       minsCtrl = TextEditingController(text: '$estimatedMinutes');

  factory _ModuleDraft.fromModule(
    CourseModule module, {
    required int fallbackIndex,
  }) => _ModuleDraft(
    id: module.id.isNotEmpty ? module.id : 'mod_$fallbackIndex',
    title: module.title,
    summary: module.summary,
    resourceUrl: module.resourceUrl,
    estimatedMinutes: module.estimatedMinutes,
  );

  final String id;
  final TextEditingController titleCtrl;
  final TextEditingController summaryCtrl;
  final TextEditingController urlCtrl;
  final TextEditingController minsCtrl;

  bool get isBlank =>
      titleCtrl.text.trim().isEmpty &&
      summaryCtrl.text.trim().isEmpty &&
      urlCtrl.text.trim().isEmpty;

  void dispose() {
    titleCtrl.dispose();
    summaryCtrl.dispose();
    urlCtrl.dispose();
    minsCtrl.dispose();
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.index,
    required this.total,
    required this.draft,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final int index;
  final int total;
  final _ModuleDraft draft;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      color: p.canvas,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusBadge('Module ${index + 1}', tone: Tone.info),
              const Spacer(),
              if (onMoveUp != null)
                IconButton(
                  tooltip: 'Move up',
                  visualDensity: VisualDensity.compact,
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                ),
              if (onMoveDown != null)
                IconButton(
                  tooltip: 'Move down',
                  visualDensity: VisualDensity.compact,
                  onPressed: onMoveDown,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                ),
              if (total > 1)
                IconButton(
                  tooltip: 'Remove module',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: p.dangerText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AppTextField(
            label: 'Module title',
            hint: 'e.g. Layouts & Responsive Navigation',
            controller: draft.titleCtrl,
          ),
          const SizedBox(height: 8),
          AppTextField(
            label: 'Summary / lesson notes (optional)',
            hint: 'What the student completes in this module',
            controller: draft.summaryCtrl,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  label: 'Resource URL (optional)',
                  hint: 'https://...',
                  controller: draft.urlCtrl,
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  label: 'Mins',
                  controller: draft.minsCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceDraft {
  _ResourceDraft({required this.id, String title = '', String url = ''})
    : titleCtrl = TextEditingController(text: title),
      urlCtrl = TextEditingController(text: url);

  final String id;
  final TextEditingController titleCtrl;
  final TextEditingController urlCtrl;

  void dispose() {
    titleCtrl.dispose();
    urlCtrl.dispose();
  }
}
