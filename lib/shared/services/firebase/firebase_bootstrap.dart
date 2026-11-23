// Initializes Firebase and connects Auth/Firestore emulators for opted-in debug runs.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:upbridge/shared/services/firebase/firebase_options.dart';

/// Resolves the emulator host for local debug devices and simulators.
String firebaseEmulatorHost({
  required bool isAndroid,
  String configuredHost = '',
}) {
  final host = configuredHost.trim();
  if (host.isNotEmpty) return host;
  return isAndroid ? '10.0.2.2' : '127.0.0.1';
}

/// Returns false when Firebase setup fails so startup can fail closed.
Future<bool> initFirebase() async {
  const useEmulators =
      kDebugMode && bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  try {
    if (Firebase.apps.isEmpty) {
      final envOptions = DefaultFirebaseOptions.currentPlatformOrNull;
      if (envOptions != null) {
        await Firebase.initializeApp(options: envOptions);
      } else {
        try {
          // Initialize from native google-services.json / GoogleServiceInfo.plist
          // when present locally.
          await Firebase.initializeApp();
        } catch (nativeError) {
          if (!useEmulators) rethrow;
          debugPrint(
            'Native Firebase config absent; using emulator options ($nativeError).',
          );
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.emulatorFallbackOptions(),
          );
        }
      }
    }
    if (useEmulators) {
      const configuredHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
      final host = firebaseEmulatorHost(
        isAndroid: defaultTargetPlatform == TargetPlatform.android,
        configuredHost: configuredHost,
      );
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    }
    return true;
  } catch (e) {
    debugPrint(
      'Firebase not ready ($e). Provide android/app/google-services.json, pass '
      '--dart-define-from-file=.env, or run with '
      '--dart-define=USE_FIREBASE_EMULATORS=true.',
    );
    return false;
  }
}
