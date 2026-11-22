import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.s5,
              Space.gutter,
              Space.s6,
            ),
            child: ConstrainedContent(
              maxWidth: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const UpBridgeLogo(
                        markWidth: 52,
                        onDark: true,
                        horizontal: true,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: l10n.languageTitle,
                        color: Colors.white.withValues(alpha: 0.9),
                        icon: const Icon(Icons.translate_rounded, size: 21),
                        onPressed: () => context.push(AppRoutes.language),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: Radii.rSm,
                    ),
                    child: MonoLabel(
                      'RWANDA YOUTH CAREER BRIDGE',
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                  Text(
                    'Turn what you learn into proof employers trust.',
                    style: AppText.display.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                  Text(
                    l10n.welcomeTagline,
                    style: AppText.bodyM.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: Space.s6),
                  AppButton(
                    l10n.createFreeAccount,
                    variant: ButtonVariant.onDark,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push(AppRoutes.signup),
                  ),
                  const SizedBox(height: Space.s3),
                  AppButton(
                    l10n.alreadyHaveAccount,
                    variant: ButtonVariant.outlineOnDark,
                    onPressed: () => context.push(AppRoutes.login),
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
