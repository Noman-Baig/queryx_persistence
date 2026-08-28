import 'package:queryx/queryx.dart';

/// A [CacheStorage] backed by a plain in-memory [Map]. Doesn't actually
/// persist anything across process restarts — useful for tests, and as the
/// simplest possible reference for what a [CacheStorage] implementation
/// looks like.
class InMemoryCacheStorage implements CacheStorage {
  final Map<String, Map<String, dynamic>> _data = {};
  int? _version;

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    _data[key] = Map<String, dynamic>.from(value);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final value = _data[key];
    return value == null ? null : Map<String, dynamic>.from(value);
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<int?> readVersion() async => _version;

  @override
  Future<void> writeVersion(int version) async => _version = version;
}
