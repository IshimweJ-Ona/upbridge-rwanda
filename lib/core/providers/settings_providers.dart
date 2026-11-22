import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';

class AppPreferencesState {
  const AppPreferencesState({
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.system,
  });

  final Locale locale;
  final ThemeMode themeMode;

  AppPreferencesState copyWith({Locale? locale, ThemeMode? themeMode}) =>
      AppPreferencesState(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
      );
}

class AppPreferencesController extends Notifier<AppPreferencesState> {
  static const _localeKey = 'upbridge.locale';
  static const _themeKey = 'upbridge.theme_mode';

  @override
  AppPreferencesState build() {
    _hydrate();
    return const AppPreferencesState();
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey) ?? 'en';
      final themeRaw = prefs.getString(_themeKey) ?? 'system';
      state = AppPreferencesState(
        locale: Locale(code),
        themeMode: _parseTheme(themeRaw),
      );
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    final normalized = switch (languageCode) {
      'rw' => 'rw',
      'fr' => 'fr',
      _ => 'en',
    };
    state = state.copyWith(locale: Locale(normalized));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, normalized);
      final uid = ref.read(appSessionProvider).asData?.value.uid;
      if (uid != null && uid.isNotEmpty) {
        await ref
            .read(userAccountRepositoryProvider)
            .updateSafeAccount(uid: uid, preferredLocale: normalized);
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {}
  }

  static ThemeMode _parseTheme(String raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesController, AppPreferencesState>(
      AppPreferencesController.new,
    );
