// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/features/mentor_workspace/domain/usecases/send_review.dart';
import 'package:upbridge/features/mentor_workspace/presentation/providers/mentor_providers.dart';

/// MR3 · Review against the rubric: Met / Partly / Not yet + a note each.
class ReviewRubricScreen extends ConsumerStatefulWidget {
  const ReviewRubricScreen({super.key, required this.submissionId});

  final String submissionId;

  @override
  ConsumerState<ReviewRubricScreen> createState() => _ReviewRubricScreenState();
}

class _ReviewRubricScreenState extends ConsumerState<ReviewRubricScreen> {
  static const _verdicts = [Verdict.met, Verdict.partly, Verdict.notYet];
  final Map<int, int> _choice = {};
  final Map<int, TextEditingController> _notes = {};
  final _summary = TextEditingController();
  bool _sending = false;

  TextEditingController _noteFor(int i) => _notes.putIfAbsent(i, TextEditingController.new);

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    _summary.dispose();
    super.dispose();
  }

  void _allMet(int count) {
    HapticFeedback.selectionClick();
    setState(() {
      for (var i = 0; i < count; i++) {
        _choice[i] = 0;
      }
    });
  }

  ReviewDraft _draft(Submission s, LearningTask task) => ReviewDraft(
    submissionId: s.id,
    criteria: [for (final c in task.criteria) c.title],
    verdicts: {for (final e in _choice.entries) e.key: _verdicts[e.value]},
    notes: {for (final i in _choice.keys) i: _noteFor(i).text},
    summary: _summary.text,
  );

  Future<void> _send(ReviewDraft draft) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final approved = await ref.read(sendReviewProvider)(draft);
      if (mounted) context.pushReplacement('/m-review-sent/${draft.submissionId}?approved=$approved');
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      showToast(context, mentorshipErrorText(error), icon: Icons.error_outline_rounded, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final s = data.submission(widget.submissionId);
    if (s == null) return const SizedBox.shrink();
    final task = data.task(s.taskId);
    final n = task.criteria.length;
    final first = s.youthName.split(' ').first;
    final draft = _draft(s, task);
    final chosen = draft.markedCount;
    final allChosen = draft.allMarked;
    final approve = draft.approves;
    final missingNotes = draft.missingNotes;
    final summaryOk = draft.summaryOk;
    final ready = draft.validate() == null;

    final hint = !allChosen
        ? '$chosen of $n criteria marked'
        : missingNotes > 0
            ? 'Add a note to $missingNotes ${missingNotes == 1 ? 'criterion' : 'criteria'} not met'
            : (!summaryOk ? 'Add an overall note to $first' : (approve ? 'All criteria met — this will approve the task' : 'This will ask $first for changes'));

    return DetailPage(
      title: 'Review · $first',
      backFallback: '/m-submission/${s.id}',
      footerNote: Row(
        children: [
          Expanded(child: ProgressLine(n == 0 ? 0 : chosen / n, color: approve ? AppColors.successText : AppColors.accent, height: 4)),
          const SizedBox(width: 10),
          Flexible(
            flex: 3,
            child: AnimatedSwitcher(
              duration: Motion.fast,
              child: Text(hint, key: ValueKey(hint), style: AppText.caption, textAlign: TextAlign.right),
            ),
          ),
        ],
      ),
      footer: [
        AppButton(
          approve || !allChosen ? 'Approve and send review' : 'Send review: request changes',
          variant: approve || !allChosen ? ButtonVariant.primary : ButtonVariant.secondary,
          icon: Icons.send_rounded,
          loading: _sending,
          onPressed: ready && !_sending ? () => _send(draft) : null,
        ),
      ],
      children: [
        PageHeading(
          eyebrow: 'Task ${s.taskNumber} · attempt ${s.attempt}',
          title: s.taskTitle,
          body: 'Mark each criterion and add a short, specific note. $first sees exactly what you write.',
          bottom: 10,
        ),
        Align(alignment: Alignment.centerLeft, child: TextLink('Mark all as met', onTap: () => _allMet(n))),
        const SizedBox(height: 8),
        for (var i = 0; i < n; i++) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('0${i + 1}', style: AppText.dataMonoStrong.copyWith(color: AppColors.accentText)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.criteria[i].title, style: AppText.bodyMStrong),
                          const SizedBox(height: 2),
                          Text(task.criteria[i].detail, style: AppText.bodyS),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                VerdictSelector(
                  labels: const ['Met', 'Partly', 'Not yet'],
                  tones: const [AppColors.successText, AppColors.warningText, AppColors.dangerText],
                  value: _choice[i],
                  onChanged: (v) => setState(() => _choice[i] = v),
                ),
                AnimatedSize(
                  duration: Motion.base,
                  curve: Motion.curve,
                  alignment: Alignment.topCenter,
                  child: _choice[i] == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: AppTextField(
                            label: _choice[i] == 0 ? 'Note (optional)' : 'What should $first change?',
                            controller: _noteFor(i),
                            maxLines: 3,
                            minLines: 2,
                            hint: _choice[i] == 0 ? 'What should they keep doing?' : 'Be specific: the element, the screen size, the fix.',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        AppTextField(
          label: 'Overall note to $first',
          controller: _summary,
          maxLines: 4,
          minLines: 3,
          hint: approve ? 'e.g. The footer now wraps cleanly at 360 px. Ready for your portfolio.' : 'Start with what works, then the one change that matters most.',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
