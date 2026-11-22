import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/shared/shared.dart';

class AccountDeactivatedScreen extends ConsumerWidget {
  const AccountDeactivatedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const IconTile(
                    Icons.block_rounded,
                    tone: Tone.danger,
                    size: 56,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Account deactivated',
                    style: AppText.titleL.copyWith(color: p.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your UpBridge account has been deactivated by an administrator. Contact support if you believe this was in error.',
                    style: AppText.bodyM.copyWith(color: p.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    'Sign out',
                    variant: ButtonVariant.secondary,
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go(AppRoutes.welcome);
                    },
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
