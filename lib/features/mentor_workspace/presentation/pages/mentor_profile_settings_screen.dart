import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/providers/settings_providers.dart';
import 'package:upbridge/core/widgets/cloudinary_media_picker.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorProfileSettingsScreen extends ConsumerStatefulWidget {
  const MentorProfileSettingsScreen({super.key});

  @override
  ConsumerState<MentorProfileSettingsScreen> createState() =>
      _MentorProfileSettingsScreenState();
}

class _MentorProfileSettingsScreenState
    extends ConsumerState<MentorProfileSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();
  final _availabilityCtrl = TextEditingController();
  final _maxMenteesCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _linksCtrl = TextEditingController();
  MediaAsset? _photoAsset;
  bool _clearPhoto = false;
  bool _isPublic = false;
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _expertiseCtrl.dispose();
    _yearsCtrl.dispose();
    _availabilityCtrl.dispose();
    _maxMenteesCtrl.dispose();
    _bioCtrl.dispose();
    _linksCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromProfile(UserProfile profile, String fallbackName) {
    if (_hydrated) return;
    _hydrated = true;
    _nameCtrl.text = profile.displayName.isNotEmpty
        ? profile.displayName
        : fallbackName;
    _headlineCtrl.text = profile.headline;
    _expertiseCtrl.text = profile.mentorExpertise.join(', ');
    _yearsCtrl.text = profile.mentorExperienceYears > 0
        ? '${profile.mentorExperienceYears}'
        : '';
    _availabilityCtrl.text = profile.mentorAvailability;
    _maxMenteesCtrl.text = '${profile.mentorMaxMentees}';
    _bioCtrl.text = profile.mentorBio.isNotEmpty
        ? profile.mentorBio
        : profile.about;
    _linksCtrl.text = profile.professionalLinks.join('\n');
    _photoAsset = profile.photoAsset;
    _isPublic = profile.isMentorPublic;
  }

  Future<void> _saveSettings(String uid) async {
    FocusScope.of(context).unfocus();
    final displayName = _nameCtrl.text.trim();
    if (displayName.isEmpty) {
      showToast(context, 'Enter your display name.', tone: Tone.warning);
      return;
    }

    final links = _linksCtrl.text
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    for (final link in links) {
      final err = Validators.url(link);
      if (err != null) {
        showToast(context, 'Link "$link": $err', tone: Tone.warning);
        return;
      }
    }

    final expertise = _expertiseCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final years = (int.tryParse(_yearsCtrl.text.trim()) ?? 1).clamp(0, 60);
    final maxMentees = (int.tryParse(_maxMenteesCtrl.text.trim()) ?? 5).clamp(
      1,
      50,
    );

    setState(() => _saving = true);
    try {
      await ref
          .read(userProfileRepositoryProvider)
          .updateMentorProfileSettings(
            uid: uid,
            displayName: displayName,
            headline: _headlineCtrl.text.trim(),
            expertise: expertise,
            experienceYears: years,
            availability: _availabilityCtrl.text.trim(),
            maxMentees: maxMentees,
            bio: _bioCtrl.text.trim(),
            professionalLinks: links,
            photoAsset: _photoAsset,
            clearPhotoAsset: _clearPhoto,
            isMentorPublic: _isPublic,
          );
      await ref.read(userAccountRepositoryProvider).updateSafeAccount(
            uid: uid,
            displayName: displayName,
            photoAsset: _photoAsset,
            clearPhotoAsset: _clearPhoto,
          );
      if (mounted) showToast(context, 'Mentor profile updated');
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showAppDialog(
      context,
      title: 'Sign out?',
      body: 'You will need to sign in again to access your mentor workspace.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirm || !mounted) return;
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;
    final prefs = ref.watch(appPreferencesProvider);

    if (session == null || uid == null) {
      return PageFrame(
        largeTitle: l10n.tabProfile,
        children: const [SizedBox(height: 16), SkeletonDashboardLoader()],
      );
    }

    final profileAsync = ref.watch(userProfileProvider(uid));

    return PageFrame(
      largeTitle: session.displayLabel,
      subtitle: '${l10n.roleMentor} · Mentor directory & preferences',
      onRefresh: () async => ref.invalidate(userProfileProvider(uid)),
      children: [
        const SizedBox(height: 12),
        profileAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 2),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load profile',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(userProfileProvider(uid)),
          ),
          data: (profile) {
            if (profile != null) {
              _hydrateFromProfile(profile, session.displayName ?? '');
            } else if (!_hydrated) {
              _hydrated = true;
              _nameCtrl.text = session.displayName ?? '';
              _maxMenteesCtrl.text = '5';
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SurfaceCard(
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Visible in mentor directory',
                      style: AppText.titleS.copyWith(color: p.textPrimary),
                    ),
                    subtitle: Text(
                      'Allow students to discover your profile and send requests.',
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v),
                  ),
                ),
                const SizedBox(height: 12),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CloudinaryMediaPicker(
                        ownerUid: uid,
                        label: 'Profile photo',
                        helperText: 'Visible to students browsing mentors.',
                        category: 'profile-photos',
                        initialAsset: _photoAsset,
                        onAssetChanged: (asset) => setState(() {
                          _photoAsset = asset;
                          _clearPhoto = asset == null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Full name',
                        hint: 'Your public display name',
                        controller: _nameCtrl,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Professional headline',
                        hint: 'e.g. Senior Mobile Engineer · Kigali',
                        controller: _headlineCtrl,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Areas of expertise (comma-separated)',
                        hint: 'Flutter, Product Design, Career Coaching',
                        controller: _expertiseCtrl,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Years exp.',
                              hint: '4',
                              controller: _yearsCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              label: 'Max mentees',
                              hint: '5',
                              controller: _maxMenteesCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Availability',
                        hint: 'e.g. Weekdays 18:00–20:00 EAT',
                        controller: _availabilityCtrl,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Mentoring bio',
                        hint: 'Share what topics and projects you coach students on.',
                        controller: _bioCtrl,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Professional links (one URL per line)',
                        hint: 'https://linkedin.com/in/...\nhttps://github.com/...',
                        controller: _linksCtrl,
                        maxLines: 2,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        l10n.save,
                        loading: _saving,
                        onPressed: () => _saveSettings(uid),
                      ),
                    ],
                  ),
                ),
                const SectionLabel('CV, portfolio & app settings'),
                ListGroup(
                  children: [
                    ListRow(
                      leading: const IconTile(
                        Icons.badge_outlined,
                        tone: Tone.info,
                      ),
                      title: 'Edit full CV & photo',
                      subtitle:
                          'Photo, headline, education, experience & CV PDF',
                      chevron: true,
                      onTap: () => context.push('/profile-edit'),
                    ),
                    ListRow(
                      leading: const IconTile(
                        Icons.translate_rounded,
                        tone: Tone.neutral,
                      ),
                      title: l10n.languageTitle,
                      subtitle: switch (prefs.locale.languageCode) {
                        'rw' => 'Ikinyarwanda',
                        'fr' => 'Français',
                        _ => 'English',
                      },
                      chevron: true,
                      onTap: () => context.push('/language'),
                    ),
                    ListRow(
                      leading: const IconTile(
                        Icons.dark_mode_outlined,
                        tone: Tone.info,
                      ),
                      title: l10n.darkModeLabel,
                      subtitle: prefs.themeMode == ThemeMode.dark
                          ? 'Dark surface palette active'
                          : 'Clean light palette active',
                      trailing: Switch.adaptive(
                        value: prefs.themeMode == ThemeMode.dark,
                        onChanged: (dark) => ref
                            .read(appPreferencesProvider.notifier)
                            .setThemeMode(
                              dark ? ThemeMode.dark : ThemeMode.light,
                            ),
                      ),
                      onTap: () => ref
                          .read(appPreferencesProvider.notifier)
                          .setThemeMode(
                            prefs.themeMode == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  l10n.signOut,
                  variant: ButtonVariant.dangerOutline,
                  onPressed: _signOut,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
