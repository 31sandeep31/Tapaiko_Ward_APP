import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tapaiko_ward/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TAPAIKO WARD end-to-end', () {
    testWidgets('app boots and renders the main map screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TapaikoWardApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('TAPAIKO WARD'), findsOneWidget);
      expect(find.text('Find my ward'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });
  });
}
