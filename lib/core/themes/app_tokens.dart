import 'package:flutter/material.dart';

/// 4/8px spacing grid tokens.
abstract final class Space {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;

  static const gutter = 16.0;
}

/// Consistent corner radii across cards, inputs, and sheets.
abstract final class Radii {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 18.0;

  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
}

/// Subtle 150-260ms motion scale respecting reduced-motion preferences.
abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 260);
  static const page = Duration(milliseconds: 240);

  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  static const stagger = Duration(milliseconds: 24);

  static Duration durationFor(BuildContext context, Duration desired) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return desired;
  }
}

/// Responsive layout breakpoints.
abstract final class Breakpoints {
  static const wide = 1024.0;
  static const contentMax = 720.0;
}
