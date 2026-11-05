// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// L3 · Submit (or resubmit) work, and L4 · submit with errors.
class SubmitWorkScreen extends ConsumerStatefulWidget {
  const SubmitWorkScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends ConsumerState<SubmitWorkScreen> {
  late final TextEditingController _live;
  late final TextEditingController _repo;
  late final TextEditingController _note;
  bool _checked = false;
  bool _tried = false;
  bool _sending = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    final data = ref.read(appStoreProvider);
    final isJean = data.user?.id == 'jean';
    final resub = data.task(widget.taskId).status == TaskStatus.changesRequested;
    _live = TextEditingController(text: isJean ? SampleData.liveUrl : '');
    _repo = TextEditingController(text: isJean ? SampleData.repoUrl : '');
    _note = TextEditingController(text: isJean && resub ? SampleData.resubmitNote : '');
  }

  @override
  void dispose() {
    _live.dispose();
    _repo.dispose();
    _note.dispose();
    super.dispose();
  }

  static bool _isUrl(String v) => RegExp(r'^https://[^\s/$.?#].[^\s]*$').hasMatch(v.trim());

  String? get _liveError => !_tried
      ? null
      : _live.text.trim().isEmpty
          ? 'Add the link to your live page.'
          : (_isUrl(_live.text) ? null : 'Use a full link that starts with https://');
  String? get _repoError => !_tried
      ? null
      : _repo.text.trim().isEmpty
          ? 'Add the link to your GitHub repository.'
          : (_isUrl(_repo.text) ? null : 'Use a full link that starts with https://');
  String? get _noteError => _tried && _note.text.trim().length < 20 ? 'Write at least one sentence so your mentor knows what to look for.' : null;
  String? get _checkError => _tried && !_checked ? 'Please check your page on a phone-sized screen first.' : null;

  int get _errorCount => [_liveError, _repoError, _noteError, _checkError].where((e) => e != null).length;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (_errorCount > 0) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    ref.read(appStoreProvider.notifier).submitWork(widget.taskId, live: _live.text.trim(), repo: _repo.text.trim(), note: _note.text.trim());
    context.pushReplacement('/task-submitted/${widget.taskId}');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final task = data.task(widget.taskId);
    final resub = task.status == TaskStatus.changesRequested;
    final review = data.latestReview(widget.taskId);
    final mentor = review?.mentorName.split(' ').first ?? 'your mentor';
    CriterionResult? ask;
    for (final r in review?.results ?? const <CriterionResult>[]) {
      if (r.verdict != Verdict.met) ask = r;
    }

    return DetailPage(
      title: resub ? 'Resubmit Task ${task.number}' : 'Submit Task ${task.number}',
      backFallback: '/task/${widget.taskId}',
      footer: [AppButton('Submit for review', icon: Icons.send_rounded, loading: _sending, onPressed: _submit)],
      children: [
        PageHeading(
          eyebrow: 'Task ${task.number} · attempt ${resub ? 2 : 1}',
          title: task.title,
          body: resub ? 'Update your live page, then tell $mentor what you changed.' : 'Share your live page and code. A mentor reviews it within 48 hours.',
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: _tried && _errorCount > 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoticeCard(
                    tone: Tone.danger,
                    icon: Icons.error_outline_rounded,
                    title: 'Fix $_errorCount ${_errorCount == 1 ? 'thing' : 'things'} before submitting',
                    body: 'Your work is saved on this phone, so nothing is lost.',
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (resub && ask != null) ...[
          NoticeCard(tone: Tone.warning, icon: Icons.edit_note_rounded, title: 'What $mentor asked for', body: ask.note),
          const SizedBox(height: 20),
        ],
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Live page link',
                controller: _live,
                hint: 'https://yourname.github.io',
                helper: 'Your GitHub Pages address.',
                keyboardType: TextInputType.url,
                error: _liveError,
                suffixIcon: Icons.public_rounded,
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Repository link',
                controller: _repo,
                hint: 'https://github.com/yourname/homepage',
                keyboardType: TextInputType.url,
                error: _repoError,
                suffixIcon: Icons.code_rounded,
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: resub ? 'What did you change?' : 'What did you build or learn?',
                controller: _note,
                maxLines: 5,
                minLines: 4,
                trailingNote: '${_note.text.length}/400',
                inputFormatters: [LengthLimitingTextInputFormatter(400)],
                error: _noteError,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              CheckRow(
                label: 'I checked my page on a phone-sized screen (360 px wide).',
                value: _checked,
                error: _checkError,
                onChanged: (v) => setState(() => _checked = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _refresh() {
    if (_tried) setState(() {});
  }
}
