// Basic widget test for Grid Survival Simulator

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:grid_survival_simulator/main.dart';

void main() {
  testWidgets('App renders quick calculator screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: GridSurvivalApp(),
      ),
    );

    // Verify that the quick calculator screen is displayed
    expect(find.text('Grid Survival Simulator'), findsOneWidget);
    expect(find.text('Symbol'), findsOneWidget);
    expect(find.text('Balance (USD)'), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
  });

  testWidgets('App shows disclaimer', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GridSurvivalApp(),
      ),
    );

    // Verify disclaimer is shown
    expect(
      find.text('Analytical/educational tool. Not financial advice. Actual broker outcome may differ.'),
      findsOneWidget,
    );
  });
}
