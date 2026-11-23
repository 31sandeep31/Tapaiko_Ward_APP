import 'package:flutter/material.dart';

import '../../../../data/location_service.dart';
import '../../../../data/settings_repository.dart';
import '../../../core/app_logo.dart';
import '../../../core/formatting.dart';
import '../../../core/theme.dart';

/// First-run welcome with the location "prominent disclosure" shown before
/// the system permission prompt.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.settings,
    required this.onDone,
    this.location = const LocationService(),
  });

  final SettingsRepository settings;
  final VoidCallback onDone;
  final LocationService location;

  Future<void> _allow() async {
    final status = await location.request();
    settings.locateOnStart = status == LocationStatus.granted;
    settings.onboardingDone = true;
    onDone();
  }

  void _skip() {
    settings.onboardingDone = true;
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(Space.sm),
                    child: ListenableBuilder(
                      listenable: settings,
                      builder: (context, _) => SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                            visualDensity: VisualDensity.compact),
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('English')),
                          ButtonSegment(value: 'ne', label: Text('नेपाली')),
                        ],
                        selected: {Localizations.localeOf(context).languageCode},
                        onSelectionChanged: (s) =>
                            settings.locale = Locale(s.first),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                    children: [
                      const SizedBox(height: Space.lg),
                      const Center(child: AppLogo(size: 80)),
                      const SizedBox(height: Space.lg),
                      Text(l10n.onboardingTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: Space.md),
                      Text(l10n.onboardingBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: Space.xl),
                      _Point(icon: Icons.touch_app_outlined, text: l10n.onboardingPointTap),
                      _Point(icon: Icons.search_rounded, text: l10n.onboardingPointSearch),
                      _Point(icon: Icons.offline_pin_outlined, text: l10n.onboardingPointOffline),
                      const SizedBox(height: Space.lg),
                      Text(l10n.disclaimerShort,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: Space.lg),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Disclosure(
                        title: l10n.locationDisclosureTitle,
                        body: l10n.locationDisclosureBody,
                      ),
                      const SizedBox(height: Space.md),
                      FilledButton.icon(
                        onPressed: _allow,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                        icon: const Icon(Icons.my_location_rounded),
                        label: Text(l10n.allowLocation),
                      ),
                      const SizedBox(height: Space.sm),
                      TextButton(onPressed: _skip, child: Text(l10n.notNow)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: Space.lg),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// Location "prominent disclosure", always visible next to the Allow button.
class _Disclosure extends StatelessWidget {
  const _Disclosure({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.my_location_rounded, color: scheme.onSecondaryContainer),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(body,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSecondaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
