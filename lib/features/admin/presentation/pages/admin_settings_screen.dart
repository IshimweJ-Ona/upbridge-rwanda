// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// AD11 · Admin settings.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, String key, bool current) async {
    if (key == 'pauseSignups' && !current) {
      final ok = await showAppDialog(
        context,
        title: 'Pause new sign-ups?',
        body: 'People who already have an account can still log in. New visitors see a waiting-list message.',
        confirmLabel: 'Pause sign-ups',
        icon: Icons.pause_circle_outline_rounded,
      );
      if (!ok) return;
    }
    ref.read(appStoreProvider.notifier).toggleSetting(key);
    if (!context.mounted) return;
    final label = switch (key) {
      'replyBy' => current ? 'Reply-by date is now optional' : 'Reply-by date is required again',
      'pauseSignups' => current ? 'Sign-ups are open' : 'New sign-ups paused',
      _ => current ? 'Weekly report turned off' : 'Weekly report turned on',
    };
    showToast(context, label, icon: Icons.settings_rounded, tone: Tone.info);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showAppDialog(context, title: 'Log out?', confirmLabel: 'Log out', destructive: true, icon: Icons.logout_rounded);
    if (ok) ref.read(appStoreProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStoreProvider.select((s) => s.settings));
    final user = ref.watch(appStoreProvider.select((s) => s.user));

    Widget row(String key, IconData icon, String title, String subtitle) {
      final v = settings[key] ?? false;
      return ListRow(
        leading: IconTile(icon, tone: v ? Tone.info : Tone.neutral),
        title: title,
        subtitle: subtitle,
        chevron: false,
        trailing: AppSwitch(value: v, onChanged: (_) => _toggle(context, ref, key, v)),
        onTap: () => _toggle(context, ref, key, v),
      );
    }

    return PageFrame(
      largeTitle: 'Settings',
      eyebrow: user == null ? 'Admin' : '${user.name} · ${user.headline}',
      children: [
        const SectionLabel('Listings', top: 16),
        ListGroup(children: [row('replyBy', Icons.event_available_outlined, 'Require a reply-by date', 'Employers must commit to replying to every applicant')]),
        const SectionLabel('Sign-ups'),
        ListGroup(children: [row('pauseSignups', Icons.pause_circle_outline_rounded, 'Pause new sign-ups', 'Existing users can still log in')]),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: (settings['pauseSignups'] ?? false)
              ? const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: NoticeCard(tone: Tone.warning, icon: Icons.pause_circle_outline_rounded, title: 'Sign-ups are paused', body: 'New visitors can join a waiting list.'),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SectionLabel('Reports'),
        ListGroup(children: [row('weeklyReport', Icons.summarize_outlined, 'Weekly report by email', 'Every Monday at 08:00 to the pilot team')]),
        const SectionLabel('Pilot'),
        const KeyValueTable([
          ('Started', 'Mon 3 Aug 2026'),
          ('Ends', 'Mon 2 Nov 2026'),
          ('Districts', 'Gasabo, Kicukiro, Nyarugenge, Huye, Musanze, Rubavu'),
          ('Data', 'Handled under Law No. 058/2021 on personal data'),
        ]),
        const SectionLabel('Account'),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.logout_rounded, tone: Tone.danger),
              title: 'Log out',
              titleStyle: AppText.bodyMStrong.copyWith(color: AppColors.dangerText),
              chevron: false,
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}
