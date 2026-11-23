import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base map styles offered in the layer picker.
enum MapStyle { auto, streets, light, dark, terrain, satellite }

/// A place the user looked at recently, enough to reopen it.
class RecentPlace {
  const RecentPlace({
    required this.district,
    required this.localLevel,
    required this.type,
    this.wardNo,
  });

  final String district;

  /// Local level name as used by the boundary files.
  final String localLevel;
  final String type;
  final String? wardNo;

  String get key => '$district/$localLevel/${wardNo ?? ''}';

  factory RecentPlace.fromJson(Map<String, dynamic> json) => RecentPlace(
        district: json['d'] as String? ?? '',
        localLevel: json['l'] as String? ?? '',
        type: json['t'] as String? ?? '',
        wardNo: json['w'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'd': district,
        'l': localLevel,
        't': type,
        if (wardNo != null) 'w': wardNo,
      };
}

/// User preferences and recent places, persisted with SharedPreferences.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository._(this._prefs) {
    _themeMode = ThemeMode.values.elementAtOrNull(
            _prefs.getInt(_kTheme) ?? ThemeMode.system.index) ??
        ThemeMode.system;
    final lang = _prefs.getString(_kLocale);
    _locale = lang == null || lang.isEmpty ? null : Locale(lang);
    _mapStyle = MapStyle.values.elementAtOrNull(
            _prefs.getInt(_kMapStyle) ?? MapStyle.auto.index) ??
        MapStyle.auto;
    _onboardingDone = _prefs.getBool(_kOnboarding) ?? false;
    _locateOnStart = _prefs.getBool(_kLocateOnStart) ?? true;
    _recents = (_prefs.getStringList(_kRecents) ?? const [])
        .map((s) {
          try {
            return RecentPlace.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentPlace>()
        .toList();
  }

  static Future<SettingsRepository> load() async =>
      SettingsRepository._(await SharedPreferences.getInstance());

  static const _kTheme = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kMapStyle = 'map_style';
  static const _kOnboarding = 'onboarding_done';
  static const _kLocateOnStart = 'locate_on_start';
  static const _kRecents = 'recent_places';
  static const maxRecents = 6;

  final SharedPreferences _prefs;

  late ThemeMode _themeMode;
  Locale? _locale;
  late MapStyle _mapStyle;
  late bool _onboardingDone;
  late bool _locateOnStart;
  late List<RecentPlace> _recents;

  ThemeMode get themeMode => _themeMode;

  /// Null means "follow the device language".
  Locale? get locale => _locale;
  MapStyle get mapStyle => _mapStyle;
  bool get onboardingDone => _onboardingDone;

  /// Whether to find the user's ward automatically when the app opens
  /// (only if location permission was already granted).
  bool get locateOnStart => _locateOnStart;
  List<RecentPlace> get recents => List.unmodifiable(_recents);

  set themeMode(ThemeMode value) {
    _themeMode = value;
    _prefs.setInt(_kTheme, value.index);
    notifyListeners();
  }

  set locale(Locale? value) {
    _locale = value;
    _prefs.setString(_kLocale, value?.languageCode ?? '');
    notifyListeners();
  }

  set mapStyle(MapStyle value) {
    _mapStyle = value;
    _prefs.setInt(_kMapStyle, value.index);
    notifyListeners();
  }

  set onboardingDone(bool value) {
    _onboardingDone = value;
    _prefs.setBool(_kOnboarding, value);
    notifyListeners();
  }

  set locateOnStart(bool value) {
    _locateOnStart = value;
    _prefs.setBool(_kLocateOnStart, value);
    notifyListeners();
  }

  void addRecent(RecentPlace place) {
    _recents
      ..removeWhere((r) =>
          r.district == place.district && r.localLevel == place.localLevel)
      ..insert(0, place);
    if (_recents.length > maxRecents) {
      _recents.removeRange(maxRecents, _recents.length);
    }
    _saveRecents();
  }

  void clearRecents() {
    _recents.clear();
    _saveRecents();
  }

  void _saveRecents() {
    _prefs.setStringList(
        _kRecents, _recents.map((r) => jsonEncode(r.toJson())).toList());
    notifyListeners();
  }
}
