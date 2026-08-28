import 'package:hive/hive.dart';
import 'package:queryx/queryx.dart';

/// A [CacheStorage] backed by a Hive [Box]. The app owns opening (and, in
/// Flutter, initializing Hive's storage path via `hive_flutter` or
/// `path_provider`) — this class just reads/writes an already-open box, so
/// it stays platform-agnostic:
///
/// ```dart
/// await Hive.initFlutter(); // or Hive.init(path) outside Flutter
/// final box = await Hive.openBox('queryx_cache');
/// final storage = HiveCacheStorage(box);
/// ```
///
/// Values are stored as plain `Map`s — Hive handles the binary encoding
/// itself, no manual JSON encode/decode needed.
class HiveCacheStorage implements CacheStorage {
  HiveCacheStorage(this._box, {this.versionKey = '__queryx_version__'});

  final Box<dynamic> _box;

  /// Key used to store the schema version inside the same box. Change this
  /// only if `__queryx_version__` collides with one of your own query keys
  /// (astronomically unlikely, since query key ids are derived from
  /// `QueryKey` parts).
  final String versionKey;

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    await _box.put(key, Map<String, dynamic>.from(value));
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    final keysToRemove = _box.keys.where((k) => k != versionKey).toList();
    await _box.deleteAll(keysToRemove);
  }

  @override
  Future<int?> readVersion() async => _box.get(versionKey) as int?;

  @override
  Future<void> writeVersion(int version) async {
    await _box.put(versionKey, version);
  }
}
