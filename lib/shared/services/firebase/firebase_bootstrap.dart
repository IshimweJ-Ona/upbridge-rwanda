// Initializes Firebase and connects emulators for opted-in debug runs.
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:upbridge/shared/services/firebase/firebase_options.dart';

/// Returns false when Firebase isn't configured yet, so the app still opens with demo data.
Future<bool> initFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (kDebugMode && const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      final host = defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : '127.0.0.1';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    }
    return true;
  } catch (e) {
    debugPrint('Firebase not ready: $e');
    return false;
  }
}
