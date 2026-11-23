import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tapaiko Ward'**
  String get appTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Know your ward, anywhere in Nepal'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Find the ward, municipality, district and province of any place in Nepal.'**
  String get onboardingBody;

  /// No description provided for @onboardingPointTap.
  ///
  /// In en, this message translates to:
  /// **'Tap any spot on the map to see its ward'**
  String get onboardingPointTap;

  /// No description provided for @onboardingPointSearch.
  ///
  /// In en, this message translates to:
  /// **'Search all 753 local levels and their wards'**
  String get onboardingPointSearch;

  /// No description provided for @onboardingPointOffline.
  ///
  /// In en, this message translates to:
  /// **'Areas you open are saved for offline use'**
  String get onboardingPointOffline;

  /// No description provided for @locationDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your ward automatically'**
  String get locationDisclosureTitle;

  /// No description provided for @locationDisclosureBody.
  ///
  /// In en, this message translates to:
  /// **'Tapaiko Ward uses your location only on this phone to work out which ward you are in. Your location is never stored or shared.'**
  String get locationDisclosureBody;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get allowLocation;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @disclaimerShort.
  ///
  /// In en, this message translates to:
  /// **'Independent app. Not affiliated with the Government of Nepal. Boundaries are for reference only.'**
  String get disclaimerShort;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search places'**
  String get searchPlaceholder;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @mapStyle.
  ///
  /// In en, this message translates to:
  /// **'Map style'**
  String get mapStyle;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your ward'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on the map, or use your location.'**
  String get exploreSubtitle;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @recentPlaces.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentPlaces;

  /// No description provided for @browseProvinces.
  ///
  /// In en, this message translates to:
  /// **'Browse by province'**
  String get browseProvinces;

  /// No description provided for @districtsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 district} other{{count} districts}}'**
  String districtsCount(int count);

  /// No description provided for @localLevelsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 local level} other{{count} local levels}}'**
  String localLevelsCount(int count);

  /// No description provided for @wardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ward} other{{count} wards}}'**
  String wardsCount(int count);

  /// No description provided for @nepal.
  ///
  /// In en, this message translates to:
  /// **'Nepal'**
  String get nepal;

  /// No description provided for @levelProvince.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get levelProvince;

  /// No description provided for @levelDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get levelDistrict;

  /// No description provided for @levelLocal.
  ///
  /// In en, this message translates to:
  /// **'Local level'**
  String get levelLocal;

  /// No description provided for @typeMetropolitan.
  ///
  /// In en, this message translates to:
  /// **'Metropolitan City'**
  String get typeMetropolitan;

  /// No description provided for @typeSubMetropolitan.
  ///
  /// In en, this message translates to:
  /// **'Sub-Metropolitan City'**
  String get typeSubMetropolitan;

  /// No description provided for @typeMunicipality.
  ///
  /// In en, this message translates to:
  /// **'Municipality'**
  String get typeMunicipality;

  /// No description provided for @typeRural.
  ///
  /// In en, this message translates to:
  /// **'Rural Municipality'**
  String get typeRural;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Local level'**
  String get typeOther;

  /// No description provided for @provinceName.
  ///
  /// In en, this message translates to:
  /// **'{name, select, Koshi{Koshi Province} Madhesh{Madhesh Province} Bagmati{Bagmati Province} Gandaki{Gandaki Province} Lumbini{Lumbini Province} Karnali{Karnali Province} Sudurpashchim{Sudurpashchim Province} other{{name}}}'**
  String provinceName(String name);

  /// No description provided for @provinceShort.
  ///
  /// In en, this message translates to:
  /// **'{name, select, Koshi{Koshi} Madhesh{Madhesh} Bagmati{Bagmati} Gandaki{Gandaki} Lumbini{Lumbini} Karnali{Karnali} Sudurpashchim{Sudurpashchim} other{{name}}}'**
  String provinceShort(String name);

  /// No description provided for @provinceNumber.
  ///
  /// In en, this message translates to:
  /// **'Province {number}'**
  String provinceNumber(String number);

  /// No description provided for @districtsHeader.
  ///
  /// In en, this message translates to:
  /// **'Districts'**
  String get districtsHeader;

  /// No description provided for @localLevelsHeader.
  ///
  /// In en, this message translates to:
  /// **'Local levels'**
  String get localLevelsHeader;

  /// No description provided for @wardsHeader.
  ///
  /// In en, this message translates to:
  /// **'Wards'**
  String get wardsHeader;

  /// No description provided for @pickWardHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a ward, or tap one on the map.'**
  String get pickWardHint;

  /// No description provided for @noWardData.
  ///
  /// In en, this message translates to:
  /// **'Ward boundaries aren\'t available for this area.'**
  String get noWardData;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @wardLabel.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get wardLabel;

  /// No description provided for @wardN.
  ///
  /// In en, this message translates to:
  /// **'Ward {wardNo}'**
  String wardN(String wardNo);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @sharedFrom.
  ///
  /// In en, this message translates to:
  /// **'Shared from Tapaiko Ward'**
  String get sharedFrom;

  /// No description provided for @population.
  ///
  /// In en, this message translates to:
  /// **'Population'**
  String get population;

  /// No description provided for @census2021.
  ///
  /// In en, this message translates to:
  /// **'Census 2021'**
  String get census2021;

  /// No description provided for @wardPopulation.
  ///
  /// In en, this message translates to:
  /// **'Ward population'**
  String get wardPopulation;

  /// No description provided for @totalPopulationOf.
  ///
  /// In en, this message translates to:
  /// **'{name} total'**
  String totalPopulationOf(String name);

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @populationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Population data isn\'t available right now.'**
  String get populationUnavailable;

  /// No description provided for @otherWardsIn.
  ///
  /// In en, this message translates to:
  /// **'Wards of {name}'**
  String otherWardsIn(String name);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get openInMaps;

  /// No description provided for @findingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get findingYourLocation;

  /// No description provided for @identifyingPlace.
  ///
  /// In en, this message translates to:
  /// **'Finding the ward…'**
  String get identifyingPlace;

  /// No description provided for @loadingArea.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingArea;

  /// No description provided for @outsideNepal.
  ///
  /// In en, this message translates to:
  /// **'That spot is outside Nepal.'**
  String get outsideNepal;

  /// No description provided for @placeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find a ward at that spot.'**
  String get placeNotFound;

  /// No description provided for @noWardAtSpot.
  ///
  /// In en, this message translates to:
  /// **'That spot isn\'t inside a ward boundary. Pick a ward below.'**
  String get noWardAtSpot;

  /// No description provided for @offlineError.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet to load this area.'**
  String get offlineError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load map data. Please try again.'**
  String get serverError;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the map.'**
  String get loadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @boundaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The boundary for {name} isn\'t available yet.'**
  String boundaryUnavailable(String name);

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off.'**
  String get locationServiceOff;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to find your ward.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Allow it in Settings.'**
  String get locationDeniedForever;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Try again, or tap the map instead.'**
  String get locationFailed;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Municipality, district or province'**
  String get searchHint;

  /// No description provided for @searchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchFilterAll;

  /// No description provided for @searchSectionProvinces.
  ///
  /// In en, this message translates to:
  /// **'Provinces'**
  String get searchSectionProvinces;

  /// No description provided for @searchSectionDistricts.
  ///
  /// In en, this message translates to:
  /// **'Districts'**
  String get searchSectionDistricts;

  /// No description provided for @searchSectionLocalLevels.
  ///
  /// In en, this message translates to:
  /// **'Local levels'**
  String get searchSectionLocalLevels;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No places match “{query}”'**
  String searchNoResults(String query);

  /// No description provided for @searchTipWard.
  ///
  /// In en, this message translates to:
  /// **'Tip: add a ward number, like “Kathmandu 5”'**
  String get searchTipWard;

  /// No description provided for @searchAllLocalLevels.
  ///
  /// In en, this message translates to:
  /// **'All local levels'**
  String get searchAllLocalLevels;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSearch;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @styleAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get styleAuto;

  /// No description provided for @styleAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Matches the light or dark theme'**
  String get styleAutoDesc;

  /// No description provided for @styleStreets.
  ///
  /// In en, this message translates to:
  /// **'Streets'**
  String get styleStreets;

  /// No description provided for @styleLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get styleLight;

  /// No description provided for @styleDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get styleDark;

  /// No description provided for @styleTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get styleTerrain;

  /// No description provided for @styleSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get styleSatellite;

  /// No description provided for @locateOnStart.
  ///
  /// In en, this message translates to:
  /// **'Find my ward when the app opens'**
  String get locateOnStart;

  /// No description provided for @locateOnStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Only if location access is allowed'**
  String get locateOnStartDesc;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear offline data'**
  String get clearCache;

  /// No description provided for @clearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'{size} of maps and boundaries saved on this phone'**
  String clearCacheDesc(String size);

  /// No description provided for @clearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear offline data?'**
  String get clearCacheConfirm;

  /// No description provided for @clearCacheConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Saved maps and boundaries will be downloaded again when you need them.'**
  String get clearCacheConfirmBody;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Offline data cleared'**
  String get cacheCleared;

  /// No description provided for @clearRecents.
  ///
  /// In en, this message translates to:
  /// **'Clear recent places'**
  String get clearRecents;

  /// No description provided for @recentsCleared.
  ///
  /// In en, this message translates to:
  /// **'Recent places cleared'**
  String get recentsCleared;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Tapaiko Ward'**
  String get aboutApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @dataSources.
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get dataSources;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get openSourceLicenses;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate on Google Play'**
  String get rateApp;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share the app'**
  String get shareApp;

  /// No description provided for @shareAppText.
  ///
  /// In en, this message translates to:
  /// **'Find your ward anywhere in Nepal with Tapaiko Ward: {link}'**
  String shareAppText(String link);

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'Tapaiko Ward is an independent app. It is not affiliated with, endorsed by, or representing the Government of Nepal or any government entity. Boundaries and population figures come from public sources and are for reference only. They are not an official survey or legal record.'**
  String get disclaimerBody;

  /// No description provided for @sourceBoundaries.
  ///
  /// In en, this message translates to:
  /// **'Administrative boundaries'**
  String get sourceBoundaries;

  /// No description provided for @sourceBoundariesDesc.
  ///
  /// In en, this message translates to:
  /// **'Province, district, local level and ward boundaries of Nepal, served from maps.sandeepkafle.com.np'**
  String get sourceBoundariesDesc;

  /// No description provided for @sourceCensus.
  ///
  /// In en, this message translates to:
  /// **'Population'**
  String get sourceCensus;

  /// No description provided for @sourceCensusDesc.
  ///
  /// In en, this message translates to:
  /// **'National Population and Housing Census 2021, National Statistics Office, Nepal (censusapi.cbs.gov.np)'**
  String get sourceCensusDesc;

  /// No description provided for @sourceMaps.
  ///
  /// In en, this message translates to:
  /// **'Base maps'**
  String get sourceMaps;

  /// No description provided for @sourceMapsDesc.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors, CARTO, OpenTopoMap, Esri'**
  String get sourceMapsDesc;

  /// No description provided for @privacyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String privacyUpdated(String date);

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Tapaiko Ward helps you find the ward, municipality, district and province of a place in Nepal. This policy explains what the app does with your information. In short: there are no accounts, no ads and no tracking.'**
  String get privacyIntro;

  /// No description provided for @privacyLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get privacyLocationTitle;

  /// No description provided for @privacyLocationBody.
  ///
  /// In en, this message translates to:
  /// **'If you allow it, the app reads your device\'s location to find the ward you are in. This happens entirely on your phone. Your location is not sent to us or anyone else, and it is not stored after the app closes. You can turn location access off at any time in your phone\'s settings; you can still use the app by tapping the map or searching.'**
  String get privacyLocationBody;

  /// No description provided for @privacyNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Internet requests'**
  String get privacyNetworkTitle;

  /// No description provided for @privacyNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'To show maps and boundaries, the app downloads map tiles from the map provider you choose (OpenStreetMap, CARTO, OpenTopoMap or Esri), boundary files from maps.sandeepkafle.com.np, and population figures from the National Statistics Office census service (censusapi.cbs.gov.np). Like any website, these servers can see your IP address and which map area or municipality was requested. They do not receive your GPS location.'**
  String get privacyNetworkBody;

  /// No description provided for @privacyStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Data stored on your phone'**
  String get privacyStorageTitle;

  /// No description provided for @privacyStorageBody.
  ///
  /// In en, this message translates to:
  /// **'The app saves downloaded maps and boundaries, your settings and a short list of recently viewed places on your phone so it works faster and offline. This data never leaves your phone. You can delete it in Settings, or by uninstalling the app.'**
  String get privacyStorageBody;

  /// No description provided for @privacyNoTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts, ads or analytics'**
  String get privacyNoTrackingTitle;

  /// No description provided for @privacyNoTrackingBody.
  ///
  /// In en, this message translates to:
  /// **'The app does not ask you to sign in, does not show ads, and does not use analytics or tracking tools. We do not sell or share any personal information.'**
  String get privacyNoTrackingBody;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildrenBody.
  ///
  /// In en, this message translates to:
  /// **'The app does not knowingly collect personal information from anyone, including children.'**
  String get privacyChildrenBody;

  /// No description provided for @privacyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get privacyChangesTitle;

  /// No description provided for @privacyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'If this policy changes, the updated version will be published in the app and on the store listing.'**
  String get privacyChangesBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'Questions about privacy? Email ward@sandeepkafle.com.np.'**
  String get privacyContactBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
