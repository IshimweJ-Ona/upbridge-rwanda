// Owner: Student 4 · Opportunities & applications
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/features/applications/presentation/state/apply_draft.dart';

/// J3 · Apply: choose evidence, and J4 · the same with errors.
class ApplyScreen extends ConsumerStatefulWidget {
  const ApplyScreen({super.key, required this.oppId});

  final String oppId;

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  static const _maxProjects = 3;
  late final List<String> _picked;
  late final TextEditingController _note;
  late bool _consent;
  bool _tried = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(applyDraftsProvider)[widget.oppId];
    final data = ref.read(appStoreProvider);
    final home = data.project('p-homepage');
    _picked = draft?.projectIds.toList() ?? [if (home != null) home.id];
    _note = TextEditingController(text: draft?.note ?? '');
    _consent = draft?.consent ?? false;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String? get _evidenceError => _tried && _picked.isEmpty ? 'Choose at least one project.' : null;
  String? get _noteError => _tried && _note.text.trim().length < 30 ? 'Write two or three sentences — employers read this first.' : null;
  String? get _consentError => _tried && !_consent ? 'The employer needs a way to reach you for an interview.' : null;
  int get _errors => [_evidenceError, _noteError, _consentError].where((e) => e != null).length;

  void _toggle(String id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else if (_picked.length < _maxProjects) {
        _picked.add(id);
      } else {
        HapticFeedback.heavyImpact();
        showToast(context, 'You can attach up to 3 projects', icon: Icons.info_outline_rounded, tone: Tone.info);
      }
    });
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (_errors > 0) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    ref.read(applyDraftsProvider.notifier).save(widget.oppId, ApplyDraft(projectIds: List.of(_picked), note: _note.text.trim(), consent: _consent));
    context.push('/apply-review/${widget.oppId}');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final o = data.opportunity(widget.oppId);
    if (o == null) return const SizedBox.shrink();
    final projects = [...data.projects.where((p) => p.verified), ...data.projects.where((p) => !p.verified)];
    final question = o.requirements.where((r) => r.evidence.startsWith('Confirm')).toList();

    return DetailPage(
      title: 'Apply · ${o.org}',
      backFallback: '/opportunity/${o.id}',
      footer: [AppButton('Continue to review', icon: Icons.arrow_forward_rounded, onPressed: _continue)],
      children: [
        const StepDots(count: 2, index: 0),
        const SizedBox(height: 18),
        PageHeading(
          eyebrow: 'Step 1 of 2 · ${o.title}',
          title: 'Choose your evidence',
          body: 'Attach up to 3 projects. Mentor-approved work counts most with employers.',
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: _tried && _errors > 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoticeCard(
                    tone: Tone.danger,
                    icon: Icons.error_outline_rounded,
                    title: 'Fix $_errors ${_errors == 1 ? 'thing' : 'things'} to continue',
                    body: 'Nothing is sent until you review and tap “Send application”.',
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: MonoLabel('${_picked.length} of $_maxProjects attached', color: _evidenceError != null ? AppColors.dangerText : AppColors.textMuted)),
                  if (_evidenceError != null) Text(_evidenceError!, style: AppText.caption.copyWith(color: AppColors.dangerText)),
                ],
              ),
              const SizedBox(height: 10),
              for (final p in projects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CheckCard(
                    selected: _picked.contains(p.id),
                    error: _evidenceError != null,
                    onTap: () => _toggle(p.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(p.title, style: AppText.bodyMStrong)),
                            if (p.verified)
                              const StatusBadge('Mentor-approved', tone: Tone.success, icon: Icons.verified_rounded)
                            else
                              const StatusBadge('Self-added'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        MonoLabel(p.verified ? 'Approved by ${p.approvedBy} · ${p.approvedOn}' : 'Added ${p.addedOn}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Note to ${o.org}',
                controller: _note,
                maxLines: 6,
                minLines: 4,
                trailingNote: '${_note.text.length}/600',
                inputFormatters: [LengthLimitingTextInputFormatter(600)],
                hint: 'Why this role, and what you’d bring. Answer any question in the listing.',
                error: _noteError,
                onChanged: (_) => setState(() {}),
              ),
              if (question.isNotEmpty) ...[
                const SizedBox(height: 10),
                NoticeCard(tone: Tone.info, icon: Icons.help_outline_rounded, title: '${o.org} asks', body: '${question.first.text}?'),
              ],
              const SizedBox(height: 18),
              CheckRow(
                label: 'Share my phone number with ${o.org} if they want to interview me.',
                value: _consent,
                error: _consentError,
                onChanged: (v) => setState(() => _consent = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
