// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.actionPrimary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.accent,
    onSecondary: AppColors.onPrimary,
    error: AppColors.dangerText,
    onError: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: 'IBMPlexSans',
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      displaySmall: AppText.display,
      headlineSmall: AppText.titleL,
      titleLarge: AppText.titleM,
      titleMedium: AppText.titleS,
      bodyLarge: AppText.bodyM,
      bodyMedium: AppText.bodyS,
      bodySmall: AppText.caption,
      labelLarge: AppText.button,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.textPrimary,
      selectionColor: AppColors.infoText.withValues(alpha: 0.2),
      selectionHandleColor: AppColors.textPrimary,
    ),
    dividerColor: AppColors.borderSubtle,
    iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
  );
}

/// Smooth, bouncy scrolling everywhere, including mouse and trackpad drags on web/desktop.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
