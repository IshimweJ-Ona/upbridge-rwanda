import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/settings_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showAppDialog(
      context,
      title: 'Sign out?',
      body: 'End your admin session on this device?',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirm || !context.mounted) return;
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return PageFrame(
      largeTitle: l10n.tabAdminSettings,
      subtitle: 'Preferences & admin audit log',
      onRefresh: () async => ref.invalidate(adminAuditLogsProvider),
      children: [
        const SizedBox(height: 12),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.translate_rounded, tone: Tone.info),
              title: l10n.languageTitle,
              subtitle: switch (prefs.locale.languageCode) {
                'rw' => 'Ikinyarwanda',
                'fr' => 'Français',
                _ => 'English',
              },
              onTap: () => context.push('/language'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const IconTile(
                  Icons.dark_mode_outlined,
                  tone: Tone.neutral,
                ),
                title: Text(l10n.darkModeLabel, style: AppText.bodyMStrong),
                value: prefs.themeMode == ThemeMode.dark,
                onChanged: (dark) => ref
                    .read(appPreferencesProvider.notifier)
                    .setThemeMode(dark ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppButton(
          l10n.signOut,
          variant: ButtonVariant.dangerOutline,
          onPressed: () => _signOut(context, ref),
        ),
        const SectionLabel('Recent audit logs'),
        logsAsync.when(
          loading: () => const SkeletonListLoader(rows: 3, showAvatar: true),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load audit logs',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(adminAuditLogsProvider),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No audit events recorded',
                body:
                    'Mentor reviews and account status updates appear here automatically.',
              );
            }
            return ListGroup(
              children: [
                for (final log in logs)
                  ActivityTile(
                    icon: Icons.receipt_long_outlined,
                    tone: Tone.info,
                    title: log.displayAction,
                    subtitle:
                        '${log.targetCollection}/${log.targetId} · ${log.actorEmail.isEmpty ? log.actorUid : log.actorEmail}${log.details.isNotEmpty ? ' — ${log.details}' : ''}',
                    timestamp: DateFormat('d MMM · HH:mm')
                        .format(log.createdAt.toLocal()),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
