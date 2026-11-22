import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/splash/splash_screen.dart';
import 'package:upbridge/core/constants/app_routes.dart';

void main() {
  testWidgets('SVG brand logo and generated splash mark assets load offline', (
    tester,
  ) async {
    final svg = await rootBundle.loadString(
      'assets/images/upbridge_logo_on_dark.svg',
    );
    final splashPng = await rootBundle.load('assets/images/splash_mark.png');
    expect(svg, contains('<svg'));
    expect(splashPng.lengthInBytes, greaterThan(0));
  });

  testWidgets('splash renders cleanly on compact and wide viewports', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final size in [const Size(320, 568), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SplashScreen())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('splash-mark')), findsOneWidget);
    }
  });

  testWidgets('splash routes once after intro duration without flash', (
    tester,
  ) async {
    final destinations = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SplashScreen(
            duration: const Duration(milliseconds: 250),
            onNavigate: destinations.add,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('splash-mark')), findsOneWidget);
    expect(destinations, isEmpty);

    await tester.pump(const Duration(milliseconds: 250));
    expect(destinations, [AppRoutes.welcome]);

    await tester.pump(const Duration(seconds: 1));
    expect(destinations, [AppRoutes.welcome]);
  });
}
