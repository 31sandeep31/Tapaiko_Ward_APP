import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'src/map_screen.dart';

void main() {
  runApp(const TapaikoWardApp());
}

class TapaikoWardApp extends StatelessWidget {
  const TapaikoWardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAPAIKO WARD',
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ne'),
      ],
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF003893),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
