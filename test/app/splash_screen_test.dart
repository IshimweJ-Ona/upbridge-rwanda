import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/app/splash/splash_screen.dart';

void main() {
  testWidgets('bundled splash photograph is available offline', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SplashScreen())),
    );
    final image = await rootBundle.load('assets/images/kigali_night.jpg');
    expect(image.lengthInBytes, greaterThan(0));
  });

  testWidgets('splash stays within compact and wide viewports', (tester) async {
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
      expect(find.byKey(const ValueKey('splash-background')), findsOneWidget);
    }
  });

  testWidgets('splash routes once after its configured duration', (
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

    expect(
      find.text('Turn what you learn into proof employers trust.'),
      findsOneWidget,
    );
    expect(destinations, isEmpty);

    await tester.pump(const Duration(milliseconds: 250));
    expect(destinations, ['/welcome']);

    await tester.pump(const Duration(seconds: 1));
    expect(destinations, ['/welcome']);
  });

  testWidgets('registration button shows its pending screen message', (
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

    await tester.tap(find.text('Create free account'));
    await tester.pump();
    expect(find.text('Waiting for registration screen'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(destinations, isEmpty);
  });

  testWidgets('login button shows its pending screen message', (tester) async {
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

    await tester.tap(find.text('I already have an account'));
    await tester.pump();
    expect(find.text('Waiting for login screen'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(destinations, isEmpty);
  });
}
