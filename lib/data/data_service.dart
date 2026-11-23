import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'data_cache.dart';
import 'data_cache_io.dart' if (dart.library.js_interop) 'data_cache_web.dart';
import 'models.dart';

/// Thrown when the server answers with a non-200 status.
class HttpStatusException implements Exception {
  HttpStatusException(this.statusCode, this.path);

  final int statusCode;
  final String path;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'HTTP $statusCode fetching $path';
}

/// Thrown when the device can't reach the server (offline, DNS, timeout).
class NetworkException implements Exception {
  NetworkException(this.path, this.cause);

  final String path;
  final Object cause;

  @override
  String toString() => 'Network error fetching $path: $cause';
}

/// Fetches GeoJSON from the live site and caches responses (on-disk on
/// Android/iOS, in-memory on web) so repeat lookups are fast and work offline.
class DataService {
  DataService({http.Client? client, DataCache? cache})
      : _client = client ?? http.Client(),
        _cache = cache ?? createCache();

  static const String baseUrl = 'https://maps.sandeepkafle.com.np/data/';
  static const Duration timeout = Duration(seconds: 30);

  /// Ward files are stored under the legacy district name "Rukum".
  static const Map<String, String> wardDistrictAliases = {
    'Rukum East': 'Rukum',
    'Rukum West': 'Rukum',
  };

  /// Files above this size are decoded on a background isolate so the UI
  /// never janks while a large boundary file is parsed.
  static const int _isolateThreshold = 200 * 1024;

  final http.Client _client;
  final DataCache _cache;
  final Map<String, Map<String, dynamic>> _jsonCache = {};
  final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  Future<Map<String, dynamic>> getJson(String path) {
    final hit = _jsonCache[path];
    if (hit != null) return SynchronousFuture(hit);
    // De-duplicate concurrent requests for the same file.
    return _inFlight[path] ??= _load(path).whenComplete(() {
      _inFlight.remove(path);
    });
  }

  Future<Map<String, dynamic>> _load(String path) async {
    final cached = await _cache.read(path);
    if (cached != null) {
      try {
        final decoded = await _decode(cached);
        _jsonCache[path] = decoded;
        return decoded;
      } catch (_) {
        // Corrupt cache entry: drop it and fetch a fresh copy.
        await _cache.delete(path);
      }
    }
    final text = await _fetch(path);
    final decoded = await _decode(text);
    await _cache.write(path, text);
    _jsonCache[path] = decoded;
    return decoded;
  }

  Future<List<Municipality>> getMunicipalities() async {
    var text = await _cache.read('locallevelcodes.json');
    if (text == null) {
      text = await _fetch('locallevelcodes.json');
      await _cache.write('locallevelcodes.json', text);
    }
    return parseMunicipalities(text);
  }

  static List<Municipality> parseMunicipalities(String text) {
    // File has a UTF-8 BOM.
    final clean = text.startsWith('﻿') ? text.substring(1) : text;
    final list = jsonDecode(clean) as List<dynamic>;
    return list
        .map((e) => Municipality.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Size of the on-device boundary cache, in bytes.
  Future<int> cacheSize() => _cache.sizeBytes();

  /// Clears both the in-memory and on-device boundary caches.
  Future<void> clearCache() async {
    _jsonCache.clear();
    await _cache.clear();
  }

  Future<String> _fetch(String path) async {
    final http.Response resp;
    try {
      resp = await _client
          .get(Uri.parse('$baseUrl${Uri.encodeFull(path)}'))
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw NetworkException(path, e);
    } on http.ClientException catch (e) {
      throw NetworkException(path, e);
    }
    if (resp.statusCode != 200) {
      throw HttpStatusException(resp.statusCode, path);
    }
    return utf8.decode(resp.bodyBytes);
  }

  static Future<Map<String, dynamic>> _decode(String text) async {
    if (text.length > _isolateThreshold && !kIsWeb) {
      return compute(_decodeMap, text);
    }
    return _decodeMap(text);
  }
}

Map<String, dynamic> _decodeMap(String text) {
  final clean = text.startsWith('﻿') ? text.substring(1) : text;
  return jsonDecode(clean) as Map<String, dynamic>;
}
