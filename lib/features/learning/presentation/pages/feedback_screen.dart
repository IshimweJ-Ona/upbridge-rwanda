// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// L6 · Feedback with a change requested, and L7 · approved.
class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final task = data.task(taskId);
    final reviews = data.reviewsFor(taskId);

    if (reviews.isEmpty) {
      return DetailPage(
        title: 'Mentor feedback',
        backFallback: '/learn',
        children: const [
          SizedBox(height: 24),
          EmptyState(icon: Icons.rate_review_outlined, title: 'No review yet', body: 'Your mentor’s feedback will appear here once your work is reviewed.'),
        ],
      );
    }

    final review = reviews.first;
    final earlier = reviews.skip(1).toList();
    final project = data.projectForTask(taskId);
    final changes = review.results.length - review.metCount;
    final first = review.mentorName.split(' ').first;

    return DetailPage(
      title: 'Mentor feedback',
      backFallback: '/task/$taskId',
      footer: review.approved
          ? [
              AppButton(
                project == null ? 'Add to portfolio' : 'View in portfolio',
                icon: project == null ? Icons.add_rounded : Icons.arrow_forward_rounded,
                onPressed: () {
                  final id = ref.read(appStoreProvider.notifier).addTaskToPortfolio(taskId);
                  if (project == null) showToast(context, 'Added to your portfolio');
                  context.push('/project/$id');
                },
              ),
              AppButton('Back to Learn', variant: ButtonVariant.secondary, onPressed: () => context.go('/learn')),
            ]
          : [
              AppButton('Revise and resubmit', icon: Icons.upload_rounded, onPressed: () => context.push('/task-submit/$taskId')),
              AppButton('Ask $first a question', variant: ButtonVariant.secondary, onPressed: () => context.push('/mentor-request/alice')),
            ],
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            AppAvatar(initialsOf(review.mentorName), tone: Tone.accent, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.mentorName, style: AppText.bodyMStrong),
                  const SizedBox(height: 2),
                  MonoLabel(review.when),
                ],
              ),
            ),
            if (review.approved) const SuccessMark(size: 40),
          ],
        ),
        const SizedBox(height: 20),
        MonoLabel('Task ${task.number} · ${task.title}', maxLines: 2),
        const SizedBox(height: 6),
        Text(
          review.approved ? 'Approved · ${review.metCount} of ${review.results.length} criteria met' : '$changes change requested · ${review.metCount} of ${review.results.length} met',
          style: AppText.titleL,
        ),
        const SizedBox(height: 14),
        _CriteriaMeter(results: review.results),
        const SizedBox(height: 20),
        SurfaceCard(
          accentEdge: review.approved ? AppColors.successText : AppColors.warningText,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded, color: AppColors.textMuted, size: 22),
              const SizedBox(height: 4),
              Text(review.summary, style: AppText.bodyM.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('— $first', style: AppText.bodySStrong.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SectionLabel('Criteria'),
        for (final r in review.results) ...[CriterionNote(result: r), const SizedBox(height: 10)],
        if (earlier.isNotEmpty) ...[
          const SectionLabel('Earlier review', top: 14),
          for (final e in earlier) _EarlierReview(review: e),
        ],
      ],
    );
  }
}

class _CriteriaMeter extends StatelessWidget {
  const _CriteriaMeter({required this.results});

  final List<CriterionResult> results;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < results.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 500 + 140 * i),
              curve: Motion.curve,
              builder: (context, v, _) => Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Color.lerp(AppColors.sunken, results[i].verdict.tone.foreground, v),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EarlierReview extends StatefulWidget {
  const _EarlierReview({required this.review});
  final Review review;

  @override
  State<_EarlierReview> createState() => _EarlierReviewState();
}

class _EarlierReviewState extends State<_EarlierReview> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return SurfaceCard(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(r.approved ? 'Approved' : 'Changes requested', tone: r.approved ? Tone.success : Tone.warning),
              const SizedBox(width: 8),
              Expanded(child: MonoLabel(r.when)),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: Motion.base,
                child: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
              ),
            ],
          ),
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.summary, style: AppText.bodyS),
                        const SizedBox(height: 10),
                        for (final c in r.results)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(c.verdict.icon, size: 16, color: c.verdict.tone.foreground),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${c.criterion} — ${c.verdict.label}', style: AppText.bodyS)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
