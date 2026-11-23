import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapaiko_ward/data/boundary_repository.dart';
import 'package:tapaiko_ward/data/settings_repository.dart';
import 'package:tapaiko_ward/l10n/app_localizations.dart';
import 'package:tapaiko_ward/ui/core/theme.dart';
import 'package:tapaiko_ward/ui/features/onboarding/views/onboarding_screen.dart';
import 'package:tapaiko_ward/ui/features/search/views/search_screen.dart';

import 'helpers/fixtures.dart';

Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      theme: buildTheme(Brightness.light),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  late SettingsRepository settings;
  late BoundaryRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await SettingsRepository.load();
    repo = testRepository();
    await repo.init();
  });

  testWidgets('onboarding explains location use and can be skipped',
      (tester) async {
    var done = false;
    await tester.pumpWidget(host(OnboardingScreen(
      settings: settings,
      onDone: () => done = true,
    )));

    expect(find.text('Know your ward, anywhere in Nepal'), findsOneWidget);
    expect(find.text('Allow location'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    expect(done, isTrue);
    expect(settings.onboardingDone, isTrue);
  });

  testWidgets('onboarding renders in Nepali', (tester) async {
    await tester.pumpWidget(host(
      OnboardingScreen(settings: settings, onDone: () {}),
      locale: const Locale('ne'),
    ));
    expect(find.text('स्थान अनुमति दिनुहोस्'), findsOneWidget);
  });

  testWidgets('search lists, filters and returns a selection', (tester) async {
    SearchSelection? picked;
    await tester.pumpWidget(host(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              picked = await Navigator.of(context).push<SearchSelection>(
                MaterialPageRoute(
                  builder: (_) => SearchScreen(repository: repo, settings: settings),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Hatuwagadhi'), findsOneWidget);
    expect(find.text('Kathmandu'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hatu 4');
    await tester.pump();
    expect(find.text('Kathmandu'), findsNothing);
    expect(find.text('Ward 4'), findsOneWidget);

    await tester.tap(find.text('Ward 4'));
    await tester.pumpAndSettle();
    expect(picked, isA<SelectMunicipality>());
    expect((picked! as SelectMunicipality).wardNo, '4');
  });

  testWidgets('search shows the empty state', (tester) async {
    await tester.pumpWidget(host(SearchScreen(repository: repo, settings: settings)));
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.textContaining('No places match'), findsOneWidget);
  });
}
