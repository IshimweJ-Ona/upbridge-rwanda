// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/portfolio/domain/usecases/add_project.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/shared.dart';

/// P3 · Add a project to the portfolio.
class AddProjectScreen extends ConsumerStatefulWidget {
  const AddProjectScreen({super.key});

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  static const _suggestions = ['HTML', 'CSS', 'JavaScript', 'React', 'Tailwind', 'Figma', 'Flutter'];

  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _link = TextEditingController();
  List<String> _skills = const [];
  bool _tried = false;
  bool _saving = false;
  int _shake = 0;

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _link.dispose();
    super.dispose();
  }

  ProjectDraft get _draft => ProjectDraft(title: _title.text, summary: _summary.text, skills: _skills, link: _link.text);

  ProjectDraftErrors get _errors => _tried ? validateProjectDraft(_draft) : const ProjectDraftErrors();

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    // Let the tag field commit any half-typed tag when it loses focus.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() => _tried = true);
    if (!validateProjectDraft(_draft).isValid) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final id = ref.read(appStoreProvider.notifier).addProject(
          title: _title.text,
          summary: _summary.text,
          link: _link.text,
          skills: _skills,
        );
    context.pushReplacement('/project-saved/$id');
  }

  void _refresh() {
    if (_tried) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final errors = _errors;
    return DetailPage(
      title: 'Add a project',
      backFallback: '/profile/portfolio',
      footer: [AppButton('Save project', loading: _saving, onPressed: _save)],
      children: [
        Text('Showcase your proof of skill to mentors and partners.', style: AppText.bodyS),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: !errors.isValid
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoticeCard(
                    tone: Tone.danger,
                    icon: Icons.error_outline_rounded,
                    title: 'Fix ${errors.count} ${errors.count == 1 ? 'thing' : 'things'} before saving',
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Project title',
                controller: _title,
                hint: 'e.g. E-commerce website',
                error: errors.title,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(ProjectRules.titleMax)],
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                controller: _summary,
                maxLines: 5,
                minLines: 3,
                hint: 'Describe what you built and what technologies you used.',
                trailingNote: '${_summary.text.length}/${ProjectRules.summaryMax}',
                inputFormatters: [LengthLimitingTextInputFormatter(ProjectRules.summaryMax)],
                error: errors.summary,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _TagInput(
                label: 'Technologies used',
                tags: _skills,
                error: errors.skills,
                onChanged: (tags) {
                  setState(() => _skills = tags);
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _suggestions.where((s) => !_skills.any((t) => t.toLowerCase() == s.toLowerCase())))
                    SelectChip(
                      label: s,
                      selected: false,
                      showCheck: false,
                      icon: Icons.add_rounded,
                      onTap: () => setState(() => _skills = addSkillTag(_skills, s)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Project link',
                trailingNote: 'Optional',
                controller: _link,
                hint: 'https://github.com/username/project',
                keyboardType: TextInputType.url,
                error: errors.link,
                onChanged: (_) => _refresh(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const NoticeCard(
          icon: Icons.verified_outlined,
          title: 'Self-added projects are marked as such',
          body: 'Work from approved tasks shows a mentor’s review, which employers trust more.',
        ),
      ],
    );
  }
}

/// Field that collects short tags: type and press done (or a comma) to add, tap × to remove.
class _TagInput extends StatefulWidget {
  const _TagInput({required this.label, required this.tags, required this.onChanged, this.error});

  final String label;
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String? error;

  @override
  State<_TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<_TagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) return;
      if (!_focus.hasFocus) _commit();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final next = addSkillTag(widget.tags, _controller.text);
    _controller.clear();
    if (!identical(next, widget.tags)) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final full = widget.tags.length >= ProjectRules.maxSkills;
    final borderColor = hasError ? AppColors.dangerText : (_focus.hasFocus ? AppColors.focus : AppColors.borderStrong);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: AppText.bodySStrong)),
            Text('${widget.tags.length}/${ProjectRules.maxSkills}', style: AppText.caption),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: AnimatedContainer(
            duration: Motion.fast,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: Radii.rMd,
              border: Border.all(color: borderColor, width: (_focus.hasFocus || hasError) ? 1.6 : 1),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final t in widget.tags)
                  InputChip(
                    label: Text(t, style: AppText.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    backgroundColor: AppColors.sunken,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    deleteButtonTooltipMessage: 'Remove $t',
                    onDeleted: () => widget.onChanged([...widget.tags]..remove(t)),
                  ),
                if (!full)
                  SizedBox(
                    width: 140,
                    child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [LengthLimitingTextInputFormatter(ProjectRules.skillMax + 1)],
                        style: AppText.bodyS.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Add tag…',
                          hintStyle: AppText.bodyS.copyWith(color: AppColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        ),
                        onChanged: (v) {
                          if (v.endsWith(',')) _commit();
                        },
                        onSubmitted: (_) {
                          _commit();
                          _focus.requestFocus();
                        },
                      ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: hasError
              ? Text(widget.error!, style: AppText.caption.copyWith(color: AppColors.dangerText))
              : Text(full ? 'You’ve added the maximum of ${ProjectRules.maxSkills}.' : 'Press done or type a comma to add each one.', style: AppText.caption),
        ),
      ],
    );
  }
}
