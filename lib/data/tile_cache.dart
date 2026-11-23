import 'package:flutter_map/flutter_map.dart';

import 'tile_cache_size_io.dart'
    if (dart.library.js_interop) 'tile_cache_size_web.dart';

/// Manages flutter_map's built-in on-device tile cache.
abstract final class TileCache {
  static const maxBytes = 300 * 1024 * 1024;

  /// Configures the cache size limit. Call once at startup, before any map
  /// is shown.
  static void configure() {
    BuiltInMapCachingProvider.getOrCreateInstance(maxCacheSize: maxBytes);
  }

  static Future<int> sizeBytes() => tileCacheSizeBytes();

  static Future<void> clear() async {
    await BuiltInMapCachingProvider.getOrCreateInstance()
        .destroy(deleteCache: true);
    configure();
  }
}
