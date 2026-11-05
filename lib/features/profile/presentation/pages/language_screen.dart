// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// S2 · Language.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  static const options = [
    RadioOption(value: 'en', title: 'English', subtitle: 'English'),
    RadioOption(value: 'rw', title: 'Ikinyarwanda', subtitle: 'Kinyarwanda'),
    RadioOption(value: 'fr', title: 'Français', subtitle: 'French'),
  ];

  static String labelFor(String code) => options.firstWhere((o) => o.value == code, orElse: () => options.first).title;

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  late String _code = ref.read(appStoreProvider).language;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(appStoreProvider.select((s) => s.language));
    return DetailPage(
      title: 'Language',
      backFallback: '/profile',
      footer: [
        AppButton(
          'Save language',
          onPressed: _code == current
              ? null
              : () {
                  ref.read(appStoreProvider.notifier).setLanguage(_code);
                  showToast(context, 'Language saved: ${LanguageScreen.labelFor(_code)}');
                  goBack(context, fallback: '/profile');
                },
        ),
      ],
      children: [
        const PageHeading(title: 'Choose your language', body: 'Used for the app, SMS updates and emails from UpBridge.'),
        RadioCards<String>(options: LanguageScreen.options, value: _code, onChanged: (v) => setState(() => _code = v)),
        const SizedBox(height: 18),
        const NoticeCard(
          icon: Icons.translate_rounded,
          title: 'Translations are being reviewed',
          body: 'During the pilot, screens stay in English until each translation has been checked by a native speaker. SMS updates switch right away.',
        ),
      ],
    );
  }
}
