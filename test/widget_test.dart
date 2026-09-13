// Minimal smoke test: boots the real app entrypoint and verifies it
// renders a frame without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:tally/main.dart' as app;

void main() {
  testWidgets('App starts without throwing', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
  });
}
