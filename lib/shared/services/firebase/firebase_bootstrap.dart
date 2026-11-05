// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:upbridge/shared/services/firebase/firebase_options.dart';

/// Returns false when Firebase isn't configured yet, so the app still opens with demo data.
Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return true;
  } catch (e) {
    debugPrint('Firebase not ready: $e');
    return false;
  }
}
