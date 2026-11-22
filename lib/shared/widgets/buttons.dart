import 'package:flutter/material.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/animations/pressable.dart';

enum ButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
  dangerOutline,
  onDark,
  outlineOnDark,
}

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

  (Color, Color, Color?) _colorsFor(BuildContext context) {
    final p = context.palette;
    return switch (variant) {
      ButtonVariant.primary => (p.actionPrimary, p.onPrimary, null),
      ButtonVariant.secondary => (p.surface, p.textPrimary, p.borderStrong),
      ButtonVariant.ghost => (Colors.transparent, p.link, null),
      ButtonVariant.danger => (p.dangerText, Colors.white, null),
      ButtonVariant.dangerOutline => (p.surface, p.dangerText, p.dangerText),
      ButtonVariant.onDark => (Colors.white, AppColors.navy, null),
      ButtonVariant.outlineOnDark => (
        Colors.transparent,
        Colors.white,
        const Color(0x99FFFFFF),
      ),
    };
  }

  double get _height => switch (size) {
    ButtonSize.large => 46,
    ButtonSize.medium => 42,
    ButtonSize.small => 36,
  };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = _colorsFor(context);
    final textStyle =
        (size == ButtonSize.small ? AppText.bodySStrong : AppText.button)
            .copyWith(color: fg);
    final iconSize = size == ButtonSize.small ? 16.0 : 18.0;
    final dur = Motion.durationFor(context, Motion.fast);

    final content = AnimatedSwitcher(
      duration: dur,
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
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: iconSize, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: iconSize, color: fg),
                ],
              ],
            ),
    );

    final button = AnimatedOpacity(
      opacity: onPressed == null ? 0.45 : 1,
      duration: dur,
      child: Container(
        constraints: BoxConstraints(minHeight: _height),
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: variant == ButtonVariant.ghost
              ? 8
              : (size == ButtonSize.small ? 12 : 18),
        ),
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

class TextLink extends StatelessWidget {
  const TextLink(
    this.label, {
    super.key,
    this.onTap,
    this.color,
    this.style,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final TextStyle? style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 36 : 44),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 4 : 8,
              horizontal: 4,
            ),
            child: Text(
              label,
              style: (style ?? AppText.bodySStrong).copyWith(
                color: color ?? p.link,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = false,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final btn = Pressable(
      onTap: onTap,
      scale: 0.9,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: color ?? p.textPrimary),
            if (badge)
              Positioned(
                top: 11,
                right: 11,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.canvas, width: 1.5),
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
