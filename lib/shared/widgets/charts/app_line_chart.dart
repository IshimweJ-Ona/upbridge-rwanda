// Line chart for ordered progress points with accessible labels and an empty state.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/shared/widgets/charts/chart_theme.dart';
import 'package:upbridge/shared/widgets/surfaces.dart';

class AppLineChart extends StatelessWidget {
  const AppLineChart({
    super.key,
    required this.points,
    this.height = 190,
    this.emptyMessage = 'No progress data yet.',
  });

  final List<ChartPoint> points;
  final double height;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return EmptyState(icon: Icons.show_chart_rounded, title: emptyMessage);
    }
    final values = points.map((point) => point.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    return Semantics(
      label: points.map((p) => '${p.label}: ${p.value}').join(', '),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _LinePainter(
                  points: points,
                  minValue: minValue,
                  maxValue: maxValue,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final point in points)
                  Expanded(
                    child: Text(
                      point.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.points,
    required this.minValue,
    required this.maxValue,
  });

  final List<ChartPoint> points;
  final double minValue;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = ChartTheme.grid
      ..strokeWidth = 1;
    final path = Path();
    final range = maxValue - minValue;
    for (var row = 0; row < 4; row++) {
      final y = size.height * row / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final normalized = range == 0
          ? 0.5
          : (points[i].value - minValue) / range;
      final position = Offset(x, size.height * (1 - normalized));
      if (i == 0) {
        path.moveTo(position.dx, position.dy);
      } else {
        path.lineTo(position.dx, position.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = ChartTheme.series.first
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final normalized = range == 0
          ? 0.5
          : (points[i].value - minValue) / range;
      canvas.drawCircle(
        Offset(x, size.height * (1 - normalized)),
        4,
        Paint()..color = ChartTheme.series.first,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.minValue != minValue ||
      oldDelegate.maxValue != maxValue;
}
