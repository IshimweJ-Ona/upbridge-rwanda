// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';

import 'package:upbridge/shared/animations/pressable.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';

enum ButtonVariant { primary, secondary, ghost, danger, dangerOutline, onDark, outlineOnDark }

enum ButtonSize { large, medium, small }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.large,
    this.icon,
    this.leadingIcon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final IconData? leadingIcon;
  final bool loading;
  final bool expand;

  (Color, Color, Color?) get _colors => switch (variant) {
        ButtonVariant.primary => (AppColors.actionPrimary, AppColors.onPrimary, null),
        ButtonVariant.secondary => (AppColors.surface, AppColors.textPrimary, AppColors.borderStrong),
        ButtonVariant.ghost => (Colors.transparent, AppColors.link, null),
        ButtonVariant.danger => (AppColors.dangerText, AppColors.onPrimary, null),
        ButtonVariant.dangerOutline => (AppColors.surface, AppColors.dangerText, AppColors.dangerText),
        ButtonVariant.onDark => (AppColors.surface, AppColors.textPrimary, null),
        ButtonVariant.outlineOnDark => (Colors.transparent, AppColors.textInverse, const Color(0x99FFFFFF)),
      };

  double get _height => switch (size) {
        ButtonSize.large => 48,
        ButtonSize.medium => 40,
        ButtonSize.small => 32,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = _colors;
    final textStyle = (size == ButtonSize.small ? AppText.bodySStrong : AppText.button).copyWith(color: fg);
    final iconSize = size == ButtonSize.small ? 16.0 : 18.0;

    final content = AnimatedSwitcher(
      duration: Motion.fast,
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[Icon(leadingIcon, size: iconSize, color: fg), const SizedBox(width: 8)],
                Flexible(child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: iconSize, color: fg)],
              ],
            ),
    );

    final button = AnimatedOpacity(
      opacity: onPressed == null ? 0.42 : 1,
      duration: Motion.fast,
      child: Container(
        height: _height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: variant == ButtonVariant.ghost ? 4 : (size == ButtonSize.small ? 12 : 18)),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: size == ButtonSize.small ? Radii.rSm : Radii.rMd,
          border: border == null ? null : Border.all(color: border),
        ),
        alignment: expand ? Alignment.center : null,
        child: expand ? content : Center(widthFactor: 1, child: content),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Pressable(onTap: enabled ? onPressed : null, child: button),
    );
  }
}

/// Inline text action, e.g. "Forgot password?", "See all".
class TextLink extends StatelessWidget {
  const TextLink(this.label, {super.key, this.onTap, this.color = AppColors.link, this.style});

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label, style: (style ?? AppText.bodySStrong).copyWith(color: color)),
      ),
    );
  }
}

/// Round icon button used for back arrows, bells and header actions.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, this.onTap, this.badge = false, this.tooltip, this.color = AppColors.textPrimary});

  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;
  final String? tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final btn = Pressable(
      onTap: onTap,
      scale: 0.9,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            if (badge)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.canvas, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}
