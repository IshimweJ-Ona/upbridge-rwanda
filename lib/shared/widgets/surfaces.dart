import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/animations/effects.dart';
import 'package:upbridge/shared/animations/pressable.dart';
import 'package:upbridge/shared/animations/success_mark.dart';
import 'package:upbridge/shared/widgets/buttons.dart';

class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key, this.color, this.maxLines});

  final String text;
  final Color? color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      text.toUpperCase(),
      style: AppText.labelMono.copyWith(color: color ?? p.textMuted),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.top = 20,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 8),
      child: Row(
        children: [
          Expanded(child: MonoLabel(title)),
          if (action != null)
            TextLink(action!, onTap: onAction, compact: true),
        ],
      ),
    );
  }
}

class ListGroup extends StatelessWidget {
  const ListGroup({
    super.key,
    required this.children,
    this.dividers = true,
    this.color,
  });

  final List<Widget> children;
  final bool dividers;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && dividers) {
        items.add(Divider(height: 1, thickness: 1, color: p.borderSubtle));
      }
      items.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: Radii.rLg,
        border: Border.all(color: p.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: Radii.rLg,
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: items),
        ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.accentEdge,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentEdge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: Radii.rLg,
        border: Border.all(color: p.borderSubtle),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x08123B75),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: Radii.rLg,
        child: accentEdge == null
            ? Padding(padding: padding, child: child)
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 3.5, color: accentEdge),
                    Expanded(
                      child: Padding(padding: padding, child: child),
                    ),
                  ],
                ),
              ),
      ),
    );
    return onTap == null
        ? card
        : Pressable(onTap: onTap, scale: 0.985, child: card);
  }
}

class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.tone = Tone.neutral,
    this.size = 36,
  });

  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.backgroundFor(context),
        borderRadius: Radii.rMd,
      ),
      child: Icon(
        icon,
        size: size * 0.52,
        color: tone == Tone.neutral
            ? p.textPrimary
            : tone.foregroundFor(context),
      ),
    );
  }
}

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron,
    this.titleStyle,
    this.metaColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? chevron;
  final TextStyle? titleStyle;
  final Color? metaColor;
  final EdgeInsetsGeometry padding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final showChevron = chevron ?? onTap != null;
    return InkWell(
      onTap: onTap,
      splashColor: p.sunken,
      highlightColor: p.sunken.withValues(alpha: 0.5),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          titleStyle ??
                          (dense
                              ? AppText.bodySStrong.copyWith(
                                  color: p.textPrimary,
                                )
                              : AppText.bodyMStrong.copyWith(
                                  color: p.textPrimary,
                                )),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppText.bodyS.copyWith(color: p.textSecondary),
                      ),
                    ],
                    if (meta != null) ...[
                      const SizedBox(height: 4),
                      MonoLabel(meta!, color: metaColor ?? p.textMuted),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              if (showChevron) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 22, color: p.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    super.key,
    this.tone = Tone.neutral,
    this.icon,
  });

  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = tone.foregroundFor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.backgroundFor(context),
        borderRadius: Radii.rSm,
        border: Border.all(
          color: fg.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar(
    this.initials, {
    super.key,
    this.tone = Tone.info,
    this.size = 40,
    this.imageUrl,
  });

  final String initials;
  final Tone tone;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tone.backgroundFor(context),
      shape: BoxShape.circle,
    ),
    child: ClipOval(
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  _InitialsAvatar(initials: initials, tone: tone, size: size),
              errorWidget: (_, _, _) =>
                  _InitialsAvatar(initials: initials, tone: tone, size: size),
            )
          : _InitialsAvatar(initials: initials, tone: tone, size: size),
    ),
  );
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.initials,
    required this.tone,
    required this.size,
  });

  final String initials;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          initials,
          style: AppText.bodySStrong.copyWith(
            color: tone == Tone.neutral
                ? p.textPrimary
                : tone.foregroundFor(context),
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine(this.value, {super.key, this.color, this.height = 6});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: AnimatedFraction(
          value: value,
          builder: (context, v) => Stack(
            children: [
              Container(color: p.sunken),
              FractionallySizedBox(
                widthFactor: v,
                child: Container(color: color ?? p.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatItem {
  const StatItem(this.value, this.label, {this.countTo});
  final String value;
  final String label;
  final int? countTo;
}

class StatStrip extends StatelessWidget {
  const StatStrip(this.items, {super.key});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: p.borderSubtle)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                VerticalDivider(width: 24, thickness: 1, color: p.borderSubtle),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    items[i].countTo == null
                        ? Text(
                            items[i].value,
                            style: AppText.dataMonoL.copyWith(
                              color: p.textPrimary,
                            ),
                          )
                        : CountUp(
                            value: items[i].countTo!,
                            style: AppText.dataMonoL.copyWith(
                              color: p.textPrimary,
                            ),
                          ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
                      style: AppText.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.title,
    this.body,
    this.tone = Tone.neutral,
    this.icon,
  });

  final String title;
  final String? body;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = tone == Tone.neutral
        ? p.textSecondary
        : tone.foregroundFor(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.backgroundFor(context),
        borderRadius: Radii.rMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline_rounded, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.bodySStrong.copyWith(
                    color: tone == Tone.neutral ? p.textPrimary : fg,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body!,
                    style: AppText.bodyS.copyWith(color: p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KeyValueTable extends StatelessWidget {
  const KeyValueTable(
    this.rows, {
    super.key,
    this.monoValues = false,
    this.keyWidth = 96,
  });

  final List<(String, String)> rows;
  final bool monoValues;
  final double keyWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListGroup(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: keyWidth,
                  child: Text(
                    r.$1,
                    style: AppText.bodyS.copyWith(color: p.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.$2,
                    style:
                        (monoValues
                                ? AppText.dataMonoStrong
                                : AppText.bodySStrong)
                            .copyWith(color: p.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class TagWrap extends StatelessWidget {
  const TagWrap(this.tags, {super.key, this.tone = Tone.neutral});

  final List<String> tags;
  final Tone tone;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [for (final t in tags) StatusBadge(t, tone: tone)],
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: p.canvas,
        borderRadius: Radii.rLg,
        border: Border.all(color: p.borderStrong.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: p.textMuted),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppText.bodyMStrong.copyWith(color: p.textPrimary),
            textAlign: TextAlign.center,
          ),
          if (body != null) ...[
            const SizedBox(height: 4),
            Text(
              body!,
              style: AppText.bodyS.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 14),
            AppButton(
              action!,
              onPressed: onAction,
              variant: ButtonVariant.secondary,
              size: ButtonSize.medium,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Highlighted primary next-step card shown on Youth home.
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
        color: AppColors.navy,
        borderRadius: Radii.rLg,
        border: Border.all(color: const Color(0xFF1D4D91)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: Radii.rSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: const Color(0xFF93C5FD)),
                const SizedBox(width: 6),
                MonoLabel(eyebrow, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppText.titleM.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyS.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            action,
            onPressed: onAction,
            variant: ButtonVariant.onDark,
            size: ButtonSize.medium,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}

/// Confirmation header block used on standalone action confirmation screens.
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
    final p = context.palette;
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
          Text(title, style: AppText.titleL.copyWith(color: p.textPrimary)),
          const SizedBox(height: 8),
          Text(body, style: AppText.bodyM.copyWith(color: p.textSecondary)),
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
      duration: Motion.durationFor(context, const Duration(milliseconds: 300)),
      curve: Motion.emphasized,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: tone.backgroundFor(context),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 30, color: tone.foregroundFor(context)),
      ),
    );
  }
}

class MetricTileData {
  const MetricTileData({
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.tone = Tone.info,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final Tone tone;
  final VoidCallback? onTap;
}

/// Compact KPI metric tile using restrained solid surfaces and clean icon pills.
class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.data});

  final MetricTileData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      onTap: data.onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconTile(data.icon, tone: data.tone, size: 30),
              const Spacer(),
              if (data.onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: p.textMuted,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: AppText.display.copyWith(
                  fontSize: 22,
                  height: 1.15,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodySStrong.copyWith(color: p.textPrimary),
              ),
              if (data.caption != null && data.caption!.isNotEmpty)
                Text(
                  data.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: p.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Overflow-safe responsive grid of compact KPI [MetricCard]s.
class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key, required this.items, this.spacing = 10});

  final List<MetricTileData> items;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 580
            ? 3
            : (constraints.maxWidth >= 280 ? 2 : 1);
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += cols) {
          final slice = items.skip(i).take(cols).toList(growable: false);
          if (i > 0) rows.add(SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < cols; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(
                      child: j < slice.length
                          ? MetricCard(data: slice[j])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// Compact pill button used for quick dashboard actions without full-width button bloat.
class QuickActionChip extends StatelessWidget {
  const QuickActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = primary ? p.actionPrimary : p.surface;
    final fg = primary ? p.onPrimary : p.textPrimary;
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: Radii.rMd,
          border: primary ? null : Border.all(color: p.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: primary ? fg : p.actionPrimary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodySStrong.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact timestamped activity / audit row.
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.tone = Tone.info,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String timestamp;
  final Tone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon, tone: tone, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySStrong.copyWith(
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timestamp,
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: p.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact row item for user directories, account rosters, and participant lists.
class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.name,
    required this.email,
    this.imageUrl,
    this.avatarTone = Tone.info,
    this.badges = const [],
    this.trailing,
    this.onTap,
  });

  final String name;
  final String email;
  final String? imageUrl;
  final Tone avatarTone;
  final List<Widget> badges;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cleanName = name.trim().isEmpty ? 'Unnamed' : name.trim();
    final initialsSource = name.trim().isEmpty ? email : cleanName;
    final words = initialsSource
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words.length >= 2
        ? '${words.first[0]}${words[1][0]}'.toUpperCase()
        : (initialsSource.isEmpty ? 'U' : initialsSource[0].toUpperCase());

    return InkWell(
      onTap: onTap,
      splashColor: p.sunken,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            AppAvatar(
              initials,
              imageUrl: imageUrl,
              tone: avatarTone,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMStrong.copyWith(color: p.textPrimary),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: p.textSecondary),
                    ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: badges),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
