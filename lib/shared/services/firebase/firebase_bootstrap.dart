// Initializes Firebase and connects emulators for opted-in debug runs.
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (kDebugMode && const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
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
    debugPrint('Firebase not ready: $e');
    return false;
  }
}
