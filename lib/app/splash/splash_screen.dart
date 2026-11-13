// Launch-only welcome splash, shown before the router resolves the destination.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/core/constants/app_constants.dart';
import 'package:upbridge/shared/shared.dart';

const splashDuration = AppConstants.splashDuration;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = splashDuration,
    this.onNavigate,
  });

  final Duration duration;

  /// Optional navigation hook used by focused widget tests.
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _kenBurns = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat(reverse: true);
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Timer _timer;
  bool _hasNavigated = false;
  String? _pendingScreen;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _finish);
  }

  void _finish() {
    if (!mounted || _hasNavigated) return;

    final initialized = Firebase.apps.isNotEmpty;
    final firebaseUser = initialized ? FirebaseAuth.instance.currentUser : null;
    final destination = splashDestination(
      firebaseInitialized: initialized,
      firebaseSignedIn: firebaseUser != null,
      emailVerified: firebaseUser?.emailVerified ?? false,
      appUser: ref.read(appStoreProvider).user,
    );
    _navigateOnce(destination);
  }

  void _navigateOnce(String destination) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _timer.cancel();
    final onNavigate = widget.onNavigate;
    if (onNavigate != null) {
      onNavigate(destination);
    } else {
      context.go(destination);
    }
  }

  // Keep auth entry points on the splash until their owner connects the flows.
  void _showPendingScreen(String screen) {
    if (!mounted) return;
    _timer.cancel();
    setState(() => _pendingScreen = screen);
  }

  @override
  void dispose() {
    _timer.cancel();
    _kenBurns.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topSpace = (size.height * 0.32).clamp(72.0, 290.0);

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
                  scale: 1.03 + 0.07 * t,
                  alignment: Alignment(-0.25 + 0.5 * t, -0.2),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/kigali_night.jpg',
                key: const ValueKey('splash-background'),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2B4A7A), AppColors.inverse],
                    ),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.36, 0.65, 1],
                  colors: [
                    Color(0x3313294B),
                    Color(0x6613294B),
                    Color(0xEB13294B),
                    Color(0xFA13294B),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    14,
                    Space.gutter,
                    20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 34,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _intro,
                            curve: Curves.easeOut,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: topSpace),
                              const UpBridgeLogo(
                                markWidth: 52,
                                onDark: true,
                                horizontal: true,
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Turn what you learn into proof employers trust.',
                                style: AppText.display.copyWith(
                                  color: AppColors.textInverse,
                                  fontSize: size.width < 360 ? 28 : 32,
                                  height: 1.18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Practical tasks, feedback from working professionals, and a portfolio that gets you to internships and jobs in Rwanda.',
                                style: AppText.bodyM.copyWith(
                                  color: AppColors.textInverse.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              AppButton(
                                'Create free account',
                                variant: ButtonVariant.onDark,
                                onPressed: () =>
                                    _showPendingScreen('registration'),
                              ),
                              const SizedBox(height: 10),
                              AppButton(
                                'I already have an account',
                                variant: ButtonVariant.outlineOnDark,
                                onPressed: () => _showPendingScreen('login'),
                              ),
                              if (_pendingScreen case final pendingScreen?) ...[
                                const SizedBox(height: 12),
                                Center(
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      'Waiting for $pendingScreen screen',
                                      key: const ValueKey(
                                        'pending-auth-screen',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: AppText.bodyS.copyWith(
                                        color: AppColors.textInverse.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Center(
                                child: Text(
                                  'PROTOTYPE  ·  ALL DATA IS SAMPLE DATA',
                                  textAlign: TextAlign.center,
                                  style: AppText.caption.copyWith(
                                    color: AppColors.textInverse.withValues(
                                      alpha: 0.48,
                                    ),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
