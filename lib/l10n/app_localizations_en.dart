// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TAPAIKO WARD';

  @override
  String get searchMunicipalityTitle => 'Search municipality / ward';

  @override
  String get searchHint => 'Search name, district, or province…';

  @override
  String get allTypes => 'All';

  @override
  String get noMatchingMunicipalities => 'No matching municipalities.';

  @override
  String get couldNotLoadMunicipalities => 'Could not load municipalities';

  @override
  String get tapAProvince => 'Tap a province to start.';

  @override
  String get baseLayer => 'Base layer';

  @override
  String get findMyWard => 'Find my ward';

  @override
  String get identifyingLocation => 'Identifying this location…';

  @override
  String get longPressHint =>
      'Tap to browse. Long-press anywhere to identify the ward, municipality, district and province.';

  @override
  String get goBack => 'Go back';

  @override
  String get searchWardTooltip => 'Search ward / municipality';

  @override
  String get yourWard => 'YOUR WARD';

  @override
  String ward(String wardNo) {
    return 'Ward $wardNo';
  }

  @override
  String get population => 'Population (Census 2021)';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get municipalityLabel => 'Municipality';

  @override
  String get typeLabel => 'Type';

  @override
  String get districtLabel => 'District';

  @override
  String get provinceLabel => 'Province';

  @override
  String get couldNotLoadMap => 'Could not load map data';

  @override
  String get retry => 'Retry';

  @override
  String get noWardBoundaries => 'No ward boundaries loaded.';

  @override
  String currentLocationInfo(String wardNo, String municipality, String district) {
    return 'You are currently in Ward $wardNo of $municipality, $district.';
  }
}
