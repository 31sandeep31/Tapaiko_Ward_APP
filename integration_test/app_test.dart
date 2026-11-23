import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapaiko_ward/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch shows onboarding, then the map', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Allow location'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Search municipality or district'), findsOneWidget);
    expect(find.text('Find your ward'), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsWidgets);
  });
}
