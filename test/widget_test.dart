import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapaiko_ward/main.dart';

void main() {
  testWidgets('app boots and renders the map scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const TapaikoWardApp());
    await tester.pump();

    expect(find.text('TAPAIKO WARD'), findsOneWidget);
    expect(find.text('Find my ward'), findsOneWidget);

    // The map data fetch fails in the test env (no network/platform), so the
    // UI either shows the loading spinner or the retry error card.
    expect(
      find.byType(FloatingActionButton),
      findsWidgets,
    );
  });
}
