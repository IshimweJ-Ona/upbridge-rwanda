import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/cloudinary_media_picker.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class EditProfileCvScreen extends ConsumerStatefulWidget {
  const EditProfileCvScreen({super.key});

  @override
  ConsumerState<EditProfileCvScreen> createState() =>
      _EditProfileCvScreenState();
}

class _EditProfileCvScreenState extends ConsumerState<EditProfileCvScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _headline = TextEditingController();
  final _location = TextEditingController();
  final _about = TextEditingController();
  final _links = TextEditingController();
  final _customSkill = TextEditingController();

  final Set<String> _skills = {};
  MediaAsset? _photoAsset;
  MediaAsset? _cvAsset;
  bool _hydrated = false;
  bool _phoneHydrated = false;
  bool _profileHydrationScheduled = false;
  bool _phoneHydrationScheduled = false;
  bool _builtOnce = false;
  bool _saving = false;
  String? _error;

  static const _suggestedSkills = [
    'Flutter',
    'Dart',
    'JavaScript',
    'React',
    'Python',
    'UI/UX Design',
    'Data Analysis',
    'Communication',
    'Teamwork',
  ];

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _headline,
      _location,
      _about,
      _links,
      _customSkill,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isSettled<T>(AsyncValue<T> value) =>
      !value.isLoading || value.hasValue || value.hasError;

  void _applyPhoneHydration(String? phone) {
    if (_phoneHydrated) return;
    _phoneHydrated = true;
    if (phone != null && phone.isNotEmpty) {
      _phone.text = phone.replaceFirst('+250', '').trim();
    }
  }

  void _applyProfileHydration(AppSession session, UserProfile? profile) {
    if (_hydrated) return;
    _hydrated = true;
    _name.text = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : (session.displayName ?? '');
    _location.text = profile?.location ?? 'Kigali, Rwanda';
    _headline.text = profile?.headline ?? '';
    _about.text = profile?.about ?? '';
    _links.text = (profile?.professionalLinks ?? const []).join('\n');
    _photoAsset = profile?.photoAsset;
    _cvAsset = profile?.cvAsset;
    _skills
      ..clear()
      ..addAll(profile?.skills ?? const []);
  }

  void _schedulePhoneHydration(String? phone) {
    if (_phoneHydrated || _phoneHydrationScheduled) return;
    _phoneHydrationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneHydrationScheduled = false;
      if (!mounted || _phoneHydrated) return;
      setState(() => _applyPhoneHydration(phone));
    });
  }

  void _scheduleProfileHydration(AppSession session, UserProfile? profile) {
    if (_hydrated || _profileHydrationScheduled) return;
    _profileHydrationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileHydrationScheduled = false;
      if (!mounted || _hydrated) return;
      setState(() => _applyProfileHydration(session, profile));
    });
  }

  void _hydrateOnce(
    AppSession session,
    UserProfile? profile,
    String? phone, {
    required bool profileReady,
    required bool accountReady,
    required bool deferred,
  }) {
    if (!_phoneHydrated && accountReady) {
      if (deferred) {
        _schedulePhoneHydration(phone);
      } else {
        _applyPhoneHydration(phone);
      }
    }
    if (!_hydrated && profileReady) {
      if (deferred) {
        _scheduleProfileHydration(session, profile);
      } else {
        _applyProfileHydration(session, profile);
      }
    }
  }

  static String _profileFallbackForSession(AppSession? session) {
    if (session == null || !session.signedIn) return AppRoutes.welcome;
    if (session.isApprovedMentor) return AppRoutes.mentorProfile;
    if (session.role == UserRole.mentor ||
        session.requiresMentorApprovalScreen) {
      return AppRoutes.mentorPending;
    }
    if (session.role == UserRole.admin) return AppRoutes.adminOverview;
    return AppRoutes.studentProfile;
  }

  Future<void> _save(AppSession session, UserProfile? existing) async {
    FocusScope.of(context).unfocus();
    final nameErr = Validators.fullName(_name.text);
    if (nameErr != null) {
      setState(() => _error = nameErr);
      return;
    }
    final phoneText = _phone.text.trim();
    if (phoneText.isNotEmpty) {
      final phoneErr = Validators.phone(phoneText);
      if (phoneErr != null) {
        setState(() => _error = phoneErr);
        return;
      }
    }
    final links = _links.text
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    for (final link in links) {
      final err = Validators.url(link);
      if (err != null) {
        setState(() => _error = 'Link "$link": $err');
        return;
      }
    }

    final uid = session.uid;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(userAccountRepositoryProvider)
          .updateSafeAccount(
            uid: uid,
            displayName: _name.text.trim(),
            phone: phoneText.isEmpty ? '' : '+250 $phoneText',
            photoAsset: _photoAsset,
            clearPhotoAsset: _photoAsset == null,
          );

      final now = DateTime.now().toUtc();
      final base =
          existing ??
          UserProfile(
            id: uid,
            ownerUid: uid,
            displayName: _name.text.trim(),
            headline: '',
            location: 'Kigali, Rwanda',
            about: '',
            createdAt: now,
            updatedAt: now,
          );

      await ref
          .read(userProfileRepositoryProvider)
          .upsertOwnProfile(
            base.copyWith(
              displayName: _name.text.trim(),
              headline: _headline.text.trim(),
              location: _location.text.trim(),
              about: _about.text.trim(),
              professionalLinks: links,
              photoAsset: _photoAsset,
              clearPhotoAsset: _photoAsset == null,
              cvAsset: _cvAsset,
              clearCvAsset: _cvAsset == null,
              skills: _skills.toList(growable: false),
              updatedAt: now,
            ),
          );
      if (mounted) {
        showToast(context, 'Profile & CV saved');
        goBack(context, fallback: _profileFallbackForSession(session));
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;
    final profileAsync = uid == null
        ? null
        : ref.watch(userProfileProvider(uid));
    final accountAsync = uid == null
        ? null
        : ref.watch(_editProfileAccountProvider(uid));
    final profile = profileAsync?.asData?.value;
    final account = accountAsync?.asData?.value;
    final profileReady = profileAsync == null || _isSettled(profileAsync);
    final accountReady = accountAsync == null || _isSettled(accountAsync);

    if (uid != null && session != null) {
      ref.listen(userProfileProvider(uid), (_, next) {
        if (!_hydrated && _isSettled(next) && mounted) {
          setState(() => _applyProfileHydration(session, next.asData?.value));
        }
      });
      ref.listen(_editProfileAccountProvider(uid), (_, next) {
        if (!_phoneHydrated && _isSettled(next) && mounted) {
          setState(() => _applyPhoneHydration(next.asData?.value?.phone));
        }
      });
      _hydrateOnce(
        session,
        profile,
        account?.phone,
        profileReady: profileReady,
        accountReady: accountReady,
        deferred: _builtOnce,
      );
    }
    _builtOnce = true;

    return DetailPage(
      title: l10n.editProfileCta,
      backFallback: _profileFallbackForSession(session),
      footer: [
        AppButton(
          'Save changes',
          loading: _saving,
          onPressed: session == null ? null : () => _save(session, profile),
        ),
      ],
      children: [
        if (_error != null) ...[
          NoticeCard(
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
            title: 'Could not save',
            body: _error!,
          ),
          const SizedBox(height: 12),
        ],
        if (uid != null) ...[
          CloudinaryMediaPicker(
            ownerUid: uid,
            label: 'Profile photo',
            category: 'avatars',
            imagesOnly: true,
            initialAsset: _photoAsset,
            helperText: 'Compressed client-side and uploaded via Cloudinary.',
            onAssetChanged: (asset) => setState(() => _photoAsset = asset),
          ),
          const SizedBox(height: 16),
        ],
        AppTextField(label: 'Full name', controller: _name),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Headline',
          hint: 'e.g. Junior Flutter & Cloud Developer',
          controller: _headline,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Location',
          hint: 'e.g. Kigali, Rwanda',
          controller: _location,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Phone number',
          trailingNote: 'Optional update',
          prefixText: '+250 ',
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
          ],
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'About me',
          hint: 'Summarize your background, interests, and career direction.',
          controller: _about,
          minLines: 3,
          maxLines: 5,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Professional links (one URL per line)',
          hint: 'https://linkedin.com/in/...\nhttps://github.com/...',
          controller: _links,
          maxLines: 2,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        Text(
          'Skills',
          style: AppText.bodySStrong.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in {..._suggestedSkills, ..._skills})
              SelectChip(
                label: s,
                selected: _skills.contains(s),
                onTap: () => setState(() {
                  if (_skills.contains(s)) {
                    _skills.remove(s);
                  } else if (_skills.length < 30) {
                    _skills.add(s);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Add another skill',
                controller: _customSkill,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: AppButton(
                'Add',
                size: ButtonSize.medium,
                variant: ButtonVariant.secondary,
                expand: false,
                onPressed: () {
                  final raw = _customSkill.text.trim();
                  if (raw.isNotEmpty && _skills.length < 30) {
                    setState(() {
                      _skills.add(raw);
                      _customSkill.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        if (uid != null) ...[
          const SizedBox(height: 16),
          CloudinaryMediaPicker(
            ownerUid: uid,
            label: 'Upload CV / Resume image snapshot (optional)',
            category: 'cv',
            imagesOnly: false,
            helperText: 'JPG, JPEG, PNG, or WebP image (max 10 MB).',
            initialAsset: _cvAsset,
            onAssetChanged: (asset) => setState(() => _cvAsset = asset),
          ),
        ],
      ],
    );
  }
}

final _editProfileAccountProvider = StreamProvider.autoDispose.family(
  (ref, String uid) =>
      ref.watch(userAccountRepositoryProvider).watchAccount(uid),
);
