import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:account_book/widgets/animated_counter.dart';

void main() {
  testWidgets('AnimatedCounter renders final value after animation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedCounter(
            value: 1234.56,
            decimals: 2,
          ),
        ),
      ),
    );

    // Pump animation frames to let it reach final value
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('1234.56'), findsOneWidget);
  });

  testWidgets('AnimatedCounter shows prefix after animation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedCounter(
            value: 99.99,
            prefix: '¥',
            decimals: 2,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('¥99.99'), findsOneWidget);
  });

  testWidgets('AnimatedCounter shows zero with decimals', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedCounter(
            value: 0,
            decimals: 2,
          ),
        ),
      ),
    );

    // value=0 doesn't animate, so it shows immediately
    expect(find.text('0.00'), findsOneWidget);
  });
}
