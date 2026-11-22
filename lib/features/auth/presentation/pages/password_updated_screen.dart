// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

/// Password reset email sent.
class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return PageFrame(
      footer: [
        AppButton(
          l10n?.backToLoginCta ?? 'Back to log in',
          onPressed: () => context.go('/login'),
        ),
      ],
      children: [
        SuccessBlock(
          title: l10n?.resetEmailSentTitle ?? 'Reset email sent',
          body:
              l10n?.resetEmailSentBody ??
              'Open the password-reset link in your email, choose a new password, and then log in again.',
        ),
        const NoticeCard(
          icon: Icons.security_outlined,
          title: 'Security',
          body: 'For your security, password-reset links expire and can only be used once.',
        ),
      ],
    );
  }
}
