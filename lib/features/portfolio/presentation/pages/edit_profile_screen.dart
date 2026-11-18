import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/profile/presentation/providers/profile_providers.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;
  bool _dirty = false;
  XFile? _photo;
  bool _removePhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).value;
    _name = TextEditingController(text: profile?.displayName ?? '');
    _phone = TextEditingController(
      text: profile?.phone.replaceFirst('+250 ', '') ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = ref.read(currentProfileProvider).value;
    final phoneError = Validators.phone(_phone.text);
    if (profile == null ||
        Validators.fullName(_name.text) != null ||
        phoneError != null) {
      setState(() => _error = phoneError ?? 'Enter your full name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? photoUrl = profile.photoUrl;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        final name = _photo!.name.toLowerCase();
        final contentType = name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
        final asset = await ref
            .read(storageServiceProvider)
            .upload(
              path: 'users/${profile.uid}/profile-$name',
              bytes: bytes,
              contentType: contentType,
            );
        photoUrl = asset.secureUrl.toString();
      } else if (_removePhoto) {
        photoUrl = null;
      }
      await ref
          .read(profileRepositoryProvider)
          .update(
            profile.copyWith(
              displayName: _name.text.trim(),
              phone: '+250 ${_phone.text.trim()}',
              photoUrl: photoUrl,
            ),
          );
      if (mounted) {
        showToast(
          context,
          'Profile changes saved',
          icon: Icons.check_circle_rounded,
        );
        goBack(context, fallback: '/profile');
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    return DetailPage(
      title: 'Edit profile',
      onBack: () => goBack(context, fallback: '/profile'),
      backFallback: '/profile',
      footer: [
        AppButton(
          'Save changes',
          loading: _saving,
          onPressed: _dirty ? _save : null,
        ),
      ],
      children: [
        if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.dangerText)),
        ImagePickerField(
          initialImageUrl: profile?.photoUrl,
          onChanged: (photo) => setState(() {
            _photo = photo;
            _removePhoto = photo == null;
            _dirty = true;
          }),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Full name',
          controller: _name,
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Phone number',
          controller: _phone,
          prefixText: '+250 ',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
          ],
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: 16),
        const NoticeCard(
          icon: Icons.lock_outline_rounded,
          title: 'Account permissions',
          body: 'Role and account status are managed by UpBridge and cannot be changed here.',
        ),
      ],
    );
  }
}
