/// Cache abstraction. On Android/iOS it's an on-disk dir; on web (no
/// filesystem) it's an in-memory map. Selected via conditional import.
abstract class DataCache {
  Future<String?> read(String key);
  Future<void> write(String key, String text);
}
