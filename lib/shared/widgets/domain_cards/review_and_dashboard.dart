part of '../domain_cards.dart';

/// The highlighted "what to do next" card (H1, H2, MH1).
class NextStepCard extends StatelessWidget {
  const NextStepCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.icon = Icons.bolt_rounded,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inverse,
        borderRadius: Radii.rXl,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2613294B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandOrange.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.brandOrange),
                    const SizedBox(width: 6),
                    MonoLabel(eyebrow, color: AppColors.brandOrange),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppText.titleM.copyWith(color: AppColors.textInverse),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: AppText.bodyS.copyWith(color: const Color(0xD9FFFFFF)),
                ),
                const SizedBox(height: 16),
                AppButton(
                  action,
                  onPressed: onAction,
                  variant: ButtonVariant.onDark,
                  size: ButtonSize.medium,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pilot objective with a target marker (AD1).
class ObjectiveMeter extends StatelessWidget {
  const ObjectiveMeter({super.key, required this.objective});

  final Objective objective;

  @override
  Widget build(BuildContext context) {
    final o = objective;
    final color = o.closed
        ? AppColors.textMuted
        : (o.onTrack ? AppColors.successText : AppColors.accent);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(o.label, style: AppText.bodySStrong)),
              Text(
                o.valueLabel,
                style: AppText.dataMonoL.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 4,
                    child: ProgressLine(
                      o.value / (o.target >= 1 ? o.target : 1),
                      color: color,
                    ),
                  ),
                  if (o.target < 1)
                    Positioned(
                      left: (c.maxWidth * o.target - 1).clamp(
                        0.0,
                        c.maxWidth - 2,
                      ),
                      top: 0,
                      child: Container(
                        width: 2,
                        height: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(o.note, style: AppText.caption)),
              MonoLabel(o.targetLabel),
            ],
          ),
        ],
      ),
    );
  }
}

/// Success header used on confirmation screens (L5, M4, J6, P4, MR4, A8).
class SuccessBlock extends StatelessWidget {
  const SuccessBlock({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow,
    this.tone = Tone.success,
    this.icon,
  });

  final String title;
  final String body;
  final String? eyebrow;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon == null
              ? SuccessMark(size: 64, tone: tone)
              : _PoppedIcon(icon: icon!, tone: tone),
          const SizedBox(height: 20),
          if (eyebrow != null) ...[
            MonoLabel(eyebrow!),
            const SizedBox(height: 8),
          ],
          Text(title, style: AppText.titleL),
          const SizedBox(height: 8),
          Text(body, style: AppText.bodyM),
        ],
      ),
    );
  }
}

class _PoppedIcon extends StatelessWidget {
  const _PoppedIcon({required this.icon, required this.tone});
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Motion.emphasized,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: tone.background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 30, color: tone.foreground),
      ),
    );
  }
}

/// Big number + caption used in dashboards.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.onTap,
    this.tone = Tone.neutral,
  });

  final int value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.rLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            IconTile(icon!, tone: tone, size: 32),
            const SizedBox(height: 10),
          ],
          CountUp(
            value: value,
            style: AppText.dataMonoL.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption),
        ],
      ),
    );
    return onTap == null ? body : Pressable(onTap: onTap, child: body);
  }
}
