// Donut chart for category totals using the shared chart palette.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/shared/widgets/charts/chart_theme.dart';
import 'package:upbridge/shared/widgets/surfaces.dart';

class AppDonutChart extends StatelessWidget {
  const AppDonutChart({
    super.key,
    required this.values,
    this.size = 176,
    this.emptyMessage = 'No chart data yet.',
  });

  final List<ChartValue> values;
  final double size;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(
      0,
      (sum, value) => sum + math.max(0, value.value).toDouble(),
    );
    if (total <= 0) {
      return EmptyState(icon: Icons.donut_small_rounded, title: emptyMessage);
    }

    return Semantics(
      label: values.map((v) => '${v.label}: ${v.value}').join(', '),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _DonutPainter(values: values, total: total),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  total.toStringAsFixed(total % 1 == 0 ? 0 : 1),
                  style: AppText.titleM,
                ),
                Text('TOTAL', style: AppText.labelMono),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.total});

  final List<ChartValue> values;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(8);
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final value = math.max(0, values[index].value);
      if (value == 0) continue;
      final sweep = value / total * math.pi * 2;
      final paint = Paint()
        ..color =
            values[index].color ??
            ChartTheme.series[index % ChartTheme.series.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.14;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.total != total;
}
