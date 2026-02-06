
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arva/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Await an asynchronous operation.
    await tester.pumpWidget(const MyApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Await an asynchronous operation.
    await tester.tap(find.byIcon(Icons.add));
    // Await an asynchronous operation.
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
