part of '../domain_cards.dart';

/// One criterion with the mentor's verdict and note (L6, L7, MR2).
class CriterionNote extends StatelessWidget {
  const CriterionNote({super.key, required this.result});

  final CriterionResult result;

  @override
  Widget build(BuildContext context) {
    final v = result.verdict;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.rLg,
        border: Border.all(
          color: v == Verdict.met
              ? AppColors.borderSubtle
              : v.tone.foreground.withValues(alpha: 0.45),
          width: v == Verdict.met ? 1 : 1.4,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(v.icon, size: 20, color: v.tone.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(result.criterion, style: AppText.bodyMStrong),
                    ),
                    StatusBadge(v.label, tone: v.tone),
                  ],
                ),
                const SizedBox(height: 6),
                Text(result.note, style: AppText.bodyS),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical timeline; the current step's dot pulses (J6, J8, L5).
class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 2,
                        height: 4,
                        color: i == 0
                            ? Colors.transparent
                            : _lineColor(events[i - 1]),
                      ),
                      _Dot(event: events[i]),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: i == events.length - 1
                              ? Colors.transparent
                              : _lineColor(events[i]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == events.length - 1 ? 0 : 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          events[i].title,
                          style: AppText.bodyMStrong.copyWith(
                            color: events[i].done || events[i].current
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        MonoLabel(
                          events[i].date,
                          color: events[i].current
                              ? AppColors.accentText
                              : AppColors.textMuted,
                        ),
                        if (events[i].detail != null) ...[
                          const SizedBox(height: 4),
                          Text(events[i].detail!, style: AppText.bodyS),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Color _lineColor(TimelineEvent e) => e.done && !e.current
      ? AppColors.successText.withValues(alpha: 0.55)
      : AppColors.borderSubtle;
}

class _Dot extends StatefulWidget {
  const _Dot({required this.event});
  final TimelineEvent event;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.event.current) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    if (e.current) {
      return SizedBox(
        width: 22,
        height: 22,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 10 + 12 * _c.value,
                height: 10 + 12 * _c.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(
                    alpha: 0.28 * (1 - _c.value),
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: e.done
            ? Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successText,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: AppColors.onPrimary,
                ),
              )
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.borderStrong, width: 1.5),
                ),
              ),
      ),
    );
  }
}
