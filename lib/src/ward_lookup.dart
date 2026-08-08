import 'package:latlong2/latlong.dart';

import 'data_service.dart';
import 'geometry.dart';
import 'models.dart';

/// Identifies features at each admin level (province → district → local
/// level → ward) by drilling down the hierarchy, loading only the small
/// per-area file at each step.
class WardLookup {
  WardLookup(this._data);

  final DataService _data;

  Future<GeoFeature?> findProvince(LatLng point) async {
    final provinces = await _data.getJson('province.json');
    return _findContaining(provinces, point);
  }

  Future<GeoFeature?> findDistrict(LatLng point, String provinceShort) async {
    final districts = await _data.getJson('districts/$provinceShort.json');
    return _findContaining(districts, point);
  }

  Future<GeoFeature?> findLocalLevel(LatLng point, String districtName) async {
    final localLevels = await _data.getJson('locallevels/$districtName.json');
    return _findContaining(localLevels, point);
  }

  Future<GeoFeature?> findWard(
      LatLng point, String districtName, String localLevelName) async {
    final fileDistrict =
        DataService.wardDistrictAliases[districtName] ?? districtName;
    final wards =
        await _data.getJson('wards/${fileDistrict}_$localLevelName.json');
    return _findContaining(wards, point);
  }

  Future<List<GeoFeature>> loadDistricts(String provinceShort) async {
    final json = await _data.getJson('districts/$provinceShort.json');
    return _features(json);
  }

  Future<List<GeoFeature>> loadLocalLevels(String districtName) async {
    final json = await _data.getJson('locallevels/$districtName.json');
    return _features(json);
  }

  Future<List<GeoFeature>> loadWards(
      String districtName, String localLevelName) async {
    final fileDistrict =
        DataService.wardDistrictAliases[districtName] ?? districtName;
    final json =
        await _data.getJson('wards/${fileDistrict}_$localLevelName.json');
    return _features(json);
  }

  /// Full drill-down (province → district → local level → ward) in one call,
  /// used by the GPS "find my ward" button.
  Future<WardResult?> identify(LatLng point) async {
    final province = await findProvince(point);
    if (province == null) return null;
    final provinceName = province['Province'] as String? ?? '';
    final provinceShort = province['name'] as String? ?? '';

    final district = await findDistrict(point, provinceShort);
    if (district == null) return null;
    final districtName = district['District'] as String? ??
        district['name'] as String? ??
        '';

    final localLevel = await findLocalLevel(point, districtName);
    if (localLevel == null) return null;
    final localLevelName = localLevel['name'] as String? ?? '';
    final llDistrict = localLevel['District'] as String? ?? districtName;

    final ward = await findWard(point, llDistrict, localLevelName);
    if (ward == null) return null;

    return WardResult(
      wardNo: ward['name'] as String? ??
          (ward['Ward_Num']?.toString() ?? ''),
      municipality: ward['GaPa_NaPa'] as String? ?? localLevelName,
      type: ward['Type_GN'] as String? ?? '',
      district: districtName,
      province: provinceName,
      wardGeometry: ward.geometry ?? const {},
    );
  }

  List<GeoFeature> _features(Map<String, dynamic> collection) {
    final features = (collection['features'] as List<dynamic>?) ?? const [];
    return features
        .map((f) => GeoFeature.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  GeoFeature? _findContaining(
      Map<String, dynamic> collection, LatLng point) {
    for (final f in _features(collection)) {
      final geometry = f.geometry;
      if (geometry != null && pointInGeometry(point, geometry)) {
        return f;
      }
    }
    return null;
  }
}
