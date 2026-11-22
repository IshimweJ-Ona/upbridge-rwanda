import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/app.dart';

void main() {
  testWidgets('app opens on the animated SVG splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: UpBridgeApp()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('splash-mark')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
  });
}
