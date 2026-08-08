import 'data_service.dart';
import 'models.dart';

class MunicipalityFocus {
  MunicipalityFocus({
    required this.geometry,
    required this.properDistrict,
    this.wards = const [],
  });

  final Map<String, dynamic> geometry;
  final String properDistrict;
  final List<GeoFeature> wards;
}

class WardSummary {
  WardSummary({required this.wardNo, required this.geometry});

  final String wardNo;
  final Map<String, dynamic> geometry;
}

/// Resolves a Municipality (from locallevelcodes.json) to real geometry.
///
/// locallevelcodes.json stores DISTRICT in ALL CAPS and its GaPa_NaPa name may
/// differ from the locallevel GeoJSON `name`. District filenames use proper
/// case, so we find the real district name by case-insensitive match inside
/// districts/{provinceShort}.json before opening the locallevels file.
class MunicipalityService {
  MunicipalityService(this._data);

  final DataService _data;

  Future<List<Municipality>> municipalities() => _data.getMunicipalities();

  Future<MunicipalityFocus?> focusFor(Municipality m) async {
    final properDistrict = await _properDistrictName(m.province, m.district);
    if (properDistrict == null) return null;

    final localLevels = await _data.getJson('locallevels/$properDistrict.json');
    GeoFeature? ll;
    final features = (localLevels['features'] as List<dynamic>? ?? const []);
    for (final f in features) {
      final feature = GeoFeature.fromJson(f as Map<String, dynamic>);
      final name = feature['name'] as String? ?? '';
      final localLevel = feature['LocalLevel'] as String? ?? '';
      if (name == m.gaPaNaPa || localLevel == m.gaPaNaPa) {
        ll = feature;
        break;
      }
    }
    if (ll == null || ll.geometry == null) return null;

    final wards = await _loadWards(properDistrict, ll['name'] as String? ?? m.gaPaNaPa);
    return MunicipalityFocus(
      geometry: ll.geometry!,
      properDistrict: properDistrict,
      wards: wards,
    );
  }

  Future<String?> _properDistrictName(
      String province, String districtAllCaps) async {
    // province.json maps Province (full) -> name (short, used in filenames).
    final provinces = await _data.getJson('province.json');
    String? provinceShort;
    for (final f in (provinces['features'] as List<dynamic>? ?? const [])) {
      final feature = f as Map<String, dynamic>;
      if ((feature['properties']['Province'] ?? '') == province) {
        provinceShort = feature['properties']['name'] as String?;
        break;
      }
    }
    if (provinceShort == null) return null;

    final districts = await _data.getJson('districts/$provinceShort.json');
    for (final f in (districts['features'] as List<dynamic>? ?? const [])) {
      final feature = f as Map<String, dynamic>;
      final name = feature['properties']['District'] as String? ?? '';
      if (name.toUpperCase() == districtAllCaps.toUpperCase()) {
        return name;
      }
    }
    return null;
  }

  Future<List<GeoFeature>> _loadWards(String district, String localLevel) async {
    final fileDistrict =
        DataService.wardDistrictAliases[district] ?? district;
    final wards = await _data.getJson('wards/${fileDistrict}_$localLevel.json');
    return (wards['features'] as List<dynamic>? ?? const [])
        .map((f) => GeoFeature.fromJson(f as Map<String, dynamic>))
        .toList();
  }
}
