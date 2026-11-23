// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'तपाईंको वडा';

  @override
  String get onboardingTitle => 'नेपालको जुनसुकै ठाउँको वडा थाहा पाउनुहोस्';

  @override
  String get onboardingBody =>
      'नेपालको कुनै पनि ठाउँको वडा, पालिका, जिल्ला र प्रदेश पत्ता लगाउनुहोस्।';

  @override
  String get onboardingPointTap =>
      'नक्सामा कुनै ठाउँ थिच्नुहोस्, त्यसको वडा देखिन्छ';

  @override
  String get onboardingPointSearch =>
      'सबै ७५३ स्थानीय तह र तिनका वडाहरू खोज्नुहोस्';

  @override
  String get onboardingPointOffline =>
      'खोलेका क्षेत्रहरू अफलाइन प्रयोगका लागि सुरक्षित हुन्छन्';

  @override
  String get locationDisclosureTitle => 'आफ्नो वडा स्वतः पत्ता लगाउनुहोस्';

  @override
  String get locationDisclosureBody =>
      'तपाईं कुन वडामा हुनुहुन्छ भनी पत्ता लगाउन तपाईंको वडा एपले तपाईंको स्थान यही फोनभित्र मात्र प्रयोग गर्छ। तपाईंको स्थान कहिल्यै सुरक्षित वा साझा गरिँदैन।';

  @override
  String get allowLocation => 'स्थान अनुमति दिनुहोस्';

  @override
  String get notNow => 'अहिले होइन';

  @override
  String get disclaimerShort =>
      'स्वतन्त्र एप। नेपाल सरकारसँग सम्बद्ध छैन। सीमाहरू सन्दर्भका लागि मात्र हुन्।';

  @override
  String get searchPlaceholder => 'ठाउँ खोज्नुहोस्';

  @override
  String get settings => 'सेटिङ';

  @override
  String get mapStyle => 'नक्साको शैली';

  @override
  String get myLocation => 'मेरो स्थान';

  @override
  String get exploreTitle => 'आफ्नो वडा खोज्नुहोस्';

  @override
  String get exploreSubtitle =>
      'नक्सामा कतै थिच्नुहोस्, वा आफ्नो स्थान प्रयोग गर्नुहोस्।';

  @override
  String get useMyLocation => 'मेरो स्थान प्रयोग गर्नुहोस्';

  @override
  String get recentPlaces => 'हालै हेरिएका';

  @override
  String get browseProvinces => 'प्रदेश अनुसार हेर्नुहोस्';

  @override
  String districtsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count जिल्ला',
    );
    return '$_temp0';
  }

  @override
  String localLevelsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्थानीय तह',
    );
    return '$_temp0';
  }

  @override
  String wardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वडा',
    );
    return '$_temp0';
  }

  @override
  String get nepal => 'नेपाल';

  @override
  String get levelProvince => 'प्रदेश';

  @override
  String get levelDistrict => 'जिल्ला';

  @override
  String get levelLocal => 'स्थानीय तह';

  @override
  String get typeMetropolitan => 'महानगरपालिका';

  @override
  String get typeSubMetropolitan => 'उपमहानगरपालिका';

  @override
  String get typeMunicipality => 'नगरपालिका';

  @override
  String get typeRural => 'गाउँपालिका';

  @override
  String get typeOther => 'स्थानीय तह';

  @override
  String provinceName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'Koshi': 'कोशी प्रदेश',
      'Madhesh': 'मधेश प्रदेश',
      'Bagmati': 'बागमती प्रदेश',
      'Gandaki': 'गण्डकी प्रदेश',
      'Lumbini': 'लुम्बिनी प्रदेश',
      'Karnali': 'कर्णाली प्रदेश',
      'Sudurpashchim': 'सुदूरपश्चिम प्रदेश',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String provinceShort(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'Koshi': 'कोशी',
      'Madhesh': 'मधेश',
      'Bagmati': 'बागमती',
      'Gandaki': 'गण्डकी',
      'Lumbini': 'लुम्बिनी',
      'Karnali': 'कर्णाली',
      'Sudurpashchim': 'सुदूरपश्चिम',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String provinceNumber(String number) {
    return 'प्रदेश नं. $number';
  }

  @override
  String get districtsHeader => 'जिल्लाहरू';

  @override
  String get localLevelsHeader => 'स्थानीय तहहरू';

  @override
  String get wardsHeader => 'वडाहरू';

  @override
  String get pickWardHint => 'वडा छान्नुहोस्, वा नक्सामा थिच्नुहोस्।';

  @override
  String get noWardData => 'यस क्षेत्रको वडा सीमा उपलब्ध छैन।';

  @override
  String get back => 'पछाडि';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get wardLabel => 'वडा';

  @override
  String wardN(String wardNo) {
    return 'वडा नं. $wardNo';
  }

  @override
  String get share => 'सेयर';

  @override
  String get copy => 'कपी';

  @override
  String get directions => 'बाटो';

  @override
  String get copied => 'कपी भयो';

  @override
  String get sharedFrom => 'तपाईंको वडा एपबाट सेयर गरिएको';

  @override
  String get population => 'जनसंख्या';

  @override
  String get census2021 => 'जनगणना २०७८';

  @override
  String get wardPopulation => 'वडाको जनसंख्या';

  @override
  String totalPopulationOf(String name) {
    return '$name जम्मा';
  }

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'महिला';

  @override
  String get populationUnavailable => 'जनसंख्याको विवरण अहिले उपलब्ध छैन।';

  @override
  String otherWardsIn(String name) {
    return '$name का वडाहरू';
  }

  @override
  String get location => 'स्थान';

  @override
  String get coordinates => 'निर्देशांक';

  @override
  String get openInMaps => 'नक्सामा खोल्नुहोस्';

  @override
  String get findingYourLocation => 'तपाईंको स्थान खोज्दै…';

  @override
  String get identifyingPlace => 'वडा खोज्दै…';

  @override
  String get loadingArea => 'लोड हुँदै…';

  @override
  String get outsideNepal => 'त्यो ठाउँ नेपालबाहिर छ।';

  @override
  String get placeNotFound => 'त्यो ठाउँमा वडा भेटिएन।';

  @override
  String get noWardAtSpot =>
      'त्यो ठाउँ कुनै वडा सीमाभित्र परेन। तल वडा छान्नुहोस्।';

  @override
  String get offlineError =>
      'इन्टरनेट छैन। यो क्षेत्र लोड गर्न इन्टरनेट जोड्नुहोस्।';

  @override
  String get serverError =>
      'नक्साको विवरण लोड हुन सकेन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get loadFailed => 'नक्सा सुरु हुन सकेन।';

  @override
  String get retry => 'फेरि प्रयास';

  @override
  String boundaryUnavailable(String name) {
    return '$name को सीमा अहिले उपलब्ध छैन।';
  }

  @override
  String get locationServiceOff => 'लोकेसन बन्द छ।';

  @override
  String get turnOn => 'खोल्नुहोस्';

  @override
  String get locationDenied => 'वडा पत्ता लगाउन स्थानको अनुमति दिनुहोस्।';

  @override
  String get locationDeniedForever =>
      'स्थानको अनुमति रोकिएको छ। सेटिङमा गएर अनुमति दिनुहोस्।';

  @override
  String get openSettings => 'सेटिङ';

  @override
  String get locationFailed =>
      'तपाईंको स्थान पाउन सकिएन। फेरि प्रयास गर्नुहोस्, वा नक्सामा थिच्नुहोस्।';

  @override
  String get searchHint => 'पालिका, जिल्ला वा प्रदेश';

  @override
  String get searchFilterAll => 'सबै';

  @override
  String get searchSectionProvinces => 'प्रदेशहरू';

  @override
  String get searchSectionDistricts => 'जिल्लाहरू';

  @override
  String get searchSectionLocalLevels => 'स्थानीय तहहरू';

  @override
  String searchNoResults(String query) {
    return '“$query” सँग मिल्ने ठाउँ भेटिएन';
  }

  @override
  String get searchTipWard =>
      'सुझाव: वडा नम्बर पनि लेख्नुहोस्, जस्तै “Kathmandu 5”';

  @override
  String get searchAllLocalLevels => 'सबै स्थानीय तह';

  @override
  String get clearSearch => 'मेटाउनुहोस्';

  @override
  String get appearance => 'देखावट';

  @override
  String get theme => 'थिम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'उज्यालो';

  @override
  String get themeDark => 'अँध्यारो';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'फोनको भाषा';

  @override
  String get map => 'नक्सा';

  @override
  String get styleAuto => 'स्वचालित';

  @override
  String get styleAutoDesc => 'उज्यालो वा अँध्यारो थिम अनुसार';

  @override
  String get styleStreets => 'सडक';

  @override
  String get styleLight => 'उज्यालो';

  @override
  String get styleDark => 'अँध्यारो';

  @override
  String get styleTerrain => 'भू-बनोट';

  @override
  String get styleSatellite => 'भू-उपग्रह';

  @override
  String get locateOnStart => 'एप खोल्दा मेरो वडा पत्ता लगाउनुहोस्';

  @override
  String get locateOnStartDesc => 'स्थानको अनुमति भएमा मात्र';

  @override
  String get storage => 'भण्डारण';

  @override
  String get clearCache => 'अफलाइन डाटा मेटाउनुहोस्';

  @override
  String clearCacheDesc(String size) {
    return 'यो फोनमा $size नक्सा र सीमा सुरक्षित छ';
  }

  @override
  String get clearCacheConfirm => 'अफलाइन डाटा मेटाउने?';

  @override
  String get clearCacheConfirmBody =>
      'सुरक्षित नक्सा र सीमाहरू आवश्यक पर्दा फेरि डाउनलोड हुनेछन्।';

  @override
  String get clear => 'मेटाउनुहोस्';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get cacheCleared => 'अफलाइन डाटा मेटाइयो';

  @override
  String get clearRecents => 'हालै हेरिएका ठाउँ मेटाउनुहोस्';

  @override
  String get recentsCleared => 'हालै हेरिएका ठाउँ मेटाइयो';

  @override
  String get about => 'बारेमा';

  @override
  String get aboutApp => 'तपाईंको वडाको बारेमा';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get dataSources => 'डाटाका स्रोतहरू';

  @override
  String get openSourceLicenses => 'खुला स्रोत इजाजतपत्र';

  @override
  String get rateApp => 'गुगल प्लेमा रेटिङ दिनुहोस्';

  @override
  String get sendFeedback => 'प्रतिक्रिया पठाउनुहोस्';

  @override
  String get shareApp => 'एप सेयर गर्नुहोस्';

  @override
  String shareAppText(String link) {
    return 'तपाईंको वडा एपबाट नेपालको जुनसुकै ठाउँको वडा थाहा पाउनुहोस्: $link';
  }

  @override
  String version(String version) {
    return 'संस्करण $version';
  }

  @override
  String get disclaimerTitle => 'अस्वीकरण';

  @override
  String get disclaimerBody =>
      'तपाईंको वडा एक स्वतन्त्र एप हो। यो नेपाल सरकार वा कुनै सरकारी निकायसँग सम्बद्ध, समर्थित वा त्यसको प्रतिनिधि होइन। सीमा र जनसंख्याका विवरणहरू सार्वजनिक स्रोतबाट लिइएका हुन् र सन्दर्भका लागि मात्र हुन्। यी आधिकारिक नापी वा कानुनी अभिलेख होइनन्।';

  @override
  String get sourceBoundaries => 'प्रशासनिक सीमाहरू';

  @override
  String get sourceBoundariesDesc =>
      'नेपालका प्रदेश, जिल्ला, स्थानीय तह र वडाका सीमाहरू, maps.sandeepkafle.com.np बाट';

  @override
  String get sourceCensus => 'जनसंख्या';

  @override
  String get sourceCensusDesc =>
      'राष्ट्रिय जनगणना २०७८, राष्ट्रिय तथ्यांक कार्यालय, नेपाल (censusapi.cbs.gov.np)';

  @override
  String get sourceMaps => 'आधार नक्सा';

  @override
  String get sourceMapsDesc =>
      '© OpenStreetMap योगदानकर्ताहरू, CARTO, OpenTopoMap, Esri';

  @override
  String privacyUpdated(String date) {
    return 'अन्तिम अद्यावधिक: $date';
  }

  @override
  String get privacyIntro =>
      'तपाईंको वडा एपले नेपालको कुनै ठाउँको वडा, पालिका, जिल्ला र प्रदेश पत्ता लगाउन मद्दत गर्छ। यो नीतिले एपले तपाईंको जानकारी के गर्छ भनी बताउँछ। छोटकरीमा: खाता छैन, विज्ञापन छैन र ट्र्याकिङ छैन।';

  @override
  String get privacyLocationTitle => 'स्थान';

  @override
  String get privacyLocationBody =>
      'तपाईंले अनुमति दिनुभयो भने, तपाईं कुन वडामा हुनुहुन्छ भनी पत्ता लगाउन एपले फोनको स्थान पढ्छ। यो काम पूर्ण रूपमा तपाईंको फोनभित्रै हुन्छ। तपाईंको स्थान हामी वा अरू कसैलाई पठाइँदैन, र एप बन्द भएपछि राखिँदैन। फोनको सेटिङमा गएर जुनसुकै बेला स्थानको अनुमति बन्द गर्न सक्नुहुन्छ; त्यसपछि पनि नक्सामा थिचेर वा खोजेर एप प्रयोग गर्न सक्नुहुन्छ।';

  @override
  String get privacyNetworkTitle => 'इन्टरनेट अनुरोधहरू';

  @override
  String get privacyNetworkBody =>
      'नक्सा र सीमाहरू देखाउन एपले तपाईंले छानेको नक्सा प्रदायक (OpenStreetMap, CARTO, OpenTopoMap वा Esri) बाट नक्साका टाइलहरू, maps.sandeepkafle.com.np बाट सीमाका फाइलहरू, र राष्ट्रिय तथ्यांक कार्यालयको जनगणना सेवा (censusapi.cbs.gov.np) बाट जनसंख्याका विवरणहरू डाउनलोड गर्छ। जुनसुकै वेबसाइटजस्तै, यी सर्भरहरूले तपाईंको IP ठेगाना र कुन नक्सा क्षेत्र वा पालिका मागिएको हो भन्ने देख्न सक्छन्। उनीहरूले तपाईंको GPS स्थान पाउँदैनन्।';

  @override
  String get privacyStorageTitle => 'फोनमा सुरक्षित हुने डाटा';

  @override
  String get privacyStorageBody =>
      'एप छिटो र अफलाइन चलोस् भनेर डाउनलोड गरिएका नक्सा र सीमाहरू, तपाईंका सेटिङहरू र हालै हेरिएका केही ठाउँहरू फोनमै सुरक्षित गरिन्छन्। यो डाटा तपाईंको फोनबाहिर जाँदैन। सेटिङबाट वा एप हटाएर यसलाई मेटाउन सकिन्छ।';

  @override
  String get privacyNoTrackingTitle => 'खाता, विज्ञापन वा एनालिटिक्स छैन';

  @override
  String get privacyNoTrackingBody =>
      'एपले साइन इन गर्न लगाउँदैन, विज्ञापन देखाउँदैन, र एनालिटिक्स वा ट्र्याकिङ उपकरण प्रयोग गर्दैन। हामी कुनै व्यक्तिगत जानकारी बेच्दैनौं वा साझा गर्दैनौं।';

  @override
  String get privacyChildrenTitle => 'बालबालिका';

  @override
  String get privacyChildrenBody =>
      'एपले बालबालिकासहित कसैको पनि व्यक्तिगत जानकारी जानीजानी सङ्कलन गर्दैन।';

  @override
  String get privacyChangesTitle => 'परिवर्तनहरू';

  @override
  String get privacyChangesBody =>
      'यो नीति परिवर्तन भएमा, अद्यावधिक संस्करण एपमा र स्टोर पेजमा प्रकाशित गरिनेछ।';

  @override
  String get privacyContactTitle => 'सम्पर्क';

  @override
  String get privacyContactBody =>
      'गोपनीयताबारे प्रश्न छ? ward@sandeepkafle.com.np मा इमेल गर्नुहोस्।';
}
