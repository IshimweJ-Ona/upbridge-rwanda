// Presents transient in-app feedback using the shared toast and banner components.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/shared/widgets/feedback.dart' show AppBanner;
import 'package:upbridge/shared/widgets/feedback.dart' as feedback;

class NotificationService {
  const NotificationService();

  void showToast(
    BuildContext context,
    String message, {
    Tone tone = Tone.success,
    IconData icon = Icons.check_circle_rounded,
  }) {
    feedback.showToast(context, message, tone: tone, icon: icon);
  }

  void showBanner(WidgetRef ref, AppBanner banner) {
    ref.read(feedback.bannerProvider.notifier).show(banner);
  }

  void dismissBanner(WidgetRef ref) {
    ref.read(feedback.bannerProvider.notifier).hide();
  }
}
