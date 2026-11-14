// Collects details for the admin add-user workflow.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/features/auth/domain/validators.dart';

/// AD3 · Add user (sends an SMS invitation).
class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _district = TextEditingController();
  Role _role = Role.youth;
  bool _invite = true;
  bool _tried = false;
  bool _saving = false;
  int _shake = 0;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _district.dispose();
    super.dispose();
  }

  String? get _nameError => _tried && _name.text.trim().length < 3 ? 'Enter their full name.' : null;
  String? get _phoneError => _tried ? Validators.phone(_phone.text) : null;
  String? get _districtError => _tried && _district.text.trim().isEmpty ? 'Enter a district, e.g. Kicukiro.' : null;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (_nameError != null || _phoneError != null || _districtError != null) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    ref.read(appStoreProvider.notifier).addUser(
          PlatformUser(
            id: 'u-${DateTime.now().millisecondsSinceEpoch}',
            name: _name.text.trim(),
            role: _role,
            phone: '+250 ${_phone.text.trim()}',
            district: _district.text.trim(),
            joined: 'Added today',
            status: _invite ? 'Invited' : 'Active',
            detail: _role == Role.mentor ? 'Needs background checks' : 'New account',
          ),
        );
    showToast(context, _invite ? 'Invitation sent by SMS to ${_name.text.trim().split(' ').first}' : 'User added');
    goBack(context, fallback: '/a/users');
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Add user',
      closeIcon: true,
      backFallback: '/a/users',
      footer: [AppButton('Add user', loading: _saving, onPressed: _save)],
      children: [
        const PageHeading(title: 'Add someone to the pilot', body: 'They get an SMS with a link to set their password.'),
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(label: 'Full name', controller: _name, error: _nameError, onChanged: (_) => _refresh()),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone number',
                controller: _phone,
                prefixText: '+250 ',
                hint: '788 123 456',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(11)],
                error: _phoneError,
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'District', controller: _district, hint: 'e.g. Kicukiro', error: _districtError, onChanged: (_) => _refresh()),
            ],
          ),
        ),
        const SectionLabel('Role'),
        RadioCards<Role>(
          value: _role,
          onChanged: (v) => setState(() => _role = v),
          options: const [
            RadioOption(value: Role.youth, title: 'Youth', subtitle: 'Learns, builds a portfolio and applies', icon: Icons.school_outlined),
            RadioOption(value: Role.mentor, title: 'Mentor', subtitle: 'Reviews work · needs 4 background checks first', icon: Icons.verified_user_outlined),
            RadioOption(value: Role.admin, title: 'Admin', subtitle: 'Full access to the pilot workspace', icon: Icons.admin_panel_settings_outlined),
          ],
        ),
        const SizedBox(height: 18),
        CheckRow(label: 'Send the SMS invitation now', value: _invite, onChanged: (v) => setState(() => _invite = v)),
      ],
    );
  }

  void _refresh() {
    if (_tried) setState(() {});
  }
}
