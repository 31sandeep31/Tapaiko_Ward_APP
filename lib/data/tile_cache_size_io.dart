import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<int> tileCacheSizeBytes() async {
  try {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/fm_cache');
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) total += await e.length();
    }
    return total;
  } catch (_) {
    return 0;
  }
}
