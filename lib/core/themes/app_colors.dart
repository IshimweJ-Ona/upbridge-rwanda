// Defines semantic color roles shared by themes, widgets, and charts.
import 'package:flutter/material.dart';

/// Colour roles from the Figma variables (page 01 — Foundations).
abstract final class AppColors {
  static const canvas = Color(0xFFF7F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFEFEBE3);
  static const inverse = Color(0xFF13294B);

  static const borderSubtle = Color(0xFFE2DCD0);
  static const borderStrong = Color(0xFF948B7C);

  static const textPrimary = Color(0xFF13294B);
  static const textSecondary = Color(0xFF3A4A63);
  static const textMuted = Color(0xFF5B6880);
  static const textDisabled = Color(0xFFA3ABB8);
  static const textInverse = Color(0xFFFFFFFF);
  static const link = Color(0xFF1D5FB4);

  static const actionPrimary = Color(0xFF13294B);
  static const onPrimary = Color(0xFFFFFFFF);

  static const accent = Color(0xFFC2510F);
  static const accentText = Color(0xFFA8460D);
  static const accentSubtle = Color(0xFFFCEBDD);
  static const brandOrange = Color(0xFFF68719);

  static const infoText = Color(0xFF1D5FB4);
  static const infoSubtle = Color(0xFFE7EFFA);
  static const successText = Color(0xFF1E7A4C);
  static const successSubtle = Color(0xFFE3F2EA);
  static const warningText = Color(0xFF8F5600);
  static const warningSubtle = Color(0xFFFFF1D6);
  static const dangerText = Color(0xFFB42318);
  static const dangerSubtle = Color(0xFFFCE9E7);

  static const focus = Color(0xFF1D5FB4);

  static Color get scrim => inverse.withValues(alpha: 0.48);
}

/// Semantic tones used by badges, notices, avatars and icon tiles.
enum Tone { neutral, info, success, warning, danger, accent }

extension ToneColors on Tone {
  Color get foreground => switch (this) {
        Tone.neutral => AppColors.textSecondary,
        Tone.info => AppColors.infoText,
        Tone.success => AppColors.successText,
        Tone.warning => AppColors.warningText,
        Tone.danger => AppColors.dangerText,
        Tone.accent => AppColors.accentText,
      };

  Color get background => switch (this) {
        Tone.neutral => AppColors.sunken,
        Tone.info => AppColors.infoSubtle,
        Tone.success => AppColors.successSubtle,
        Tone.warning => AppColors.warningSubtle,
        Tone.danger => AppColors.dangerSubtle,
        Tone.accent => AppColors.accentSubtle,
      };
}
