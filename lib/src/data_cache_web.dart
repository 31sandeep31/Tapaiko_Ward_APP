import 'data_cache.dart';

/// In-memory cache for web builds (no filesystem access).
DataCache createCache() => _MemoryCache();

class _MemoryCache implements DataCache {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String text) async {
    _store[key] = text;
  }
}
