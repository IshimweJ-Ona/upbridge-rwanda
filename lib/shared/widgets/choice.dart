// Provides reusable selection chips, cards, tabs, and rubric controls.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:upbridge/shared/animations/pressable.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';

/// Pill that fills navy and shows a tick when selected.
class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, this.onTap, this.icon, this.enabled = true, this.showCheck = true});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool enabled;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimary : (enabled ? AppColors.textPrimary : AppColors.textDisabled);
    return Pressable(
      onTap: enabled ? onTap : null,
      scale: 0.95,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.actionPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: selected ? AppColors.actionPrimary : (enabled ? AppColors.borderStrong : AppColors.borderSubtle)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: Motion.base,
              curve: Motion.curve,
              child: selected && showCheck
                  ? const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary),
                    )
                  : icon != null
                      ? Padding(padding: const EdgeInsets.only(right: 6), child: Icon(icon, size: 16, color: fg))
                      : const SizedBox.shrink(),
            ),
            Text(label, style: AppText.bodySStrong.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrolling filter row (J1, M1, MR1, AD2).
class ChipBar extends StatelessWidget {
  const ChipBar({super.key, required this.options, required this.selected, required this.onSelected, this.padding = const EdgeInsets.symmetric(horizontal: Space.gutter)});

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => SelectChip(
          label: options[i],
          selected: options[i] == selected,
          showCheck: false,
          onTap: () => onSelected(options[i]),
        ),
      ),
    );
  }
}

class RadioOption<T> {
  const RadioOption({required this.value, required this.title, this.subtitle, this.icon});
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
}

/// Stack of selectable cards with an animated radio dot (O1, M3, S2, AD3).
class RadioCards<T> extends StatelessWidget {
  const RadioCards({super.key, required this.options, required this.value, required this.onChanged, this.error = false});

  final List<RadioOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _RadioCard<T>(option: options[i], selected: options[i].value == value, error: error, onTap: () => onChanged(options[i].value)),
        ],
      ],
    );
  }
}

class _RadioCard<T> extends StatelessWidget {
  const _RadioCard({required this.option, required this.selected, required this.onTap, required this.error});

  final RadioOption<T> option;
  final bool selected;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.985,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.curve,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.infoSubtle.withValues(alpha: 0.55) : AppColors.surface,
            borderRadius: Radii.rLg,
            border: Border.all(
              color: selected ? AppColors.actionPrimary : (error ? AppColors.dangerText : AppColors.borderSubtle),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (option.icon != null) ...[
                AnimatedContainer(
                  duration: Motion.base,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: selected ? AppColors.actionPrimary : AppColors.sunken, borderRadius: Radii.rMd),
                  child: Icon(option.icon, size: 19, color: selected ? AppColors.onPrimary : AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title, style: AppText.bodyMStrong),
                    if (option.subtitle != null) ...[const SizedBox(height: 2), Text(option.subtitle!, style: AppText.bodyS)],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.base,
      curve: Motion.curve,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: selected ? AppColors.actionPrimary : AppColors.borderStrong, width: selected ? 6.5 : 1.4),
      ),
    );
  }
}

/// Underlined segmented tabs with a sliding indicator (P1/P5, J7, AD4, AD6/AD9).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.tabs, required this.index, required this.onChanged, this.counts});

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final List<int?>? counts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth / tabs.length;
        return SizedBox(
          height: 44,
          child: Stack(
            children: [
              const Positioned(left: 0, right: 0, bottom: 0, child: Divider(height: 1, thickness: 1, color: AppColors.borderSubtle)),
              AnimatedPositioned(
                duration: Motion.base,
                curve: Motion.curve,
                left: w * index + 8,
                width: w - 16,
                bottom: 0,
                height: 2.5,
                child: Container(decoration: const BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.vertical(top: Radius.circular(2)))),
              ),
              Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (i == index) return;
                          HapticFeedback.selectionClick();
                          onChanged(i);
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: Motion.fast,
                                style: AppText.bodySStrong.copyWith(color: i == index ? AppColors.textPrimary : AppColors.textMuted, fontWeight: i == index ? FontWeight.w600 : FontWeight.w500),
                                child: Text(tabs[i]),
                              ),
                              if (counts != null && i < counts!.length && counts![i] != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: i == index ? AppColors.accentSubtle : AppColors.sunken, borderRadius: BorderRadius.circular(10)),
                                  child: Text('${counts![i]}', style: AppText.labelMono.copyWith(color: i == index ? AppColors.accentText : AppColors.textMuted)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Swaps between tab bodies with a fade + small slide in the direction of travel.
class TabBodySwitcher extends StatelessWidget {
  const TabBodySwitcher({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.curve,
      switchOutCurve: Motion.exit,
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim), child: child),
      ),
      child: KeyedSubtree(key: ValueKey(index), child: child),
    );
  }
}

/// Three-way verdict selector for each rubric criterion (MR3).
class VerdictSelector extends StatelessWidget {
  const VerdictSelector({super.key, required this.labels, required this.value, required this.onChanged, this.tones = const []});

  final List<String> labels;
  final int? value;
  final ValueChanged<int> onChanged;
  final List<Color> tones;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.sunken, borderRadius: Radii.rMd),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          final tone = value != null && value! < tones.length ? tones[value!] : AppColors.actionPrimary;
          return Stack(
            children: [
              if (value != null)
                AnimatedPositioned(
                  duration: Motion.base,
                  curve: Motion.curve,
                  left: w * value!,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: AnimatedContainer(
                    duration: Motion.base,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(Radii.md - 2),
                      border: Border.all(color: tone, width: 1.4),
                      boxShadow: const [BoxShadow(color: Color(0x1413294B), blurRadius: 4, offset: Offset(0, 1))],
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(i);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: Motion.fast,
                            style: AppText.bodySStrong.copyWith(color: i == value ? tone : AppColors.textSecondary),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 1–5 scale used in the monthly check-in (H4).
class ScaleSelector extends StatelessWidget {
  const ScaleSelector({super.key, required this.value, required this.onChanged, this.min = 'Not useful', this.max = 'Very useful'});

  final int? value;
  final ValueChanged<int> onChanged;
  final String min;
  final String max;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 8),
              Expanded(
                child: Pressable(
                  onTap: () => onChanged(i),
                  scale: 0.92,
                  child: AnimatedContainer(
                    duration: Motion.base,
                    curve: Motion.curve,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == i ? AppColors.actionPrimary : AppColors.surface,
                      borderRadius: Radii.rMd,
                      border: Border.all(color: value == i ? AppColors.actionPrimary : AppColors.borderStrong),
                    ),
                    child: Text('$i', style: AppText.dataMonoL.copyWith(color: value == i ? AppColors.onPrimary : AppColors.textPrimary)),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(min, style: AppText.caption),
            const Spacer(),
            Text(max, style: AppText.caption),
          ],
        ),
      ],
    );
  }
}

/// Selectable card with a checkbox (J3 evidence picker).
class CheckCard extends StatelessWidget {
  const CheckCard({super.key, required this.selected, required this.onTap, required this.child, this.error = false});

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.curve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.rLg,
          border: Border.all(
            color: selected ? AppColors.actionPrimary : (error ? AppColors.dangerText : AppColors.borderSubtle),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: Motion.fast,
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: selected ? AppColors.actionPrimary : AppColors.surface,
                borderRadius: Radii.rSm,
                border: Border.all(color: selected ? AppColors.actionPrimary : AppColors.borderStrong, width: 1.4),
              ),
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: Motion.base,
                curve: Motion.emphasized,
                child: const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
