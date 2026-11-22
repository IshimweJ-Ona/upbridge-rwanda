import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/cloudinary_media_picker.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class ProjectEditorScreen extends ConsumerStatefulWidget {
  const ProjectEditorScreen({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<ProjectEditorScreen> createState() =>
      _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends ConsumerState<ProjectEditorScreen> {
  static const _skillSuggestions = [
    'Flutter',
    'Dart',
    'Firebase',
    'React',
    'HTML/CSS',
    'Python',
    'UI/UX',
    'SQL',
  ];

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _projectUrl = TextEditingController();
  final _repoUrl = TextEditingController();
  final _customSkill = TextEditingController();

  final Set<String> _skills = {};
  MediaAsset? _coverImage;
  MediaAsset? _attachment;
  bool _isPublic = true;
  bool _loadedExisting = false;
  bool _saving = false;
  String? _error;

  PortfolioProject? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    try {
      final project = await ref
          .read(projectRepositoryProvider)
          .getProject(widget.projectId!);
      if (!mounted || _loadedExisting) return;
      if (project == null) {
        setState(() {
          _loadedExisting = true;
          _error = 'Project could not be found.';
        });
        return;
      }
      setState(() {
        _loadedExisting = true;
        _existing = project;
        _title.text = project.title;
        _description.text = project.description;
        _projectUrl.text = project.projectUrl;
        _repoUrl.text = project.repoUrl;
        _skills
          ..clear()
          ..addAll(project.skills);
        _coverImage = project.images.firstOrNull;
        _attachment = project.attachments.firstOrNull;
        _isPublic = project.isPublic;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadedExisting = true;
        _error = errorMessage(error);
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _projectUrl.dispose();
    _repoUrl.dispose();
    _customSkill.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final uid = ref.read(appSessionProvider).asData?.value.uid;
    if (uid == null) return;

    final title = _title.text.trim();
    final desc = _description.text.trim();
    if (title.length < 2) {
      setState(() => _error = 'Enter a project title (at least 2 characters).');
      return;
    }
    if (desc.length < 10) {
      setState(() => _error = 'Enter a description (at least 10 characters).');
      return;
    }
    if (_skills.isEmpty) {
      setState(() => _error = 'Select or add at least one skill.');
      return;
    }
    final demoUrlErr = Validators.optionalUrl(_projectUrl.text);
    if (demoUrlErr != null) {
      setState(() => _error = 'Demo / project link: $demoUrlErr');
      return;
    }
    final repoUrlErr = Validators.optionalUrl(_repoUrl.text);
    if (repoUrlErr != null) {
      setState(() => _error = 'Repository link: $repoUrlErr');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final now = DateTime.now().toUtc();
      final images = _coverImage == null
          ? const <MediaAsset>[]
          : [_coverImage!];
      final attachments = _attachment == null
          ? const <MediaAsset>[]
          : [_attachment!];

      if (_existing != null) {
        await ref
            .read(projectRepositoryProvider)
            .updateProject(
              _existing!.copyWith(
                title: title,
                description: desc,
                skills: _skills.toList(growable: false),
                projectUrl: _projectUrl.text.trim(),
                repoUrl: _repoUrl.text.trim(),
                images: images,
                attachments: attachments,
                isPublic: _isPublic,
                updatedAt: now,
              ),
            );
        if (mounted) {
          showToast(context, 'Project updated');
          context.pop();
        }
      } else {
        final createdId = await ref
            .read(projectRepositoryProvider)
            .createProject(
              PortfolioProject(
                id: '',
                ownerUid: uid,
                title: title,
                description: desc,
                skills: _skills.toList(growable: false),
                projectUrl: _projectUrl.text.trim(),
                repoUrl: _repoUrl.text.trim(),
                images: images,
                attachments: attachments,
                isPublic: _isPublic,
                status: ProjectStatus.published,
                createdAt: now,
                updatedAt: now,
              ),
            );
        if (mounted) {
          showToast(context, 'Project saved to your portfolio');
          context.pushReplacement('/project/$createdId');
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(appSessionProvider).asData?.value.uid ?? '';
    final isLoadingExisting = widget.projectId != null && !_loadedExisting;
    if (isLoadingExisting) {
      return const DetailPage(
        title: 'Edit project',
        backFallback: '/profile',
        children: [SkeletonDetailPageLoader()],
      );
    }
    return DetailPage(
      title: widget.projectId == null ? 'Add project' : 'Edit project',
      backFallback: '/profile',
      footer: [
        AppButton(
          widget.projectId == null ? 'Publish project' : 'Save changes',
          loading: _saving,
          onPressed: _save,
        ),
      ],
      children: [
        if (_error != null) ...[
          NoticeCard(
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
            title: 'Check project details',
            body: _error!,
          ),
          const SizedBox(height: 12),
        ],
        AppTextField(
          label: 'Project title',
          hint: 'e.g. Kigali Bus Route Finder',
          controller: _title,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Description & impact',
          hint: 'What did you build, what problem does it solve, and what was your role?',
          controller: _description,
          minLines: 4,
          maxLines: 6,
        ),
        const SizedBox(height: 16),
        Text(
          'Skills & technologies',
          style: AppText.bodySStrong.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in {..._skillSuggestions, ..._skills})
              SelectChip(
                label: s,
                selected: _skills.contains(s),
                onTap: () => setState(() {
                  if (_skills.contains(s)) {
                    _skills.remove(s);
                  } else if (_skills.length < 15) {
                    _skills.add(s);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Add custom skill',
                hint: 'e.g. Node.js',
                controller: _customSkill,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: AppButton(
                'Add',
                size: ButtonSize.medium,
                variant: ButtonVariant.secondary,
                expand: false,
                onPressed: () {
                  final raw = _customSkill.text.trim();
                  if (raw.isNotEmpty && _skills.length < 15) {
                    setState(() {
                      _skills.add(raw);
                      _customSkill.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Live demo URL',
          trailingNote: 'Optional',
          hint: 'https://...',
          controller: _projectUrl,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Source code URL',
          trailingNote: 'Optional',
          hint: 'https://github.com/...',
          controller: _repoUrl,
          keyboardType: TextInputType.url,
        ),
        if (uid.isNotEmpty) ...[
          const SizedBox(height: 16),
          CloudinaryMediaPicker(
            ownerUid: uid,
            label: 'Project screenshot or cover image',
            category: 'project-images',
            imagesOnly: true,
            initialAsset: _coverImage,
            onAssetChanged: (asset) => setState(() => _coverImage = asset),
          ),
          const SizedBox(height: 12),
          CloudinaryMediaPicker(
            ownerUid: uid,
            label: 'Supporting diagram or badge image (optional)',
            category: 'project-files',
            imagesOnly: false,
            helperText: 'JPG, JPEG, PNG, or WebP image (max 10 MB).',
            initialAsset: _attachment,
            onAssetChanged: (asset) => setState(() => _attachment = asset),
          ),
        ],
        const SizedBox(height: 16),
        CheckRow(
          label: 'Show on my public portfolio & CV',
          value: _isPublic,
          onChanged: (v) => setState(() => _isPublic = v),
        ),
      ],
    );
  }
}
