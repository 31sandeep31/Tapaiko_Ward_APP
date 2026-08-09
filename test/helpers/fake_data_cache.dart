import 'package:tapaiko_ward/src/data_cache.dart';

/// In-memory [DataCache] for tests, avoiding path_provider platform calls.
class FakeDataCache implements DataCache {
  final Map<String, String> store = {};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String text) async {
    store[key] = text;
  }
}
