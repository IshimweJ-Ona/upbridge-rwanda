// Reusable transitions for modal dialogs and bottom sheets.
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

Widget dialogFadeScaleTransition(Animation<double> animation, Widget child) =>
    FadeScaleTransition(animation: animation, child: child);

Widget sheetSlideTransition(Animation<double> animation, Widget child) =>
    SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animation, child: child),
    );
