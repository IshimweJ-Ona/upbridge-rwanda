import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';

ThemeData buildAppTheme() {
  const palette = AppPalette.light;
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: palette.actionPrimary,
    onPrimary: palette.onPrimary,
    secondary: palette.accent,
    onSecondary: palette.onPrimary,
    error: palette.dangerText,
    onError: palette.onPrimary,
    surface: palette.surface,
    onSurface: palette.textPrimary,
  );

  return _themeFrom(
    palette: palette,
    scheme: scheme,
    overlay: SystemUiOverlayStyle.dark,
  );
}

ThemeData buildDarkTheme() {
  const palette = AppPalette.dark;
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: palette.actionPrimary,
    onPrimary: palette.onPrimary,
    secondary: palette.accent,
    onSecondary: palette.onPrimary,
    error: palette.dangerText,
    onError: palette.onPrimary,
    surface: palette.surface,
    onSurface: palette.textPrimary,
  );

  return _themeFrom(
    palette: palette,
    scheme: scheme,
    overlay: SystemUiOverlayStyle.light,
  );
}

ThemeData _themeFrom({
  required AppPalette palette,
  required ColorScheme scheme,
  required SystemUiOverlayStyle overlay,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.canvas,
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
    visualDensity: VisualDensity.standard,
    extensions: [palette],
    textTheme: TextTheme(
      displaySmall: AppText.display.copyWith(color: palette.textPrimary),
      headlineSmall: AppText.titleL.copyWith(color: palette.textPrimary),
      titleLarge: AppText.titleM.copyWith(color: palette.textPrimary),
      titleMedium: AppText.titleS.copyWith(color: palette.textPrimary),
      bodyLarge: AppText.bodyM.copyWith(color: palette.textSecondary),
      bodyMedium: AppText.bodyS.copyWith(color: palette.textSecondary),
      bodySmall: AppText.caption.copyWith(color: palette.textMuted),
      labelLarge: AppText.button.copyWith(color: palette.textPrimary),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.textPrimary,
      selectionColor: palette.infoText.withValues(alpha: 0.25),
      selectionHandleColor: palette.textPrimary,
    ),
    dividerColor: palette.borderSubtle,
    dividerTheme: DividerThemeData(color: palette.borderSubtle, thickness: 1),
    iconTheme: IconThemeData(color: palette.textPrimary, size: 20),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: overlay,
      backgroundColor: palette.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: AppText.titleS.copyWith(color: palette.textPrimary),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.actionPrimary,
      linearTrackColor: palette.sunken,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      selectedColor: palette.actionPrimary,
      disabledColor: palette.sunken,
      checkmarkColor: palette.onPrimary,
      side: BorderSide(color: palette.borderSubtle),
      shape: const StadiumBorder(),
      labelStyle: AppText.bodySStrong.copyWith(color: palette.textPrimary),
      secondaryLabelStyle: AppText.bodySStrong.copyWith(
        color: palette.onPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: palette.infoSubtle,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return AppText.tab.copyWith(
          color: selected ? palette.actionPrimary : palette.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? palette.actionPrimary : palette.textSecondary,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.infoSubtle,
      selectedIconTheme: IconThemeData(color: palette.actionPrimary, size: 22),
      unselectedIconTheme: IconThemeData(
        color: palette.textSecondary,
        size: 22,
      ),
      selectedLabelTextStyle: AppText.tab.copyWith(
        color: palette.actionPrimary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: AppText.tab.copyWith(
        color: palette.textSecondary,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.rMd,
        side: BorderSide(color: palette.borderSubtle),
      ),
      textStyle: AppText.bodyS.copyWith(color: palette.textPrimary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.onPrimary;
        return palette.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.actionPrimary;
        return palette.sunken;
      }),
      trackOutlineColor: WidgetStateProperty.all(palette.borderStrong),
    ),
  );
}

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
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
