import 'dart:convert';

import 'package:http/http.dart' as http;

import 'data_cache.dart';
import 'data_cache_io.dart' if (dart.library.js_interop) 'data_cache_web.dart';
import 'models.dart';

/// Fetches GeoJSON from the live site and caches responses (on-disk on
/// Android/iOS, in-memory on web) so repeat lookups are fast and work offline.
class DataService {
  DataService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://maps.sandeepkafle.com.np/data/';

  /// Ward files are stored under the legacy district name "Rukum".
  static const Map<String, String> wardDistrictAliases = {
    'Rukum East': 'Rukum',
    'Rukum West': 'Rukum',
  };

  final http.Client _client;
  final DataCache _cache = createCache();
  final Map<String, dynamic> _jsonCache = {};

  Future<Map<String, dynamic>> getJson(String path) async {
    final hit = _jsonCache[path];
    if (hit != null) return hit as Map<String, dynamic>;

    final text = await _fetchWithCache(path);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    _jsonCache[path] = decoded;
    return decoded;
  }

  Future<List<Municipality>> getMunicipalities() async {
    final text = await _fetchWithCache('locallevelcodes.json');
    // File has a UTF-8 BOM.
    final clean = text.startsWith('\uFEFF') ? text.substring(1) : text;
    final list = jsonDecode(clean) as List<dynamic>;
    return list
        .map((e) => Municipality.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> _fetchWithCache(String path) async {
    final cached = await _cache.read(path);
    if (cached != null) return cached;

    final resp = await _client.get(Uri.parse('$baseUrl$path'));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} fetching $path');
    }
    final text = utf8.decode(resp.bodyBytes);
    await _cache.write(path, text);
    return text;
  }
}
