// Shows a safe startup message when Firebase cannot initialize.
import 'package:flutter/material.dart';
import 'package:upbridge/shared/shared.dart';

class FirebaseUnavailableApp extends StatelessWidget {
  const FirebaseUnavailableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UpBridge Rwanda',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppColors.infoSubtle,
                        borderRadius: Radii.rLg,
                      ),
                      child: const Icon(
                        Icons.cloud_off_outlined,
                        size: 28,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Connection unavailable',
                      style: AppText.titleL.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UpBridge could not connect to Firebase. Check your configuration and network connection, then reopen the app.',
                      style: AppText.bodyM.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
