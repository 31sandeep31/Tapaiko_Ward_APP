import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

import '../domain/admin.dart';
import '../domain/geometry.dart';
import 'data_service.dart';
import 'models.dart';

typedef AssetLoader = Future<String> Function(String key);

/// Single source of truth for Nepal's administrative boundaries.
///
/// Province and district outlines (simplified) and the list of all 753 local
/// levels are bundled with the app, so the first screen, browsing and search
/// work instantly and offline. Full-detail municipality and ward boundaries
/// are fetched on demand from the server and cached on the device.
class BoundaryRepository {
  BoundaryRepository({required DataService data, AssetLoader? assets})
      : _data = data,
        _assets = assets ?? rootBundle.loadString;

  static const provincesAsset = 'assets/geo/provinces.json';
  static const districtsAsset = 'assets/geo/districts.json';
  static const localLevelCodesAsset = 'assets/data/locallevelcodes.json';

  /// Province order matches the official numbering (Koshi = 1 …).
  static const provinceOrder = [
    'Koshi',
    'Madhesh',
    'Bagmati',
    'Gandaki',
    'Lumbini',
    'Karnali',
    'Sudurpashchim',
  ];

  /// Names in locallevelcodes.json that are spelled differently in the
  /// boundary files: (district, codes name) -> boundary file name.
  static const Map<(String, String), String> localLevelAliases = {
    ('Tanahu', 'Vyas'): 'Byas',
    ('Kapilbastu', 'Shuddhodhan'): 'Suddhodhan',
    ('Kalikot', 'Shuvakalika'): 'Kalika',
    ('Kanchanpur', 'Dodhara Chandani'): 'Mahakali',
  };

  final DataService _data;
  final AssetLoader _assets;

  List<ProvinceInfo> _provinces = const [];
  List<DistrictInfo> _districts = const [];
  List<Municipality> _municipalities = const [];
  Future<void>? _init;

  final Map<String, MunicipalityInfo> _municipalityCache = {};

  DataService get data => _data;
  List<ProvinceInfo> get provinces => _provinces;
  List<DistrictInfo> get districts => _districts;
  List<Municipality> get municipalities => _municipalities;
  bool get isReady => _provinces.isNotEmpty;

  /// Loads the bundled outlines. Safe to call more than once.
  Future<void> init() => _init ??= _loadBundled().catchError((Object e) {
        _init = null; // allow a retry
        throw e;
      });

  Future<void> _loadBundled() async {
    final texts = await Future.wait([
      _assets(provincesAsset),
      _assets(districtsAsset),
      _assets(localLevelCodesAsset),
    ]);
    final provincesJson = jsonDecode(texts[0]) as Map<String, dynamic>;
    final districtsJson = texts[1].length > 100 * 1024 && !kIsWeb
        ? await compute(_decode, texts[1])
        : _decode(texts[1]);

    final provinces = <ProvinceInfo>[];
    for (final f in _features(provincesJson)) {
      final short = f['name'] as String? ?? '';
      provinces.add(ProvinceInfo(
        number: provinceOrder.indexOf(short) + 1,
        shortName: short,
        fullName: f['Province'] as String? ?? short,
        feature: f,
      ));
    }
    provinces.sort((a, b) => a.number.compareTo(b.number));
    final byShort = {for (final p in provinces) p.shortName: p};

    final districts = <DistrictInfo>[];
    for (final f in _features(districtsJson)) {
      final province = byShort[f['ProvinceShort']];
      if (province == null) continue;
      districts.add(DistrictInfo(
        name: f['District'] as String? ?? f['name'] as String? ?? '',
        province: province,
        feature: f,
      ));
    }
    districts.sort((a, b) => a.name.compareTo(b.name));

    _municipalities = DataService.parseMunicipalities(texts[2])
      ..sort((a, b) => a.gaPaNaPa.compareTo(b.gaPaNaPa));
    _districts = districts;
    _provinces = provinces;
  }

  // ---- Lookups over bundled data ----

  ProvinceInfo? provinceByName(String name) {
    final n = name.toLowerCase();
    for (final p in _provinces) {
      if (p.shortName.toLowerCase() == n || p.fullName.toLowerCase() == n) {
        return p;
      }
    }
    return null;
  }

  DistrictInfo? districtByName(String name) {
    final n = name.toLowerCase();
    for (final d in _districts) {
      if (d.name.toLowerCase() == n) return d;
    }
    return null;
  }

  List<DistrictInfo> districtsOf(ProvinceInfo province) =>
      _districts.where((d) => d.province == province).toList();

  List<Municipality> municipalitiesOf(DistrictInfo district) {
    final upper = district.name.toUpperCase();
    return _municipalities.where((m) => m.district == upper).toList();
  }

  int municipalityCountOf(ProvinceInfo province) => _municipalities
      .where((m) => m.province.toLowerCase() == province.fullName.toLowerCase())
      .length;

  /// Official codes for a local level named as in the boundary files.
  Municipality? codesFor(String district, String localLevel) {
    final upper = district.toUpperCase();
    final name = localLevel.toLowerCase();
    String? alias;
    for (final e in localLevelAliases.entries) {
      if (e.key.$1 == district && e.value == localLevel) alias = e.key.$2;
    }
    for (final m in _municipalities) {
      if (m.district != upper) continue;
      final n = m.gaPaNaPa.toLowerCase();
      if (n == name || (alias != null && n == alias.toLowerCase())) return m;
    }
    return null;
  }

  // ---- Network-backed boundaries ----

  /// Full-detail local level boundaries of a district.
  Future<List<GeoFeature>> localLevelsOf(DistrictInfo district) async {
    final json = await _data.getJson('locallevels/${district.name}.json');
    return _features(json);
  }

  /// Ward boundaries of a local level. Empty when the area has no wards
  /// (e.g. a national park).
  Future<List<GeoFeature>> wardsOf(
      DistrictInfo district, String localLevel) async {
    final fileDistrict =
        DataService.wardDistrictAliases[district.name] ?? district.name;
    try {
      final json =
          await _data.getJson('wards/${fileDistrict}_$localLevel.json');
      final wards = _features(json)
        ..sort((a, b) {
          final na = int.tryParse(wardNumberOf(a)) ?? 0;
          final nb = int.tryParse(wardNumberOf(b)) ?? 0;
          return na.compareTo(nb);
        });
      return wards;
    } on HttpStatusException catch (e) {
      if (e.isNotFound) return const [];
      rethrow;
    }
  }

  /// Builds the full municipality (boundary + wards) from a local level
  /// feature of `locallevels/{district}.json`.
  Future<MunicipalityInfo> municipalityFromFeature(
      DistrictInfo district, GeoFeature localLevel) async {
    final name = localLevel['name'] as String? ??
        localLevel['LocalLevel'] as String? ??
        '';
    final key = '${district.name}/$name';
    final cached = _municipalityCache[key];
    if (cached != null) return cached;

    final wards = await wardsOf(district, name);
    final codes = codesFor(district.name, name) ??
        codesFor(district.name, localLevel['LocalLevel'] as String? ?? '');
    final info = MunicipalityInfo(
      name: name,
      type: LocalLevelType.parse(
          localLevel['Type'] as String? ?? codes?.typeGn),
      district: district,
      feature: localLevel,
      wards: wards,
      codes: codes,
    );
    _municipalityCache[key] = info;
    return info;
  }

  /// Resolves a local level from locallevelcodes.json (search results) to
  /// its boundary and wards. Returns null when no boundary is available.
  Future<MunicipalityInfo?> municipalityFor(Municipality m) async {
    final district = districtByName(m.district);
    if (district == null) return null;
    final target = localLevelAliases[(district.name, m.gaPaNaPa)] ??
        m.gaPaNaPa;
    final features = await localLevelsOf(district);
    GeoFeature? match;
    for (final f in features) {
      if (f['name'] == target || f['LocalLevel'] == target) {
        match = f;
        break;
      }
    }
    if (match == null) {
      final t = _normalize(target);
      for (final f in features) {
        if (_normalize(f['name'] as String? ?? '') == t ||
            _normalize(f['LocalLevel'] as String? ?? '') == t) {
          match = f;
          break;
        }
      }
    }
    if (match == null) return null;
    return municipalityFromFeature(district, match);
  }

  /// Reopens a local level by district + boundary-file name (recent places).
  Future<MunicipalityInfo?> municipalityByName(
      String districtName, String localLevel) async {
    final district = districtByName(districtName);
    if (district == null) return null;
    final cached = _municipalityCache['${district.name}/$localLevel'];
    if (cached != null) return cached;
    for (final f in await localLevelsOf(district)) {
      if (f['name'] == localLevel || f['LocalLevel'] == localLevel) {
        return municipalityFromFeature(district, f);
      }
    }
    return null;
  }

  /// Identifies the municipality and ward containing [point].
  ///
  /// Candidate districts come from the bundled (simplified) outlines; exact
  /// containment is decided with the full-detail municipality boundaries, so
  /// a point near a district border still resolves correctly.
  Future<IdentifyResult> identify(LatLng point) async {
    await init();
    if (!boundsContains(nepalBounds, point, margin: 0.05)) {
      return const IdentifyOutsideNepal();
    }

    final inside = <DistrictInfo>[];
    final nearby = <DistrictInfo>[];
    for (final d in _districts) {
      final b = d.bounds;
      if (b == null || !boundsContains(b, point, margin: 0.03)) continue;
      final g = d.feature.geometry;
      if (g != null && pointInGeometry(point, g)) {
        inside.add(d);
      } else {
        nearby.add(d);
      }
    }
    if (inside.isEmpty && nearby.isEmpty) return const IdentifyOutsideNepal();
    nearby.sort((a, b) => distanceToBoundsCenter(point, a.bounds!)
        .compareTo(distanceToBoundsCenter(point, b.bounds!)));

    // A point just outside the simplified outlines is most likely across the
    // border, so only check a couple of nearby districts in that case.
    final candidates = inside.isNotEmpty
        ? [...inside, ...nearby.take(3)]
        : nearby.take(2).toList();
    for (final district in candidates) {
      final features = await localLevelsOf(district);
      for (final f in features) {
        final g = f.geometry;
        if (g == null || !pointInGeometry(point, g)) continue;
        final municipality = await municipalityFromFeature(district, f);
        GeoFeature? ward;
        for (final w in municipality.wards) {
          final wg = w.geometry;
          if (wg != null && pointInGeometry(point, wg)) {
            ward = w;
            break;
          }
        }
        return IdentifyFound(municipality: municipality, ward: ward);
      }
    }
    return inside.isEmpty
        ? const IdentifyOutsideNepal()
        : const IdentifyNotFound();
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  static List<GeoFeature> _features(Map<String, dynamic> collection) {
    final features = (collection['features'] as List<dynamic>?) ?? const [];
    return features
        .map((f) => GeoFeature.fromJson(f as Map<String, dynamic>))
        .toList();
  }
}

Map<String, dynamic> _decode(String text) =>
    jsonDecode(text) as Map<String, dynamic>;
