import 'package:tapaiko_ward/data/data_cache.dart';

/// In-memory [DataCache] for tests, avoiding path_provider platform calls.
class FakeDataCache implements DataCache {
  final Map<String, String> store = {};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String text) async {
    store[key] = text;
  }

  @override
  Future<void> delete(String key) async {
    store.remove(key);
  }

  @override
  Future<void> clear() async => store.clear();

  @override
  Future<int> sizeBytes() async =>
      store.values.fold<int>(0, (sum, v) => sum + v.length);
}
