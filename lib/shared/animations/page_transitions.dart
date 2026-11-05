// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_tokens.dart';

/// Drilling into detail: Material shared-axis slide + fade.
Page<void> slidePage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: Motion.page,
      reverseTransitionDuration: Motion.base,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: AppColors.canvas,
        child: child,
      ),
    );

/// Moving between peers (onboarding steps, auth steps): vertical shared axis.
Page<void> stepPage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: Motion.page,
      reverseTransitionDuration: Motion.base,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.vertical,
        fillColor: AppColors.canvas,
        child: child,
      ),
    );

/// Completion moments (sent, saved, approved): scaled shared axis.
Page<void> scalePage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: Motion.slow,
      reverseTransitionDuration: Motion.base,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.scaled,
        fillColor: AppColors.canvas,
        child: child,
      ),
    );

/// Switching role or area (welcome → home): fade through.
Page<void> fadePage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: Motion.slow,
      reverseTransitionDuration: Motion.base,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fillColor: AppColors.canvas,
        child: child,
      ),
    );

/// Role shells fade in and stay still while detail pages slide over them.
Page<void> shellPage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: Motion.slow,
      reverseTransitionDuration: Motion.base,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Motion.curve),
        child: child,
      ),
    );

/// Tab root pages inside a shell don't animate themselves — the shell cross-fades branches.
Page<void> tabPage(GoRouterState state, Widget child) => NoTransitionPage<void>(key: state.pageKey, name: state.name, child: child);
