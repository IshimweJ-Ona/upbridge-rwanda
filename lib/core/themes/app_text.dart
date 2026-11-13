// Defines reusable text styles for the product typography scale.
import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';

/// Text styles from the Figma file (IBM Plex Sans for reading, IBM Plex Mono for evidence metadata).
abstract final class AppText {
  static const _sans = 'IBMPlexSans';
  static const _mono = 'IBMPlexMono';

  static const display = TextStyle(fontFamily: _sans, fontSize: 30, height: 36 / 30, letterSpacing: -0.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const titleL = TextStyle(fontFamily: _sans, fontSize: 24, height: 30 / 24, letterSpacing: -0.3, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const titleM = TextStyle(fontFamily: _sans, fontSize: 18, height: 24 / 18, letterSpacing: -0.1, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const titleS = TextStyle(fontFamily: _sans, fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const bodyM = TextStyle(fontFamily: _sans, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const bodyMStrong = TextStyle(fontFamily: _sans, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const bodyS = TextStyle(fontFamily: _sans, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const bodySStrong = TextStyle(fontFamily: _sans, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const caption = TextStyle(fontFamily: _sans, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static const button = TextStyle(fontFamily: _sans, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const tab = TextStyle(fontFamily: _sans, fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w500, color: AppColors.textMuted);

  /// Always rendered in capitals — use [MonoLabel], which uppercases the text.
  static const labelMono = TextStyle(fontFamily: _mono, fontSize: 11, height: 14 / 11, letterSpacing: 0.6, fontWeight: FontWeight.w500, color: AppColors.textMuted);
  static const dataMono = TextStyle(fontFamily: _mono, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const dataMonoStrong = TextStyle(fontFamily: _mono, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const dataMonoL = TextStyle(fontFamily: _mono, fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
}
