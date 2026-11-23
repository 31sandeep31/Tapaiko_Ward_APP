// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tapaiko Ward';

  @override
  String get onboardingTitle => 'Know your ward, anywhere in Nepal';

  @override
  String get onboardingBody =>
      'Find the ward, municipality, district and province of any place in Nepal.';

  @override
  String get onboardingPointTap => 'Tap any spot on the map to see its ward';

  @override
  String get onboardingPointSearch =>
      'Search all 753 local levels and their wards';

  @override
  String get onboardingPointOffline =>
      'Areas you open are saved for offline use';

  @override
  String get locationDisclosureTitle => 'Find your ward automatically';

  @override
  String get locationDisclosureBody =>
      'Tapaiko Ward uses your location only on this phone to work out which ward you are in. Your location is never stored or shared.';

  @override
  String get allowLocation => 'Allow location';

  @override
  String get notNow => 'Not now';

  @override
  String get disclaimerShort =>
      'Independent app. Not affiliated with the Government of Nepal. Boundaries are for reference only.';

  @override
  String get searchPlaceholder => 'Search places';

  @override
  String get settings => 'Settings';

  @override
  String get mapStyle => 'Map style';

  @override
  String get myLocation => 'My location';

  @override
  String get exploreTitle => 'Find your ward';

  @override
  String get exploreSubtitle =>
      'Tap anywhere on the map, or use your location.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get recentPlaces => 'Recent';

  @override
  String get browseProvinces => 'Browse by province';

  @override
  String districtsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count districts',
      one: '1 district',
    );
    return '$_temp0';
  }

  @override
  String localLevelsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count local levels',
      one: '1 local level',
    );
    return '$_temp0';
  }

  @override
  String wardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wards',
      one: '1 ward',
    );
    return '$_temp0';
  }

  @override
  String get nepal => 'Nepal';

  @override
  String get levelProvince => 'Province';

  @override
  String get levelDistrict => 'District';

  @override
  String get levelLocal => 'Local level';

  @override
  String get typeMetropolitan => 'Metropolitan City';

  @override
  String get typeSubMetropolitan => 'Sub-Metropolitan City';

  @override
  String get typeMunicipality => 'Municipality';

  @override
  String get typeRural => 'Rural Municipality';

  @override
  String get typeOther => 'Local level';

  @override
  String provinceName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'Koshi': 'Koshi Province',
      'Madhesh': 'Madhesh Province',
      'Bagmati': 'Bagmati Province',
      'Gandaki': 'Gandaki Province',
      'Lumbini': 'Lumbini Province',
      'Karnali': 'Karnali Province',
      'Sudurpashchim': 'Sudurpashchim Province',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String provinceShort(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'Koshi': 'Koshi',
      'Madhesh': 'Madhesh',
      'Bagmati': 'Bagmati',
      'Gandaki': 'Gandaki',
      'Lumbini': 'Lumbini',
      'Karnali': 'Karnali',
      'Sudurpashchim': 'Sudurpashchim',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String provinceNumber(String number) {
    return 'Province $number';
  }

  @override
  String get districtsHeader => 'Districts';

  @override
  String get localLevelsHeader => 'Local levels';

  @override
  String get wardsHeader => 'Wards';

  @override
  String get pickWardHint => 'Pick a ward, or tap one on the map.';

  @override
  String get noWardData => 'Ward boundaries aren\'t available for this area.';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get wardLabel => 'Ward';

  @override
  String wardN(String wardNo) {
    return 'Ward $wardNo';
  }

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get directions => 'Directions';

  @override
  String get copied => 'Copied';

  @override
  String get sharedFrom => 'Shared from Tapaiko Ward';

  @override
  String get population => 'Population';

  @override
  String get census2021 => 'Census 2021';

  @override
  String get wardPopulation => 'Ward population';

  @override
  String totalPopulationOf(String name) {
    return '$name total';
  }

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get populationUnavailable =>
      'Population data isn\'t available right now.';

  @override
  String otherWardsIn(String name) {
    return 'Wards of $name';
  }

  @override
  String get location => 'Location';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get openInMaps => 'Open in maps';

  @override
  String get findingYourLocation => 'Finding your location…';

  @override
  String get identifyingPlace => 'Finding the ward…';

  @override
  String get loadingArea => 'Loading…';

  @override
  String get outsideNepal => 'That spot is outside Nepal.';

  @override
  String get placeNotFound => 'Couldn\'t find a ward at that spot.';

  @override
  String get noWardAtSpot =>
      'That spot isn\'t inside a ward boundary. Pick a ward below.';

  @override
  String get offlineError =>
      'You\'re offline. Connect to the internet to load this area.';

  @override
  String get serverError => 'Couldn\'t load map data. Please try again.';

  @override
  String get loadFailed => 'Couldn\'t start the map.';

  @override
  String get retry => 'Retry';

  @override
  String boundaryUnavailable(String name) {
    return 'The boundary for $name isn\'t available yet.';
  }

  @override
  String get locationServiceOff => 'Location is turned off.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get locationDenied => 'Allow location access to find your ward.';

  @override
  String get locationDeniedForever =>
      'Location access is blocked. Allow it in Settings.';

  @override
  String get openSettings => 'Settings';

  @override
  String get locationFailed =>
      'Couldn\'t get your location. Try again, or tap the map instead.';

  @override
  String get searchHint => 'Municipality, district or province';

  @override
  String get searchFilterAll => 'All';

  @override
  String get searchSectionProvinces => 'Provinces';

  @override
  String get searchSectionDistricts => 'Districts';

  @override
  String get searchSectionLocalLevels => 'Local levels';

  @override
  String searchNoResults(String query) {
    return 'No places match “$query”';
  }

  @override
  String get searchTipWard => 'Tip: add a ward number, like “Kathmandu 5”';

  @override
  String get searchAllLocalLevels => 'All local levels';

  @override
  String get clearSearch => 'Clear';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get map => 'Map';

  @override
  String get styleAuto => 'Automatic';

  @override
  String get styleAutoDesc => 'Matches the light or dark theme';

  @override
  String get styleStreets => 'Streets';

  @override
  String get styleLight => 'Light';

  @override
  String get styleDark => 'Dark';

  @override
  String get styleTerrain => 'Terrain';

  @override
  String get styleSatellite => 'Satellite';

  @override
  String get locateOnStart => 'Find my ward when the app opens';

  @override
  String get locateOnStartDesc => 'Only if location access is allowed';

  @override
  String get storage => 'Storage';

  @override
  String get clearCache => 'Clear offline data';

  @override
  String clearCacheDesc(String size) {
    return '$size of maps and boundaries saved on this phone';
  }

  @override
  String get clearCacheConfirm => 'Clear offline data?';

  @override
  String get clearCacheConfirmBody =>
      'Saved maps and boundaries will be downloaded again when you need them.';

  @override
  String get clear => 'Clear';

  @override
  String get cancel => 'Cancel';

  @override
  String get cacheCleared => 'Offline data cleared';

  @override
  String get clearRecents => 'Clear recent places';

  @override
  String get recentsCleared => 'Recent places cleared';

  @override
  String get about => 'About';

  @override
  String get aboutApp => 'About Tapaiko Ward';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get dataSources => 'Data sources';

  @override
  String get openSourceLicenses => 'Open-source licences';

  @override
  String get rateApp => 'Rate on Google Play';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get shareApp => 'Share the app';

  @override
  String shareAppText(String link) {
    return 'Find your ward anywhere in Nepal with Tapaiko Ward: $link';
  }

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get disclaimerTitle => 'Disclaimer';

  @override
  String get disclaimerBody =>
      'Tapaiko Ward is an independent app. It is not affiliated with, endorsed by, or representing the Government of Nepal or any government entity. Boundaries and population figures come from public sources and are for reference only. They are not an official survey or legal record.';

  @override
  String get sourceBoundaries => 'Administrative boundaries';

  @override
  String get sourceBoundariesDesc =>
      'Province, district, local level and ward boundaries from the Survey Department (Napi Bibhag), Government of Nepal. Served via maps.sandeepkafle.com.np';

  @override
  String get sourceCensus => 'Population';

  @override
  String get sourceCensusDesc =>
      'National Population and Housing Census 2021, National Statistics Office, Nepal (censusapi.cbs.gov.np)';

  @override
  String get sourceMaps => 'Base maps';

  @override
  String get sourceMapsDesc =>
      '© OpenStreetMap contributors, OpenTopoMap, Esri';

  @override
  String privacyUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get privacyIntro =>
      'Tapaiko Ward helps you find the ward, municipality, district and province of a place in Nepal. This policy explains what the app does with your information. In short: there are no accounts, no ads and no tracking.';

  @override
  String get privacyLocationTitle => 'Location';

  @override
  String get privacyLocationBody =>
      'If you allow it, the app reads your device\'s location to find the ward you are in. This happens entirely on your phone. Your location is not sent to us or anyone else, and it is not stored after the app closes. You can turn location access off at any time in your phone\'s settings; you can still use the app by tapping the map or searching.';

  @override
  String get privacyNetworkTitle => 'Internet requests';

  @override
  String get privacyNetworkBody =>
      'To show maps and boundaries, the app downloads map tiles from the map provider you choose (OpenStreetMap, OpenTopoMap or Esri), Survey Department boundary files from maps.sandeepkafle.com.np, and population figures from the National Statistics Office census service (censusapi.cbs.gov.np). Like any website, these servers can see your IP address and which map area or municipality was requested. They do not receive your GPS location.';

  @override
  String get privacyStorageTitle => 'Data stored on your phone';

  @override
  String get privacyStorageBody =>
      'The app saves downloaded maps and boundaries, your settings and a short list of recently viewed places on your phone so it works faster and offline. This data never leaves your phone. You can delete it in Settings, or by uninstalling the app.';

  @override
  String get privacyNoTrackingTitle => 'No accounts, ads or analytics';

  @override
  String get privacyNoTrackingBody =>
      'The app does not ask you to sign in, does not show ads, and does not use analytics or tracking tools. We do not sell or share any personal information.';

  @override
  String get privacyChildrenTitle => 'Children';

  @override
  String get privacyChildrenBody =>
      'The app does not knowingly collect personal information from anyone, including children.';

  @override
  String get privacyChangesTitle => 'Changes';

  @override
  String get privacyChangesBody =>
      'If this policy changes, the updated version will be published in the app and on the store listing.';

  @override
  String get privacyContactTitle => 'Contact';

  @override
  String get privacyContactBody =>
      'Questions about privacy? Email ward@sandeepkafle.com.np.';
}
