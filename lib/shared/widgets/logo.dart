import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';

/// Vector SVG UpBridge bridge mark with optional wordmark.
class UpBridgeLogo extends StatelessWidget {
  const UpBridgeLogo({
    super.key,
    this.markWidth = 66,
    this.onDark = false,
    this.showWordmark = true,
    this.horizontal = false,
  });

  final double markWidth;
  final bool onDark;
  final bool showWordmark;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final darkSurface =
        onDark || Theme.of(context).brightness == Brightness.dark;
    final ink = darkSurface ? Colors.white : p.textPrimary;
    final asset = darkSurface
        ? 'assets/images/upbridge_logo_on_dark.svg'
        : 'assets/images/upbridge_logo.svg';

    final mark = SvgPicture.asset(
      asset,
      width: markWidth,
      height: markWidth * 38 / 66,
      fit: BoxFit.contain,
    );

    if (!showWordmark) {
      return Semantics(label: 'UpBridge Rwanda', child: mark);
    }

    final words = Column(
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'UpBridge',
          style: AppText.titleM.copyWith(
            color: ink,
            letterSpacing: -0.2,
            height: 1.1,
          ),
        ),
        Text(
          'RWANDA',
          style: AppText.labelMono.copyWith(
            color: darkSurface
                ? Colors.white.withValues(alpha: 0.72)
                : p.textMuted,
            letterSpacing: 2.2,
            fontSize: 9.5,
          ),
        ),
      ],
    );

    return Semantics(
      label: 'UpBridge Rwanda',
      child: ExcludeSemantics(
        child: horizontal
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [mark, const SizedBox(width: 10), words],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [mark, const SizedBox(height: 8), words],
              ),
      ),
    );
  }
}
