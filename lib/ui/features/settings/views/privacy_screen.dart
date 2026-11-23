import 'package:flutter/material.dart';

import '../../../core/formatting.dart';
import '../../../core/theme.dart';

/// In-app copy of the privacy policy (also published as
/// store/privacy_policy.html for the Play Console).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const lastUpdated = '2026-11-23';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = [
      (l10n.privacyLocationTitle, l10n.privacyLocationBody),
      (l10n.privacyNetworkTitle, l10n.privacyNetworkBody),
      (l10n.privacyStorageTitle, l10n.privacyStorageBody),
      (l10n.privacyNoTrackingTitle, l10n.privacyNoTrackingBody),
      (l10n.privacyChildrenTitle, l10n.privacyChildrenBody),
      (l10n.privacyChangesTitle, l10n.privacyChangesBody),
      (l10n.privacyContactTitle, l10n.privacyContactBody),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg,
            MediaQuery.paddingOf(context).bottom + Space.xl),
        children: [
          Text(l10n.privacyUpdated(context.digits(lastUpdated)),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Space.md),
          Text(l10n.privacyIntro, style: theme.textTheme.bodyLarge),
          for (final (title, body) in sections) ...[
            const SizedBox(height: Space.xl),
            Semantics(
              header: true,
              child: Text(title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: Space.sm),
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}
