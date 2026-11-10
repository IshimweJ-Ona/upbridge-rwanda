// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/app/app.dart';
import 'package:upbridge/app/firebase_unavailable_screen.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/shared/services/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await initFirebase();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  if (!firebaseReady) {
    runApp(const FirebaseUnavailableApp());
    return;
  }
  runApp(const ProviderScope(child: UpBridgeApp()));
}
