// Draws the shared animated success checkmark.
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_tokens.dart';

/// The round success mark used on confirmation screens: the circle pops in,
/// then the tick draws itself.
class SuccessMark extends StatefulWidget {
  const SuccessMark({super.key, this.size = 56, this.tone = Tone.success});

  final double size;
  final Tone tone;

  @override
  State<SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<SuccessMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _pop = CurvedAnimation(parent: _c, curve: const Interval(0, 0.55, curve: Motion.emphasized));
  late final Animation<double> _draw = CurvedAnimation(parent: _c, curve: const Interval(0.35, 1, curve: Motion.curve));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Transform.scale(
        scale: _pop.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: widget.tone.background, shape: BoxShape.circle),
          child: CustomPaint(painter: _TickPainter(progress: _draw.value, color: widget.tone.foreground)),
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.31, w * 0.52)
      ..lineTo(w * 0.44, w * 0.65)
      ..lineTo(w * 0.70, w * 0.38);
    final paint = Paint()
      ..color = color
      ..strokeWidth = w * 0.055
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final out = Path();
    for (final PathMetric m in path.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * progress), Offset.zero);
    }
    canvas.drawPath(out, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress || old.color != color;
}
