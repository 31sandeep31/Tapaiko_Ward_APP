import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/admin.dart';
import '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  bool get isNepali => Localizations.localeOf(this).languageCode == 'ne';

  /// Converts ASCII digits to Devanagari digits in Nepali.
  String digits(String s) {
    if (!isNepali) return s;
    const deva = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    final b = StringBuffer();
    for (final c in s.codeUnits) {
      b.write(c >= 48 && c <= 57 ? deva[c - 48] : String.fromCharCode(c));
    }
    return b.toString();
  }

  String number(int n) =>
      digits(NumberFormat.decimalPattern('en_IN').format(n));

  String typeLabel(LocalLevelType type) => switch (type) {
        LocalLevelType.metropolitan => l10n.typeMetropolitan,
        LocalLevelType.subMetropolitan => l10n.typeSubMetropolitan,
        LocalLevelType.municipality => l10n.typeMunicipality,
        LocalLevelType.rural => l10n.typeRural,
        LocalLevelType.other => l10n.typeOther,
      };

  String provinceLabel(ProvinceInfo p) => l10n.provinceName(p.shortName);

  String provinceShortLabel(ProvinceInfo p) => l10n.provinceShort(p.shortName);

  String wardLabel(String wardNo) => l10n.wardN(digits(wardNo));
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
