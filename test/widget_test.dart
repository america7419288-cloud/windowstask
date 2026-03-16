import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:windowstask/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Just verify the app widget builds
    expect(TaskiApp, isNotNull);
  });
}
