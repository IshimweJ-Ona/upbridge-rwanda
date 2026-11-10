// Owner: Student 5 · Core, shared, app shell, home & admin
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_tokens.dart';

/// Fades and slides a child up into place. Give list items increasing [index]
/// values for a staggered entrance.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
    this.duration = Motion.slow,
  });

  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  Timer? _delayTimer;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Motion.curve,
  );

  @override
  void initState() {
    super.initState();
    final delay = Motion.stagger * widget.index.clamp(0, 12);
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      _delayTimer = Timer(delay, () {
        _delayTimer = null;
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps each child in a [Reveal] with an increasing index.
List<Widget> staggered(List<Widget> children, {int start = 0}) => [
  for (var i = 0; i < children.length; i++)
    Reveal(index: start + i, child: children[i]),
];
