import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_dependencies.dart';
import 'l10n/app_localizations.dart';
import 'ui/core/theme.dart';
import 'ui/features/map/views/map_screen.dart';
import 'ui/features/onboarding/views/onboarding_screen.dart';

class TapaikoWardApp extends StatefulWidget {
  const TapaikoWardApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<TapaikoWardApp> createState() => _TapaikoWardAppState();
}

class _TapaikoWardAppState extends State<TapaikoWardApp> {
  late bool _showOnboarding = !widget.deps.settings.onboardingDone;

  @override
  Widget build(BuildContext context) {
    final settings = widget.deps.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: settings.locale,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: settings.themeMode,
        // Transparent system bars everywhere (edge-to-edge); screens with
        // their own needs (the map) override this.
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
            ),
            child: child!,
          );
        },
        home: AnimatedSwitcher(
          duration: Motion.long,
          child: _showOnboarding
              ? OnboardingScreen(
                  key: const ValueKey('onboarding'),
                  settings: settings,
                  onDone: () => setState(() => _showOnboarding = false),
                )
              : MapScreen(key: const ValueKey('map'), deps: widget.deps),
        ),
      ),
    );
  }
}
