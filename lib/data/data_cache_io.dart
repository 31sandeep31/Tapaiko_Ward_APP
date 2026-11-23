import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'data_cache.dart';

/// On-disk cache under the app support dir. Used on Android/iOS.
DataCache createCache() => _DiskCache();

class _DiskCache implements DataCache {
  Directory? _dir;

  Future<Directory> _ensureDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/boundary_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  Future<File> _file(String key) async =>
      File('${(await _ensureDir()).path}/${_safeName(key)}');

  @override
  Future<String?> read(String key) async {
    final file = await _file(key);
    if (await file.exists()) {
      try {
        return await file.readAsString();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> write(String key, String text) async {
    final file = await _file(key);
    try {
      // Write to a temp file first so a crash never leaves a half-written
      // (corrupt) cache entry behind.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(text, flush: true);
      await tmp.rename(file.path);
    } catch (_) {}
  }

  @override
  Future<void> delete(String key) async {
    final file = await _file(key);
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    final dir = await _ensureDir();
    try {
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    } catch (_) {}
  }

  @override
  Future<int> sizeBytes() async {
    final dir = await _ensureDir();
    var total = 0;
    try {
      await for (final entity in dir.list()) {
        if (entity is File) total += await entity.length();
      }
    } catch (_) {}
    return total;
  }

  String _safeName(String path) =>
      path.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
}
