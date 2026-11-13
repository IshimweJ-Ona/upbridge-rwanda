// Shared data shape, palette, and axis colors for the lightweight chart widgets.
import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';

class ChartValue {
  const ChartValue({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final Color? color;
}

class ChartPoint {
  const ChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

abstract final class ChartTheme {
  static const grid = AppColors.borderSubtle;
  static const label = AppColors.textMuted;
  static const series = [
    AppColors.link,
    AppColors.brandOrange,
    AppColors.successText,
    AppColors.warningText,
    AppColors.accentText,
  ];
}
