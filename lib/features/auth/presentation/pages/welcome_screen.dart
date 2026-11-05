// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';

/// A1 · Welcome — Kigali Convention Centre at night under a navy scrim.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _kenBurns = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat(reverse: true);

  @override
  void dispose() {
    _kenBurns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.inverse,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _kenBurns,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_kenBurns.value);
                return Transform.scale(
                  scale: 1.04 + 0.08 * t,
                  alignment: Alignment(-0.3 + 0.6 * t, -0.2),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/kigali_night.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B4A7A), AppColors.inverse]),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.42, 0.72, 1.0],
                  colors: [
                    AppColors.inverse.withValues(alpha: 0.25),
                    AppColors.inverse.withValues(alpha: 0.45),
                    AppColors.inverse.withValues(alpha: 0.92),
                    AppColors.inverse.withValues(alpha: 0.98),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, 16, Space.gutter, 20),
                child: ConstrainedContent(
                  maxWidth: 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Reveal(child: UpBridgeLogo(markWidth: 52, onDark: true, horizontal: true)),
                      const Spacer(),
                      Reveal(
                        index: 2,
                        child: MonoLabel('Free for young people in Rwanda', color: AppColors.textInverse.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(height: 12),
                      Reveal(
                        index: 3,
                        offset: 22,
                        child: Text(
                          'Turn practical work into proof employers trust.',
                          style: AppText.display.copyWith(color: AppColors.textInverse, fontSize: 32, height: 38 / 32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Reveal(
                        index: 4,
                        child: Text(
                          'Do real tasks, get feedback from working mentors, build a portfolio and apply with evidence.',
                          style: AppText.bodyM.copyWith(color: AppColors.textInverse.withValues(alpha: 0.85)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Reveal(
                        index: 6,
                        offset: 28,
                        child: AppButton(
                          'Create free account',
                          variant: ButtonVariant.onDark,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => context.push('/signup'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Reveal(
                        index: 7,
                        offset: 28,
                        child: AppButton(
                          'I already have an account',
                          variant: ButtonVariant.outlineOnDark,
                          onPressed: () => context.push('/login'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Reveal(
                        index: 8,
                        child: Center(
                          child: Text(
                            'Kigali Convention Centre at night',
                            style: AppText.caption.copyWith(color: AppColors.textInverse.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
