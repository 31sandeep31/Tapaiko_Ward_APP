import 'package:flutter/material.dart';

import '../../../core/app_logo.dart';
import '../../../core/formatting.dart';
import '../../../core/theme.dart';
import '../../map/views/place_actions.dart';

/// App info, government-data disclaimer and data sources (required by
/// Google Play's policy for apps that show government information).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg,
            MediaQuery.paddingOf(context).bottom + Space.xl),
        children: [
          const Center(child: AppLogo(size: 88)),
          const SizedBox(height: Space.md),
          Text(l10n.appTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (version.isNotEmpty)
            Text(l10n.version(version),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Space.xl),
          Card(
            color: scheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.gavel_rounded, color: scheme.onTertiaryContainer),
                    const SizedBox(width: Space.sm),
                    Text(l10n.disclaimerTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: scheme.onTertiaryContainer)),
                  ]),
                  const SizedBox(height: Space.sm),
                  Text(l10n.disclaimerBody,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onTertiaryContainer)),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          Text(l10n.dataSources,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: Space.sm),
          _Source(
            icon: Icons.map_outlined,
            title: l10n.sourceBoundaries,
            body: l10n.sourceBoundariesDesc,
            url: 'https://dos.gov.np',
          ),
          _Source(
            icon: Icons.groups_outlined,
            title: l10n.sourceCensus,
            body: l10n.sourceCensusDesc,
            url: 'https://censusnepal.cbs.gov.np',
          ),
          _Source(
            icon: Icons.layers_outlined,
            title: l10n.sourceMaps,
            body: l10n.sourceMapsDesc,
            url: 'https://www.openstreetmap.org/copyright',
          ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({
    required this.icon,
    required this.title,
    required this.body,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String body;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
      onTap: () => openLink(url),
    );
  }
}
