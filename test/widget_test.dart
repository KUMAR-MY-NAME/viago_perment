// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packmate/main.dart';

void main() {
  testWidgets('App starts and shows SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Wait for the app to settle (e.g., SplashScreen animations)
    await tester.pumpAndSettle();

    // Verify that the MaterialApp title is present (or some text from SplashScreen)
    expect(find.text('Auth Phase 1'), findsOneWidget);
    // You might also want to check for specific widgets from SplashScreen
    // For example: expect(find.byType(SplashScreen), findsOneWidget);
  });
}
