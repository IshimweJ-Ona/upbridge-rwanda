// Composes the shared theme, router, and application shell.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/app/router/app_router.dart';

class UpBridgeApp extends ConsumerWidget {
  const UpBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'UpBridge Rwanda',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,
      builder: (context, child) => BannerHost(
        onOpen: (route) => router.push(route),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
