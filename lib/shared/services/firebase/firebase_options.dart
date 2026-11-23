// Resolves Firebase options from `--dart-define` / `.env` values so fresh
// clones compile cleanly without a gitignored `lib/firebase_options.dart` file.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;

/// Platform Firebase options resolved from compile-time environment defines.
class DefaultFirebaseOptions {
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );

  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );

  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');

  static const _emulatorProjectId = 'upridge-rwanda-dev';

  /// Returns [FirebaseOptions] when configured via `--dart-define` / `.env`,
  /// or `null` so native builds fall back to `google-services.json` /
  /// `GoogleServiceInfo.plist`.
  static FirebaseOptions? get currentPlatformOrNull => fromEnvironment();

  /// Resolves platform [FirebaseOptions] from explicit environment strings.
  static FirebaseOptions? fromEnvironment({
    bool? isWeb,
    TargetPlatform? platform,
    String projectId = _projectId,
    String messagingSenderId = _messagingSenderId,
    String storageBucket = _storageBucket,
    String authDomain = _authDomain,
    String measurementId = _measurementId,
    String androidApiKey = _androidApiKey,
    String androidAppId = _androidAppId,
    String iosApiKey = _iosApiKey,
    String iosAppId = _iosAppId,
    String iosClientId = _iosClientId,
    String iosBundleId = _iosBundleId,
    String webApiKey = _webApiKey,
    String webAppId = _webAppId,
  }) {
    final web = isWeb ?? kIsWeb;
    final target = platform ?? defaultTargetPlatform;
    final trimmedProject = projectId.trim();
    final trimmedSender = messagingSenderId.trim();
    if (trimmedProject.isEmpty || trimmedSender.isEmpty) {
      return null;
    }
    final bucket = storageBucket.trim();

    if (web) {
      if (webApiKey.trim().isEmpty || webAppId.trim().isEmpty) return null;
      return FirebaseOptions(
        apiKey: webApiKey.trim(),
        appId: webAppId.trim(),
        messagingSenderId: trimmedSender,
        projectId: trimmedProject,
        authDomain: authDomain.trim().isEmpty ? null : authDomain.trim(),
        storageBucket: bucket.isEmpty ? null : bucket,
        measurementId:
            measurementId.trim().isEmpty ? null : measurementId.trim(),
      );
    }

    switch (target) {
      case TargetPlatform.android:
        if (androidApiKey.trim().isEmpty || androidAppId.trim().isEmpty) {
          return null;
        }
        return FirebaseOptions(
          apiKey: androidApiKey.trim(),
          appId: androidAppId.trim(),
          messagingSenderId: trimmedSender,
          projectId: trimmedProject,
          storageBucket: bucket.isEmpty ? null : bucket,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        if (iosApiKey.trim().isEmpty || iosAppId.trim().isEmpty) {
          return null;
        }
        return FirebaseOptions(
          apiKey: iosApiKey.trim(),
          appId: iosAppId.trim(),
          messagingSenderId: trimmedSender,
          projectId: trimmedProject,
          storageBucket: bucket.isEmpty ? null : bucket,
          iosClientId: iosClientId.trim().isEmpty ? null : iosClientId.trim(),
          iosBundleId: iosBundleId.trim().isEmpty ? null : iosBundleId.trim(),
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  /// Debug-only fallback options when running against local Firebase Emulators
  /// without local `google-services.json` or `.env` Firebase defines.
  static FirebaseOptions emulatorFallbackOptions({
    bool? isWeb,
    TargetPlatform? platform,
  }) {
    final web = isWeb ?? kIsWeb;
    final target = platform ?? defaultTargetPlatform;
    final appSuffix = web
        ? 'web:emulator'
        : (target == TargetPlatform.iOS || target == TargetPlatform.macOS
              ? 'ios:emulator'
              : 'android:emulator');
    return FirebaseOptions(
      apiKey: 'demo-emulator-api-key',
      appId: '1:710913599432:$appSuffix',
      messagingSenderId: '710913599432',
      projectId: _emulatorProjectId,
      authDomain: web ? '$_emulatorProjectId.firebaseapp.com' : null,
      storageBucket: '$_emulatorProjectId.firebasestorage.app',
    );
  }

  /// Resolves [FirebaseOptions] from environment or debug emulator defaults.
  static FirebaseOptions get currentPlatform {
    final resolved = currentPlatformOrNull;
    if (resolved != null) return resolved;
    if (kDebugMode && const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      return emulatorFallbackOptions();
    }
    throw StateError(
      'Firebase options are not configured. Provide '
      'android/app/google-services.json (or GoogleServiceInfo.plist), or pass '
      '--dart-define-from-file=.env.',
    );
  }
}
