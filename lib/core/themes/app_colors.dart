import 'package:flutter/material.dart';

/// Centralized UpBridge Rwanda color tokens (Light defaults + Light/Dark ThemeExtension).
abstract final class AppColors {
  static const navy = Color(0xFF123B75);
  static const actionBlue = Color(0xFF2563EB);

  static const canvas = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFF1F5F9);
  static const inverse = navy;

  static const borderSubtle = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);

  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF64748B);
  static const textDisabled = Color(0xFF94A3B8);
  static const textInverse = Color(0xFFFFFFFF);
  static const link = actionBlue;

  static const actionPrimary = actionBlue;
  static const onPrimary = Color(0xFFFFFFFF);

  static const accent = actionBlue;
  static const accentText = Color(0xFF1D4ED8);
  static const accentSubtle = Color(0xFFEFF6FF);

  static const infoText = Color(0xFF2563EB);
  static const infoBase = Color(0xFF3B82F6);
  static const infoSubtle = Color(0xFFEFF6FF);
  static const successText = Color(0xFF15966A);
  static const successSubtle = Color(0xFFE8F7F1);
  static const warningText = Color(0xFFB45309);
  static const warningBase = Color(0xFFF59E0B);
  static const warningSubtle = Color(0xFFFEF3C7);
  static const dangerText = Color(0xFFDC4545);
  static const dangerSubtle = Color(0xFFFEECEC);

  static const focus = actionBlue;
  static Color get scrim => navy.withValues(alpha: 0.48);
}

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

  Color foregroundFor(BuildContext context) {
    final p = context.palette;
    return switch (this) {
      Tone.neutral => p.textSecondary,
      Tone.info => p.infoText,
      Tone.success => p.successText,
      Tone.warning => p.warningText,
      Tone.danger => p.dangerText,
      Tone.accent => p.accentText,
    };
  }

  Color backgroundFor(BuildContext context) {
    final p = context.palette;
    return switch (this) {
      Tone.neutral => p.sunken,
      Tone.info => p.infoSubtle,
      Tone.success => p.successSubtle,
      Tone.warning => p.warningSubtle,
      Tone.danger => p.dangerSubtle,
      Tone.accent => p.accentSubtle,
    };
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.sunken,
    required this.inverse,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.link,
    required this.actionPrimary,
    required this.onPrimary,
    required this.accent,
    required this.accentText,
    required this.accentSubtle,
    required this.infoText,
    required this.infoSubtle,
    required this.successText,
    required this.successSubtle,
    required this.warningText,
    required this.warningSubtle,
    required this.dangerText,
    required this.dangerSubtle,
    required this.focus,
  });

  final Color canvas;
  final Color surface;
  final Color sunken;
  final Color inverse;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;
  final Color link;
  final Color actionPrimary;
  final Color onPrimary;
  final Color accent;
  final Color accentText;
  final Color accentSubtle;
  final Color infoText;
  final Color infoSubtle;
  final Color successText;
  final Color successSubtle;
  final Color warningText;
  final Color warningSubtle;
  final Color dangerText;
  final Color dangerSubtle;
  final Color focus;

  static const light = AppPalette(
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    sunken: AppColors.sunken,
    inverse: AppColors.inverse,
    borderSubtle: AppColors.borderSubtle,
    borderStrong: AppColors.borderStrong,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    textInverse: AppColors.textInverse,
    link: AppColors.link,
    actionPrimary: AppColors.actionPrimary,
    onPrimary: AppColors.onPrimary,
    accent: AppColors.accent,
    accentText: AppColors.accentText,
    accentSubtle: AppColors.accentSubtle,
    infoText: AppColors.infoText,
    infoSubtle: AppColors.infoSubtle,
    successText: AppColors.successText,
    successSubtle: AppColors.successSubtle,
    warningText: AppColors.warningText,
    warningSubtle: AppColors.warningSubtle,
    dangerText: AppColors.dangerText,
    dangerSubtle: AppColors.dangerSubtle,
    focus: AppColors.focus,
  );

  static const dark = AppPalette(
    canvas: Color(0xFF0B1120),
    surface: Color(0xFF131C31),
    sunken: Color(0xFF1B2741),
    inverse: Color(0xFF123B75),
    borderSubtle: Color(0xFF24324D),
    borderStrong: Color(0xFF3A4D70),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF94A3B8),
    textInverse: Color(0xFFFFFFFF),
    link: Color(0xFF60A5FA),
    actionPrimary: Color(0xFF2563EB),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF3B82F6),
    accentText: Color(0xFF93C5FD),
    accentSubtle: Color(0xFF172554),
    infoText: Color(0xFF60A5FA),
    infoSubtle: Color(0xFF172554),
    successText: Color(0xFF34D399),
    successSubtle: Color(0xFF0D3326),
    warningText: Color(0xFFFBBF24),
    warningSubtle: Color(0xFF3B2808),
    dangerText: Color(0xFFF87171),
    dangerSubtle: Color(0xFF3B1618),
    focus: Color(0xFF60A5FA),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? sunken,
    Color? inverse,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? link,
    Color? actionPrimary,
    Color? onPrimary,
    Color? accent,
    Color? accentText,
    Color? accentSubtle,
    Color? infoText,
    Color? infoSubtle,
    Color? successText,
    Color? successSubtle,
    Color? warningText,
    Color? warningSubtle,
    Color? dangerText,
    Color? dangerSubtle,
    Color? focus,
  }) => AppPalette(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    sunken: sunken ?? this.sunken,
    inverse: inverse ?? this.inverse,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    borderStrong: borderStrong ?? this.borderStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    textInverse: textInverse ?? this.textInverse,
    link: link ?? this.link,
    actionPrimary: actionPrimary ?? this.actionPrimary,
    onPrimary: onPrimary ?? this.onPrimary,
    accent: accent ?? this.accent,
    accentText: accentText ?? this.accentText,
    accentSubtle: accentSubtle ?? this.accentSubtle,
    infoText: infoText ?? this.infoText,
    infoSubtle: infoSubtle ?? this.infoSubtle,
    successText: successText ?? this.successText,
    successSubtle: successSubtle ?? this.successSubtle,
    warningText: warningText ?? this.warningText,
    warningSubtle: warningSubtle ?? this.warningSubtle,
    dangerText: dangerText ?? this.dangerText,
    dangerSubtle: dangerSubtle ?? this.dangerSubtle,
    focus: focus ?? this.focus,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      sunken: Color.lerp(sunken, other.sunken, t) ?? sunken,
      inverse: Color.lerp(inverse, other.inverse, t) ?? inverse,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderStrong:
          Color.lerp(borderStrong, other.borderStrong, t) ?? borderStrong,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      textInverse: Color.lerp(textInverse, other.textInverse, t) ?? textInverse,
      link: Color.lerp(link, other.link, t) ?? link,
      actionPrimary:
          Color.lerp(actionPrimary, other.actionPrimary, t) ?? actionPrimary,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentText: Color.lerp(accentText, other.accentText, t) ?? accentText,
      accentSubtle:
          Color.lerp(accentSubtle, other.accentSubtle, t) ?? accentSubtle,
      infoText: Color.lerp(infoText, other.infoText, t) ?? infoText,
      infoSubtle: Color.lerp(infoSubtle, other.infoSubtle, t) ?? infoSubtle,
      successText: Color.lerp(successText, other.successText, t) ?? successText,
      successSubtle:
          Color.lerp(successSubtle, other.successSubtle, t) ?? successSubtle,
      warningText: Color.lerp(warningText, other.warningText, t) ?? warningText,
      warningSubtle:
          Color.lerp(warningSubtle, other.warningSubtle, t) ?? warningSubtle,
      dangerText: Color.lerp(dangerText, other.dangerText, t) ?? dangerText,
      dangerSubtle:
          Color.lerp(dangerSubtle, other.dangerSubtle, t) ?? dangerSubtle,
      focus: Color.lerp(focus, other.focus, t) ?? focus,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
