import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app_dependencies.dart';
import '../../../../data/settings_repository.dart';
import '../../../../data/tile_cache.dart';
import '../../../core/formatting.dart';
import '../../../core/theme.dart';
import '../../map/views/place_actions.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _cacheBytes;
  String _version = '';

  SettingsRepository get settings => widget.deps.settings;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    }).catchError((_) {});
  }

  Future<void> _loadCacheSize() async {
    final sizes = await Future.wait([
      widget.deps.data.cacheSize(),
      TileCache.sizeBytes(),
    ]);
    if (mounted) setState(() => _cacheBytes = sizes[0] + sizes[1]);
  }

  Future<void> _clearCache() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(l10n.clearCacheConfirm),
        content: Text(l10n.clearCacheConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.clear)),
        ],
      ),
    );
    if (ok != true) return;
    await widget.deps.data.clearCache();
    await TileCache.clear();
    await _loadCacheSize();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.cacheCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.xl),
          children: [
            _Section(l10n.appearance),
            _Labeled(
              label: l10n.theme,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_outlined),
                      label: Text(l10n.themeSystem)),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(l10n.themeLight)),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(l10n.themeDark)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.themeMode = s.first,
              ),
            ),
            _Labeled(
              label: l10n.language,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: '', label: Text(l10n.languageSystem)),
                  const ButtonSegment(value: 'en', label: Text('English')),
                  const ButtonSegment(value: 'ne', label: Text('नेपाली')),
                ],
                selected: {settings.locale?.languageCode ?? ''},
                onSelectionChanged: (s) =>
                    settings.locale = s.first.isEmpty ? null : Locale(s.first),
              ),
            ),
            _Section(l10n.map),
            SwitchListTile(
              secondary: const Icon(Icons.my_location_rounded),
              title: Text(l10n.locateOnStart),
              subtitle: Text(l10n.locateOnStartDesc),
              value: settings.locateOnStart,
              onChanged: (v) => settings.locateOnStart = v,
            ),
            _Section(l10n.storage),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(l10n.clearCache),
              subtitle: _cacheBytes == null
                  ? null
                  : Text(l10n.clearCacheDesc(formatBytes(_cacheBytes!))),
              onTap: _clearCache,
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(l10n.clearRecents),
              enabled: settings.recents.isNotEmpty,
              onTap: () {
                settings.clearRecents();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.recentsCleared)));
              },
            ),
            _Section(l10n.about),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l10n.aboutApp),
              subtitle: Text(l10n.dataSources),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AboutScreen(version: _version))),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.privacyPolicy),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PrivacyScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.star_outline_rounded),
              title: Text(l10n.rateApp),
              onTap: () => openLink(AppDependencies.playStoreUrl),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.shareApp),
              onTap: () => SharePlus.instance.share(ShareParams(
                  text: l10n.shareAppText(AppDependencies.playStoreUrl))),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.openSourceLicenses),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
                applicationVersion: _version,
              ),
            ),
            if (_version.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Text(
                  l10n.version(_version),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.sm),
      child: Semantics(
        header: true,
        child: Text(text,
            style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: Space.sm),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}
