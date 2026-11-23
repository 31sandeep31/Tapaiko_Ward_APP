import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'data_service.dart';
import 'models.dart';

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
    if (i < 0 || i >= male.length || i >= female.length) return null;
    return male[i] + female[i];
  }

  int? wardMale(int wardNo) =>
      wardNo >= 1 && wardNo <= male.length ? male[wardNo - 1] : null;

  int? wardFemale(int wardNo) =>
      wardNo >= 1 && wardNo <= female.length ? female[wardNo - 1] : null;
}

/// Wraps the CBS census API (National Population and Housing Census 2021).
class CensusService {
  CensusService(this._data, {http.Client? client})
      : _client = client ?? http.Client();

  final DataService _data;
  final http.Client _client;
  final Map<int, CensusData?> _cache = {};

  static const String _baseUrl =
      'https://censusapi.cbs.gov.np/api/v1/population/distribution/ward';

  /// Resolves the census codes for a local level by matching the municipality
  /// metadata (case-insensitive), then fetches its ward populations.
  Future<CensusData?> fetchFor({
    required String province,
    required String district,
    required String municipality,
  }) async {
    try {
      final list = await _data.getMunicipalities();
      for (final m in list) {
        if (m.province.toLowerCase() == province.toLowerCase() &&
            m.district.toLowerCase() == district.toLowerCase() &&
            m.gaPaNaPa.toLowerCase() == municipality.toLowerCase()) {
          return fetchByCodes(m);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches ward populations for a local level with known codes. Returns
  /// null when the API is unreachable or has no data. Results are memoised.
  Future<CensusData?> fetchByCodes(Municipality m) async {
    final key = m.stateCode * 1000000 + m.districtCode * 1000 +
        m.municipalityCode;
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final uri = Uri.parse(
          '$_baseUrl?province=${m.stateCode}&district=${m.districtCode}'
          '&municipality=${m.municipalityCode}');
      final resp =
          await _client.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || json['success'] != true) {
        return _cache[key] = null;
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
      if (male.isEmpty && female.isEmpty) return _cache[key] = null;
      return _cache[key] = CensusData(male: male, female: female);
    } catch (_) {
      // Network errors aren't cached so a later attempt can succeed.
      return null;
    }
  }
}
