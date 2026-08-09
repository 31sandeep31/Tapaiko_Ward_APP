import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:tapaiko_ward/l10n/app_localizations.dart';
import 'package:tapaiko_ward/src/data_service.dart';
import 'package:tapaiko_ward/src/search_screen.dart';

import '../helpers/fake_data_cache.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
import 'search_screen_test.mocks.dart';

const municipalities = [
  {
    'STATE_CODE': 1,
    'DISTRICT': 'BHOJPUR',
    'GaPa_NaPa': 'Hatuwagadhi',
    'Type_GN': 'Gaunpalika',
    'Province': 'Koshi Pradesh',
    'DISTRICT_CODE': 7,
    'MUNICIPALITY_CODE': 5,
  },
  {
    'STATE_CODE': 3,
    'DISTRICT': 'KATHMANDU',
    'GaPa_NaPa': 'Kathmandu',
    'Type_GN': 'Mahanagarpalika',
    'Province': 'Bagmati Pradesh',
    'DISTRICT_CODE': 27,
    'MUNICIPALITY_CODE': 1,
  },
];

Widget _host(FakeDataCache cache) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SearchScreen(
                    data: DataService(
                      client: MockClient(),
                      cache: cache,
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

void main() {
  late FakeDataCache cache;

  setUp(() {
    cache = FakeDataCache()
      ..store['locallevelcodes.json'] = jsonEncode(municipalities);
  });

  testWidgets('search screen lists municipalities and filters by query',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(cache));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Search municipality / ward'), findsOneWidget);
    expect(find.text('Hatuwagadhi'), findsOneWidget);
    expect(find.text('Kathmandu'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hatu');
    await tester.pump();

    expect(find.text('Hatuwagadhi'), findsOneWidget);
    expect(find.text('Kathmandu'), findsNothing);
  });

  testWidgets('search screen shows the empty state for no matches',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(cache));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('No matching municipalities.'), findsOneWidget);
  });

  testWidgets('selecting a municipality pops back with the selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(cache));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hatuwagadhi'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });
}
