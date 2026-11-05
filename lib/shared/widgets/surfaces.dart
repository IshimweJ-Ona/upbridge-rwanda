// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';

import 'package:upbridge/shared/animations/effects.dart';
import 'package:upbridge/shared/animations/pressable.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/widgets/buttons.dart';

/// Uppercase monospace label used for eyebrows, metadata and section headers.
class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key, this.color = AppColors.textMuted, this.maxLines});

  final String text;
  final Color color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppText.labelMono.copyWith(color: color),
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
}

/// Section header: mono label with an optional action on the right.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.action, this.onAction, this.top = 24});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Row(
        children: [
          Expanded(child: MonoLabel(title)),
          if (action != null) TextLink(action!, onTap: onAction),
        ],
      ),
    );
  }
}

/// White grouped container with hairlines between rows.
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children, this.dividers = true, this.color = AppColors.surface});

  final List<Widget> children;
  final bool dividers;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && dividers) items.add(const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle));
      items.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: Radii.rLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: Radii.rLg,
        child: Material(type: MaterialType.transparency, child: Column(children: items)),
      ),
    );
  }
}

/// Plain card surface.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.accentEdge, this.color = AppColors.surface});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentEdge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: Radii.rLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: Radii.rLg,
        child: accentEdge == null
            ? Padding(padding: padding, child: child)
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accentEdge),
                    Expanded(child: Padding(padding: padding, child: child)),
                  ],
                ),
              ),
      ),
    );
    return onTap == null ? card : Pressable(onTap: onTap, scale: 0.985, child: card);
  }
}

/// Rounded square with an icon, tinted by tone.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.tone = Tone.neutral, this.size = 36});

  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: tone.background, borderRadius: Radii.rMd),
        child: Icon(icon, size: size * 0.52, color: tone == Tone.neutral ? AppColors.textPrimary : tone.foreground),
      );
}

/// Tappable row inside a [ListGroup].
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
    this.metaColor = AppColors.textMuted,
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
  final Color metaColor;
  final EdgeInsetsGeometry padding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final showChevron = chevron ?? onTap != null;
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.sunken,
      highlightColor: AppColors.sunken.withValues(alpha: 0.5),
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
                  Text(title, style: titleStyle ?? (dense ? AppText.bodySStrong : AppText.bodyMStrong)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.bodyS),
                  ],
                  if (meta != null) ...[
                    const SizedBox(height: 4),
                    MonoLabel(meta!, color: metaColor),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (showChevron) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = Tone.neutral, this.icon});

  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: tone.background, borderRadius: Radii.rSm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: tone.foreground), const SizedBox(width: 4)],
            Text(label, style: AppText.caption.copyWith(color: tone.foreground, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class AppAvatar extends StatelessWidget {
  const AppAvatar(this.initials, {super.key, this.tone = Tone.info, this.size = 40});

  final String initials;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tone.background, shape: BoxShape.circle),
        child: Text(
          initials,
          style: AppText.bodySStrong.copyWith(
            color: tone == Tone.neutral ? AppColors.textPrimary : tone.foreground,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

/// Thin animated progress bar.
class ProgressLine extends StatelessWidget {
  const ProgressLine(this.value, {super.key, this.color = AppColors.accent, this.height = 6});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: AnimatedFraction(
          value: value,
          builder: (context, v) => Stack(
            children: [
              Container(color: AppColors.sunken),
              FractionallySizedBox(widthFactor: v, child: Container(color: color)),
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

/// Row of figures separated by hairlines (H2, M2, MH1, AD1…).
class StatStrip extends StatelessWidget {
  const StatStrip(this.items, {super.key});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 24, thickness: 1, color: AppColors.borderSubtle),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    items[i].countTo == null
                        ? Text(items[i].value, style: AppText.dataMonoL)
                        : CountUp(value: items[i].countTo!, style: AppText.dataMonoL),
                    const SizedBox(height: 2),
                    Text(items[i].label, style: AppText.caption),
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

/// Inline notice: info, warning, danger or neutral.
class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key, required this.title, this.body, this.tone = Tone.neutral, this.icon});

  final String title;
  final String? body;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = tone == Tone.neutral ? AppColors.textSecondary : tone.foreground;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tone.background, borderRadius: Radii.rMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline_rounded, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodySStrong.copyWith(color: tone == Tone.neutral ? AppColors.textPrimary : fg)),
                if (body != null) ...[const SizedBox(height: 2), Text(body!, style: AppText.bodyS)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-column facts table (J2 "Type / Pay / Where", J6 reference, M4 summary).
class KeyValueTable extends StatelessWidget {
  const KeyValueTable(this.rows, {super.key, this.monoValues = false, this.keyWidth = 96});

  final List<(String, String)> rows;
  final bool monoValues;
  final double keyWidth;

  @override
  Widget build(BuildContext context) {
    return ListGroup(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: keyWidth, child: Text(r.$1, style: AppText.bodyS.copyWith(color: AppColors.textMuted))),
                Expanded(child: Text(r.$2, style: monoValues ? AppText.dataMonoStrong : AppText.bodySStrong)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Wrap of small neutral tags (skills, "Helps with").
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

/// Dashed-feel empty state used for "Nothing to review yet" and empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: Radii.rLg,
        border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(title, style: AppText.bodyMStrong, textAlign: TextAlign.center),
          if (body != null) ...[const SizedBox(height: 4), Text(body!, style: AppText.bodyS, textAlign: TextAlign.center)],
          if (action != null) ...[
            const SizedBox(height: 14),
            AppButton(action!, onPressed: onAction, variant: ButtonVariant.secondary, size: ButtonSize.medium, expand: false),
          ],
        ],
      ),
    );
  }
}
