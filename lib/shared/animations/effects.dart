// Owner: Student 5 · Core, shared, app shell, home & admin
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_tokens.dart';

/// Counts a number up from zero the first time it appears.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style, this.suffix = '', this.duration = const Duration(milliseconds: 900)});

  final int value;
  final TextStyle style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Motion.curve,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Shakes its child horizontally every time [trigger] changes (wrong password, invalid form).
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final dx = math.sin(_c.value * math.pi * 6) * 8 * (1 - _c.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Smoothly animates a fraction between 0 and 1 (progress bars, objective meters).
class AnimatedFraction extends StatelessWidget {
  const AnimatedFraction({super.key, required this.value, required this.builder});

  final double value;
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Motion.curve,
      builder: (context, v, _) => builder(context, v),
    );
  }
}
