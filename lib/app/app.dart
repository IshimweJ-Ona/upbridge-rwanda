import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/app/router/app_router.dart';
import 'package:upbridge/core/providers/settings_providers.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

class UpBridgeApp extends ConsumerWidget {
  const UpBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(appPreferencesProvider);
    return MaterialApp.router(
      title: 'UpBridge Rwanda',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: prefs.themeMode,
      locale: prefs.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlay =
            (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: isDark
              ? AppPalette.dark.surface
              : AppPalette.light.surface,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: BannerHost(
            onOpen: (route) => router.push(route),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
