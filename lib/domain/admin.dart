import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import 'geometry.dart';

/// The four levels of Nepal's administrative hierarchy shown on the map.
enum AdminLevel { country, province, district, municipality }

/// Local level types as stored in the data (`Type_GN`).
enum LocalLevelType {
  metropolitan('Mahanagarpalika'),
  subMetropolitan('Upamahanagarpalika'),
  municipality('Nagarpalika'),
  rural('Gaunpalika'),
  other('');

  const LocalLevelType(this.raw);

  final String raw;

  static LocalLevelType parse(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    // Order matters: "upamahanagarpalika" contains "mahanagarpalika", which
    // contains "nagarpalika".
    if (v.contains('upamahanagar')) return subMetropolitan;
    if (v.contains('mahanagar')) return metropolitan;
    if (v.contains('nagar')) return municipality;
    if (v.contains('gaun')) return rural;
    return other;
  }
}

class ProvinceInfo {
  ProvinceInfo({
    required this.number,
    required this.shortName,
    required this.fullName,
    required this.feature,
  }) : bounds = geometryBounds(feature.geometry ?? const {});

  /// Province number 1–7 (Koshi = 1 … Sudurpashchim = 7).
  final int number;

  /// Short name used in filenames, e.g. "Koshi".
  final String shortName;

  /// Full name, e.g. "Koshi Pradesh".
  final String fullName;

  /// Simplified outline bundled with the app.
  final GeoFeature feature;
  final LatLngBounds? bounds;
}

class DistrictInfo {
  DistrictInfo({
    required this.name,
    required this.province,
    required this.feature,
  }) : bounds = geometryBounds(feature.geometry ?? const {});

  final String name;
  final ProvinceInfo province;

  /// Simplified outline bundled with the app.
  final GeoFeature feature;
  final LatLngBounds? bounds;
}

/// A local level (municipality / rural municipality) with its full-detail
/// boundary and ward boundaries loaded from the server.
class MunicipalityInfo {
  MunicipalityInfo({
    required this.name,
    required this.type,
    required this.district,
    required this.feature,
    required this.wards,
    this.codes,
  }) : bounds = geometryBounds(feature.geometry ?? const {});

  /// Name as used by the boundary files, e.g. "Hatuwagadhi".
  final String name;
  final LocalLevelType type;
  final DistrictInfo district;
  final GeoFeature feature;
  final LatLngBounds? bounds;

  /// Ward features, sorted by ward number.
  final List<GeoFeature> wards;

  /// Census/official codes from locallevelcodes.json, when matched.
  final Municipality? codes;

  ProvinceInfo get province => district.province;

  GeoFeature? ward(String wardNo) {
    for (final w in wards) {
      if (wardNumberOf(w) == wardNo) return w;
    }
    return null;
  }
}

/// Result of identifying a point on the map.
sealed class IdentifyResult {
  const IdentifyResult();
}

class IdentifyFound extends IdentifyResult {
  const IdentifyFound({required this.municipality, required this.ward});

  final MunicipalityInfo municipality;

  /// Null when the point falls in a gap between ward boundaries, or the
  /// area (e.g. a national park) has no wards.
  final GeoFeature? ward;
}

class IdentifyOutsideNepal extends IdentifyResult {
  const IdentifyOutsideNepal();
}

class IdentifyNotFound extends IdentifyResult {
  const IdentifyNotFound();
}

String wardNumberOf(GeoFeature ward) =>
    (ward['Ward_Num'] ?? ward['name'])?.toString() ?? '';

/// Point in Nepal's rough centre, used for the initial camera.
const nepalCenter = LatLng(28.3949, 84.1240);

final nepalBounds =
    LatLngBounds(const LatLng(26.35, 80.05), const LatLng(30.45, 88.2));
