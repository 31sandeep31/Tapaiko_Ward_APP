import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'data_cache.dart';

/// On-disk cache under the app documents dir. Used on Android/iOS.
DataCache createCache() => _DiskCache();

class _DiskCache implements DataCache {
  Directory? _dir;

  Future<Directory> _ensureDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/tapaiko_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  @override
  Future<String?> read(String key) async {
    final dir = await _ensureDir();
    final file = File('${dir.path}/${_safeName(key)}');
    if (await file.exists()) {
      try {
        return await file.readAsString();
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<void> write(String key, String text) async {
    final dir = await _ensureDir();
    final file = File('${dir.path}/${_safeName(key)}');
    try {
      await file.writeAsString(text);
    } catch (_) {}
  }

  String _safeName(String path) =>
      path.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
}
