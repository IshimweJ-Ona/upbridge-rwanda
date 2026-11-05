// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';

/// UpBridge mark (roof, wall and the orange upward arrow) with an optional wordmark.
class UpBridgeLogo extends StatelessWidget {
  const UpBridgeLogo({super.key, this.markWidth = 66, this.onDark = false, this.showWordmark = true, this.horizontal = false});

  final double markWidth;
  final bool onDark;
  final bool showWordmark;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final ink = onDark ? AppColors.textInverse : AppColors.textPrimary;
    final mark = SizedBox(
      width: markWidth,
      height: markWidth * 38 / 66,
      child: CustomPaint(painter: _MarkPainter(ink: ink)),
    );
    if (!showWordmark) return Semantics(label: 'UpBridge Rwanda', child: mark);
    final words = Column(
      crossAxisAlignment: horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('UpBridge', style: AppText.titleM.copyWith(color: ink, letterSpacing: -0.2, height: 1.1)),
        Text('RWANDA', style: AppText.labelMono.copyWith(color: onDark ? const Color(0xB3FFFFFF) : AppColors.textMuted, letterSpacing: 2.2, fontSize: 9.5)),
      ],
    );
    return Semantics(
      label: 'UpBridge Rwanda',
      child: ExcludeSemantics(
        child: horizontal
            ? Row(mainAxisSize: MainAxisSize.min, children: [mark, const SizedBox(width: 10), words])
            : Column(mainAxisSize: MainAxisSize.min, children: [mark, const SizedBox(height: 8), words]),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 66;
    canvas.scale(s, s);
    final line = Paint()
      ..color = ink
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0.757, 33.87), const Offset(32.57, 11.59), line);
    canvas.drawLine(const Offset(32.75, 11.81), const Offset(64.56, 34.09), line);
    canvas.drawLine(const Offset(18.83, 36.97), const Offset(18.83, 11.24), line);

    final arrow = Paint()
      ..color = AppColors.brandOrange
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(47.69, 35.57), const Offset(47.69, 0.76), arrow);
    final head = Path()
      ..moveTo(42.34, 5.57)
      ..lineTo(47.69, 0.22)
      ..lineTo(53.04, 5.57);
    canvas.drawPath(head, arrow);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.ink != ink;
}
