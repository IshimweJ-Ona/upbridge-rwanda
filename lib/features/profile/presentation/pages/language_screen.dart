import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/providers/settings_providers.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  static const options = [
    RadioOption(value: 'en', title: 'English', subtitle: 'Default language'),
    RadioOption(value: 'rw', title: 'Ikinyarwanda', subtitle: 'Kinyarwanda'),
    RadioOption(value: 'fr', title: 'Français', subtitle: 'French'),
  ];

  static String labelFor(String code) => options
      .firstWhere((o) => o.value == code, orElse: () => options.first)
      .title;

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String? _pickedLocale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final session = ref.watch(appSessionProvider).asData?.value;
    final fallback = session == null || !session.signedIn
        ? AppRoutes.welcome
        : homeRouteForSession(session);
    final selected = _pickedLocale ?? prefs.locale.languageCode;
    final isDark = prefs.themeMode == ThemeMode.dark;

    return DetailPage(
      title: '${l10n.languageTitle} & ${l10n.appearanceTitle}',
      backFallback: fallback,
      footer: [
        AppButton(
          l10n.save,
          onPressed: selected == prefs.locale.languageCode
              ? null
              : () async {
                  await ref
                      .read(appPreferencesProvider.notifier)
                      .setLocale(selected);
                  if (context.mounted) {
                    showToast(context, 'Language updated');
                    goBack(context, fallback: fallback);
                  }
                },
        ),
      ],
      children: [
        PageHeading(
          title: l10n.languageTitle,
          body: l10n.languageSelectBody,
        ),
        RadioCards<String>(
          options: LanguageScreen.options,
          value: selected,
          onChanged: (v) => setState(() => _pickedLocale = v),
        ),
        const SectionLabel('Appearance'),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(
                Icons.dark_mode_outlined,
                tone: Tone.info,
              ),
              title: l10n.darkModeLabel,
              subtitle: isDark ? 'Dark theme enabled' : 'Light / system theme',
              trailing: AppSwitch(
                value: isDark,
                onChanged: (dark) => ref
                    .read(appPreferencesProvider.notifier)
                    .setThemeMode(dark ? ThemeMode.dark : ThemeMode.light),
              ),
              chevron: false,
            ),
          ],
        ),
      ],
    );
  }
}
