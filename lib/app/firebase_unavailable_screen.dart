// Owner: Student 5 - Core, shared, app shell, home & admin
import 'package:flutter/material.dart';

class FirebaseUnavailableApp extends StatelessWidget {
  const FirebaseUnavailableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UpBridge Rwanda',
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48),
                  SizedBox(height: 20),
                  Text(
                    'UpBridge could not connect to Firebase. Check the app configuration and try again.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
