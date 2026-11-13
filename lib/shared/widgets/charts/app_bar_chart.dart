// Responsive bar chart for already-loaded values; data access stays in repositories.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/shared/widgets/charts/chart_theme.dart';
import 'package:upbridge/shared/widgets/surfaces.dart';

class AppBarChart extends StatelessWidget {
  const AppBarChart({
    super.key,
    required this.values,
    this.height = 190,
    this.emptyMessage = 'No chart data yet.',
  });

  final List<ChartValue> values;
  final double height;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return EmptyState(icon: Icons.bar_chart_rounded, title: emptyMessage);
    }
    final maxValue = math.max(
      1.0,
      values.map((v) => v.value).reduce((a, b) => math.max(a, b).toDouble()),
    );
    return Semantics(
      label: values.map((v) => '${v.label}: ${v.value}').join(', '),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _BarPainter(values: values, maxValue: maxValue),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final value in values)
                  Expanded(
                    child: Text(
                      value.label,
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

class _BarPainter extends CustomPainter {
  const _BarPainter({required this.values, required this.maxValue});

  final List<ChartValue> values;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = Paint()
      ..color = ChartTheme.grid
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      baseline,
    );
    final slot = size.width / values.length;
    final barWidth = math.min(28.0, slot * 0.58);
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final barHeight =
          (value.value.clamp(0, maxValue) / maxValue) * (size.height - 8);
      final rect = Rect.fromLTWH(
        slot * i + (slot - barWidth) / 2,
        size.height - barHeight,
        barWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..color =
              value.color ?? ChartTheme.series[i % ChartTheme.series.length],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}
