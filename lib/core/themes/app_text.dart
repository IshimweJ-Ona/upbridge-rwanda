// Defines reusable text styles for the product typography scale.
import 'package:flutter/material.dart';

/// Text styles from the Figma file (IBM Plex Sans for reading, IBM Plex Mono for evidence metadata).
/// Colors are left unset so styles inherit theme-aware colors (`light`/`dark`) automatically.
abstract final class AppText {
  static const _sans = 'IBMPlexSans';
  static const _mono = 'IBMPlexMono';

  static const display = TextStyle(
    fontFamily: _sans,
    fontSize: 25,
    height: 31 / 25,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w600,
  );
  static const titleL = TextStyle(
    fontFamily: _sans,
    fontSize: 21,
    height: 27 / 21,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
  );
  static const titleM = TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    height: 23 / 17,
    letterSpacing: -0.1,
    fontWeight: FontWeight.w600,
  );
  static const titleS = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
  );
  static const bodyM = TextStyle(
    fontFamily: _sans,
    fontSize: 14.5,
    height: 21 / 14.5,
    fontWeight: FontWeight.w400,
  );
  static const bodyMStrong = TextStyle(
    fontFamily: _sans,
    fontSize: 14.5,
    height: 21 / 14.5,
    fontWeight: FontWeight.w500,
  );
  static const bodyS = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
  static const bodySStrong = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );
  static const caption = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const button = TextStyle(
    fontFamily: _sans,
    fontSize: 14.5,
    height: 20 / 14.5,
    fontWeight: FontWeight.w600,
  );
  static const tab = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
  );

  /// Always rendered in capitals — use [MonoLabel], which uppercases the text.
  static const labelMono = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.6,
    fontWeight: FontWeight.w500,
  );
  static const dataMono = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
  static const dataMonoStrong = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );
  static const dataMonoL = TextStyle(
    fontFamily: _mono,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w500,
  );
}
