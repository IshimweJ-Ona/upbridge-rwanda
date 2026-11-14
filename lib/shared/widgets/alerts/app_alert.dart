// A semantic alert panel for success, warning, information, and recoverable errors.
import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';

class AppAlert extends StatelessWidget {
  const AppAlert({
    super.key,
    required this.title,
    required this.message,
    this.variant = AlertVariant.info,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final AlertVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (variant) {
      AlertVariant.success => (
        Icons.check_circle_outline_rounded,
        AppColors.successText,
        AppColors.successSubtle,
      ),
      AlertVariant.warning => (
        Icons.warning_amber_rounded,
        AppColors.warningText,
        AppColors.warningSubtle,
      ),
      AlertVariant.error => (
        Icons.error_outline_rounded,
        AppColors.dangerText,
        AppColors.dangerSubtle,
      ),
      AlertVariant.info => (
        Icons.info_outline_rounded,
        AppColors.infoText,
        AppColors.infoSubtle,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: Radii.rMd,
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.bodySStrong.copyWith(color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: AppText.bodyS.copyWith(color: AppColors.textPrimary),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 8),
                    TextButton(onPressed: onAction, child: Text(actionLabel!)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AlertVariant { success, warning, error, info }
