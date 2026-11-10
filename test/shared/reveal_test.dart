import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/shared/animations/reveal.dart';

void main() {
  testWidgets('cancels a stagger timer when disposed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Reveal(index: 12, child: Text('content'))),
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
