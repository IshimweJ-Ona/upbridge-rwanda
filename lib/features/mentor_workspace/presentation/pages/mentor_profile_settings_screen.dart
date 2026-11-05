// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/features/profile/presentation/pages/language_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_home_screen.dart';

/// MP1 · Mentor profile and availability.
class MentorProfileSettingsScreen extends ConsumerStatefulWidget {
  const MentorProfileSettingsScreen({super.key});

  @override
  ConsumerState<MentorProfileSettingsScreen> createState() => _MentorProfileSettingsScreenState();
}

class _MentorProfileSettingsScreenState extends ConsumerState<MentorProfileSettingsScreen> {
  late final Map<String, bool> _slots = {
    'Tuesday · 18:00–20:00': !_isNew,
    'Thursday · 18:00–20:00': !_isNew,
    'Saturday · 10:00–12:00': false,
  };
  late bool _accepting = !_isNew;

  bool get _isNew => ref.read(appStoreProvider).user?.isNewMentor ?? false;

  Future<void> _logout() async {
    final ok = await showAppDialog(
      context,
      title: 'Log out?',
      body: 'Your reviews and notes are saved.',
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
    final isAlice = user.id == 'alice';
    final mentor = isAlice ? data.mentor('alice') : null;
    final open = _slots.values.where((v) => v).length;

    return PageFrame(
      largeTitle: 'Profile',
      eyebrow: user.phone,
      children: [
        const SizedBox(height: 16),
        SurfaceCard(
          child: Row(
            children: [
              AppAvatar(user.initials, tone: Tone.accent, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppText.titleM),
                    Text(user.headline, style: AppText.bodyS),
                    const SizedBox(height: 6),
                    StatusBadge(isAlice ? 'Verified mentor since 28 Jul' : 'Verified 16 Oct', tone: Tone.success, icon: Icons.verified_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatStrip([
          StatItem('', 'Reviews', countTo: isAlice ? data.reviewedCount : 0),
          StatItem(isAlice ? '1.4 d' : '—', 'Median reply'),
          StatItem('', 'Mentees', countTo: isAlice ? data.mentees.length : 0),
        ]),
        SectionLabel('Availability · $open ${open == 1 ? 'slot' : 'slots'} a week'),
        ListGroup(
          children: [
            for (final e in _slots.entries)
              ListRow(
                leading: const IconTile(Icons.schedule_rounded, tone: Tone.info),
                title: e.key,
                chevron: false,
                trailing: AppSwitch(value: e.value, onChanged: (v) => setState(() => _slots[e.key] = v)),
                onTap: () => setState(() => _slots[e.key] = !e.value),
              ),
            ListRow(
              leading: const IconTile(Icons.person_add_alt_outlined, tone: Tone.accent),
              title: 'Accepting new mentees',
              subtitle: _accepting ? 'You appear in the Mentors list' : 'Hidden from new youth',
              chevron: false,
              trailing: AppSwitch(value: _accepting, onChanged: (v) => setState(() => _accepting = v)),
              onTap: () => setState(() => _accepting = !_accepting),
            ),
          ],
        ),
        const SectionLabel('Expertise'),
        TagWrap(mentor?.skills ?? const ['Excel', 'SQL', 'Reporting'], tone: Tone.info),
        const SectionLabel('Account'),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.translate_rounded),
              title: 'Language',
              trailing: Text(LanguageScreen.labelFor(data.language), style: AppText.bodyS),
              onTap: () => context.push('/language'),
            ),
            ListRow(
              leading: const IconTile(Icons.menu_book_outlined),
              title: 'Review guide',
              onTap: () => showAppSheet<void>(context, title: 'Review guide', builder: (_) => const ReviewGuide()),
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
      ],
    );
  }
}
