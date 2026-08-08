import 'dart:convert';

import 'package:http/http.dart' as http;

import 'data_service.dart';

/// Male/female population per ward from the CBS census API.
class CensusData {
  CensusData({required this.male, required this.female});

  final List<int> male;
  final List<int> female;

  int get totalMale => male.fold(0, (a, b) => a + b);
  int get totalFemale => female.fold(0, (a, b) => a + b);
  int get totalPopulation => totalMale + totalFemale;
  int get wardCount => male.length;

  /// Population of the ward with the given 1-based number, if in range.
  int? wardPopulation(int wardNo) {
    final i = wardNo - 1;
    if (i < 0 || i >= male.length) return null;
    return male[i] + female[i];
  }
}

/// Wraps the CBS census API (same endpoint the web app uses for the
/// population chart).
class CensusService {
  CensusService(this._data);

  final DataService _data;
  final http.Client _client = http.Client();

  static const String _baseUrl =
      'https://censusapi.cbs.gov.np/api/v1/population/distribution/ward';

  /// Resolves the census codes for a local level by matching the municipality
  /// metadata (case-insensitive, like the web app does).
  Future<CensusData?> fetchFor({
    required String province,
    required String district,
    required String municipality,
  }) async {
    try {
      final codes = await _resolveCodes(province, district, municipality);
      if (codes == null) return null;
      final uri = Uri.parse(
          '$_baseUrl?province=${codes.state}&district=${codes.district}'
          '&municipality=${codes.municipality}');
      final resp = await _client.get(uri);
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || json['success'] != true) {
        return null;
      }
      final series =
          ((json['data'] as Map<String, dynamic>?)?['series'] as List?) ??
              const [];
      List<int> male = const [], female = const [];
      for (final s in series) {
        final map = s as Map<String, dynamic>;
        final name = map['name'] as String?;
        final data = ((map['data'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList();
        if (name == 'male') male = data;
        if (name == 'female') female = data;
      }
      if (male.isEmpty && female.isEmpty) return null;
      return CensusData(male: male, female: female);
    } catch (_) {
      return null;
    }
  }

  Future<({int state, int district, int municipality})?> _resolveCodes(
    String province,
    String district,
    String municipality,
  ) async {
    final list = await _data.getMunicipalities();
    for (final m in list) {
      if (m.province.toLowerCase() == province.toLowerCase() &&
          m.district.toLowerCase() == district.toLowerCase() &&
          m.gaPaNaPa.toLowerCase() == municipality.toLowerCase()) {
        return (
          state: m.stateCode,
          district: m.districtCode,
          municipality: m.municipalityCode,
        );
      }
    }
    return null;
  }
}
