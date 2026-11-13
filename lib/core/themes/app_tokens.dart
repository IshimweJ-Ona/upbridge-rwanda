// Defines shared spacing, radius, and motion tokens.
import 'package:flutter/material.dart';

/// Spacing scale from the `space/*` variables.
abstract final class Space {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;

  /// Side gutter of every phone screen.
  static const gutter = 20.0;
}

/// Corner radii from the `radius/*` variables.
abstract final class Radii {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 20.0;

  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
}

/// One motion language for the whole app.
abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const page = Duration(milliseconds: 380);

  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
  static const exit = Curves.easeInCubic;

  /// Delay between items in a staggered list entrance.
  static const stagger = Duration(milliseconds: 45);
}

/// Width at which the shells switch from a bottom tab bar to a sidebar.
abstract final class Breakpoints {
  static const wide = 1024.0;
  static const contentMax = 720.0;
}
