// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/features/profile/presentation/pages/language_screen.dart';

/// S1 · Profile & settings (tab root).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _sms = true;
  bool _dataSaver = false;

  Future<void> _logout() async {
    final ok = await showAppDialog(
      context,
      title: 'Log out of UpBridge?',
      body: 'Your work is saved. Log in again with your phone number and password.',
      confirmLabel: 'Log out',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (ok) ref.read(appStoreProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final user = data.user;
    if (user == null) return const SizedBox.shrink();
    final verified = data.projects.where((p) => p.verified).length;

    return PageFrame(
      largeTitle: 'Profile',
      eyebrow: user.phone,
      children: [
        const SizedBox(height: 16),
        SurfaceCard(
          onTap: () => context.go('/profile/portfolio'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(user.initials, tone: Tone.accent, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: AppText.titleM),
                        const SizedBox(height: 2),
                        Text(user.headline, style: AppText.bodyS, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.folder_special_outlined, size: 18, color: AppColors.link),
                  const SizedBox(width: 8),
                  Expanded(child: Text('My portfolio', style: AppText.bodySStrong.copyWith(color: AppColors.link))),
                  StatusBadge('$verified mentor-approved', tone: Tone.success, icon: Icons.verified_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatStrip([
          StatItem('', 'Projects', countTo: data.projects.length),
          StatItem('', 'Approved tasks', countTo: data.approvedCount),
          StatItem('', 'Applications', countTo: data.myApplications.length),
        ]),
        const SectionLabel('Your work'),
        ListGroup(
          children: [
            ListRow(leading: const IconTile(Icons.folder_open_rounded, tone: Tone.accent), title: 'My portfolio', onTap: () => context.go('/profile/portfolio')),
            ListRow(leading: const IconTile(Icons.person_outline_rounded, tone: Tone.accent), title: 'About me', onTap: () => context.go('/profile/portfolio?tab=about')),
            ListRow(leading: const IconTile(Icons.send_outlined, tone: Tone.info), title: 'My applications', onTap: () => context.go('/jobs/applications')),
            if (!data.isFirstDay)
              ListRow(leading: const IconTile(Icons.people_outline_rounded, tone: Tone.info), title: 'My mentorship', onTap: () => context.push('/my-mentorship')),
          ],
        ),
        const SectionLabel('Settings'),
        ListGroup(
          children: [
            ListRow(leading: const IconTile(Icons.edit_outlined), title: 'Edit profile', onTap: () => context.push('/profile-edit')),
            ListRow(
              leading: const IconTile(Icons.translate_rounded),
              title: 'Language',
              trailing: Text(LanguageScreen.labelFor(data.language), style: AppText.bodyS),
              onTap: () => context.push('/language'),
            ),
            ListRow(
              leading: const IconTile(Icons.sms_outlined),
              title: 'SMS updates',
              subtitle: 'Reviews, sessions and replies from employers',
              chevron: false,
              trailing: AppSwitch(value: _sms, onChanged: (v) => setState(() => _sms = v)),
              onTap: () => setState(() => _sms = !_sms),
            ),
            ListRow(
              leading: const IconTile(Icons.data_saver_on_outlined),
              title: 'Data saver',
              subtitle: 'Load images only on Wi-Fi',
              chevron: false,
              trailing: AppSwitch(value: _dataSaver, onChanged: (v) => setState(() => _dataSaver = v)),
              onTap: () => setState(() => _dataSaver = !_dataSaver),
            ),
          ],
        ),
        const SectionLabel('Help'),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.help_outline_rounded),
              title: 'How UpBridge works',
              onTap: () => showAppSheet<void>(context, title: 'How UpBridge works', builder: (_) => const _HowItWorks()),
            ),
            ListRow(
              leading: const IconTile(Icons.shield_outlined),
              title: 'Privacy and your data',
              onTap: () => showAppSheet<void>(context, title: 'Privacy and your data', builder: (_) => const _Privacy()),
            ),
            ListRow(
              leading: const IconTile(Icons.logout_rounded, tone: Tone.danger),
              title: 'Log out',
              titleStyle: AppText.bodyMStrong.copyWith(color: AppColors.dangerText),
              chevron: false,
              onTap: _logout,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(child: Text('UpBridge Rwanda · pilot build 1.0.0', style: AppText.caption)),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('01', 'Do practical tasks', 'Short tasks based on freeCodeCamp and MDN.'),
      ('02', 'Get mentor feedback', 'A working professional reviews each task against clear criteria.'),
      ('03', 'Build your portfolio', 'Approved work becomes evidence employers can check.'),
      ('04', 'Apply with proof', 'Attach that evidence when you apply for jobs, internships and gigs.'),
    ];
    return Column(
      children: [
        for (final s in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 34, child: Text(s.$1, style: AppText.dataMonoStrong.copyWith(color: AppColors.accentText))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(s.$2, style: AppText.bodyMStrong), Text(s.$3, style: AppText.bodyS)],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Privacy extends StatelessWidget {
  const _Privacy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your mentor sees the work you submit. Employers only see your profile, the projects you attach and your phone number after you apply. '
          'UpBridge handles personal data under Rwanda’s data protection law (Law No. 058/2021).',
          style: AppText.bodyM,
        ),
        const SizedBox(height: 16),
        AppButton('Got it', variant: ButtonVariant.secondary, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
