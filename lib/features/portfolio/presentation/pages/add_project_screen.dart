// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// P3 · Add a project you did outside UpBridge.
class AddProjectScreen extends ConsumerStatefulWidget {
  const AddProjectScreen({super.key});

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  static const _skillOptions = ['HTML', 'CSS', 'JavaScript', 'Figma', 'Excel', 'Photography', 'Writing', 'Customer service'];
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _link = TextEditingController();
  final Set<String> _skills = {};
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

  String? get _titleError => _tried && _title.text.trim().length < 3 ? 'Give your project a name.' : null;
  String? get _summaryError => _tried && _summary.text.trim().length < 20 ? 'Describe what you did in a sentence or two.' : null;
  String? get _linkError {
    final v = _link.text.trim();
    if (!_tried || v.isEmpty) return null;
    return v.startsWith('https://') ? null : 'Use a full link that starts with https://';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (_titleError != null || _summaryError != null || _linkError != null) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final id = ref.read(appStoreProvider.notifier).addProject(title: _title.text, summary: _summary.text, link: _link.text, skills: _skills.toList());
    context.pushReplacement('/project-saved/$id');
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Add a project',
      closeIcon: true,
      backFallback: '/profile/portfolio',
      footer: [AppButton('Save project', loading: _saving, onPressed: _save)],
      children: [
        const PageHeading(
          title: 'Add a project',
          body: 'Something you made outside UpBridge — for a client, a class or yourself.',
        ),
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Project name',
                controller: _title,
                hint: 'e.g. Menu page for a café in Remera',
                error: _titleError,
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'What did you do?',
                controller: _summary,
                maxLines: 5,
                minLines: 3,
                trailingNote: '${_summary.text.length}/300',
                inputFormatters: [LengthLimitingTextInputFormatter(300)],
                hint: 'Who was it for, what you built and what changed because of it.',
                error: _summaryError,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Link',
                trailingNote: 'Optional',
                controller: _link,
                hint: 'https://',
                keyboardType: TextInputType.url,
                error: _linkError,
                onChanged: (_) => _refresh(),
              ),
            ],
          ),
        ),
        const SectionLabel('Skills used'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _skillOptions)
              SelectChip(
                label: s,
                selected: _skills.contains(s),
                onTap: () => setState(() => _skills.contains(s) ? _skills.remove(s) : _skills.add(s)),
              ),
          ],
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

  void _refresh() {
    if (_tried) setState(() {});
  }
}
