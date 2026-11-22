// Opens external links with platform-aware URL launch behavior.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/shared/widgets/feedback.dart';

/// Opens a link in the browser or the right app (Google Meet, WhatsApp…).
Future<void> openLink(BuildContext context, String url) async {
  final trimmed = url.trim();
  var ok = false;
  if (trimmed.isNotEmpty) {
    final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        ok = false;
      }
    }
  }
  if (!ok && context.mounted) {
    showToast(
      context,
      'Couldn’t open the link. Check the URL and your connection.',
      icon: Icons.link_off_rounded,
      tone: Tone.warning,
    );
  }
}

/// Copies text and confirms with a toast.
Future<void> copyText(
  BuildContext context,
  String text, {
  String message = 'Copied',
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showToast(context, message, icon: Icons.copy_rounded);
}

/// Short, readable form of a URL for display.
String displayUrl(String url) =>
    url.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/$'), '');
