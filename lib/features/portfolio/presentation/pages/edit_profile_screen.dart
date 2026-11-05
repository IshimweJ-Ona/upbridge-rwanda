// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// P6 · Edit profile.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _headline;
  late final TextEditingController _location;
  late final TextEditingController _about;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(appStoreProvider).user;
    _name = TextEditingController(text: u?.name ?? '');
    _headline = TextEditingController(text: u?.headline ?? '');
    _location = TextEditingController(text: u?.location ?? '');
    _about = TextEditingController(text: u?.about ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _location.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ref.read(appStoreProvider.notifier).updateProfile(name: _name.text, headline: _headline.text, location: _location.text, about: _about.text);
    showToast(context, 'Profile updated');
    _closeAfterFrame('/profile/portfolio?tab=about');
  }

  void _closeAfterFrame(String fallback) {
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) goBack(context, fallback: fallback);
    });
  }

  Future<void> _leave() async {
    if (!_dirty) {
      goBack(context, fallback: '/profile');
      return;
    }
    final discard = await showAppDialog(
      context,
      title: 'Discard your changes?',
      body: 'You’ve edited your profile but haven’t saved it.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
      icon: Icons.edit_off_outlined,
    );
    if (discard && mounted) _closeAfterFrame('/profile');
  }

  void _changed(String _) {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: DetailPage(
        title: 'Edit profile',
        onBack: _leave,
        backFallback: '/profile',
        footer: [AppButton('Save changes', loading: _saving, onPressed: _dirty ? _save : null)],
        children: [
          const SizedBox(height: 8),
          AppTextField(label: 'Full name', controller: _name, onChanged: _changed),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Headline',
            controller: _headline,
            helper: 'One line employers read first, e.g. “Junior frontend developer”.',
            inputFormatters: [LengthLimitingTextInputFormatter(80)],
            onChanged: _changed,
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Location', controller: _location, hint: 'District, e.g. Kigali · Gasabo', onChanged: _changed),
          const SizedBox(height: 16),
          AppTextField(
            label: 'About me',
            controller: _about,
            maxLines: 6,
            minLines: 4,
            trailingNote: '${_about.text.length}/300',
            inputFormatters: [LengthLimitingTextInputFormatter(300)],
            onChanged: (v) {
              _changed(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          const NoticeCard(
            icon: Icons.visibility_outlined,
            title: 'Who sees this',
            body: 'Your mentor, UpBridge admins and employers you apply to.',
          ),
        ],
      ),
    );
  }
}
