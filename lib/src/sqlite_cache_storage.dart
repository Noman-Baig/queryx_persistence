import 'dart:convert';

import 'package:queryx/queryx.dart';
import 'package:sqlite3/sqlite3.dart';

/// A [CacheStorage] backed by [sqlite3] — a pure-Dart FFI binding, no
/// platform channels, so this works identically on every platform sqlite3
/// itself supports (including outside Flutter). Values are JSON-encoded
/// into a single `TEXT` column.
///
/// ```dart
/// final db = sqlite3.open('queryx_cache.db'); // or sqlite3.openInMemory() for tests
/// final storage = SqliteCacheStorage(db);
/// ```
///
/// The app owns the [Database] lifecycle (opening it at the right path,
/// closing it on shutdown) — this class only creates its one table and
/// operates on it.
class SqliteCacheStorage implements CacheStorage {
  SqliteCacheStorage(this._db, {this.tableName = 'queryx_cache'}) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
  }

  final Database _db;
  final String tableName;

  static const _versionKey = '__queryx_version__';

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    _db.execute(
      'INSERT OR REPLACE INTO $tableName (key, value) VALUES (?, ?)',
      [key, jsonEncode(value)],
    );
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final rows = _db.select(
      'SELECT value FROM $tableName WHERE key = ?',
      [key],
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['value'] as String) as Map<String, dynamic>;
  }

  @override
  Future<void> delete(String key) async {
    _db.execute('DELETE FROM $tableName WHERE key = ?', [key]);
  }

  @override
  Future<void> clear() async {
    _db.execute('DELETE FROM $tableName WHERE key != ?', [_versionKey]);
  }

  @override
  Future<int?> readVersion() async {
    final rows = _db.select(
      'SELECT value FROM $tableName WHERE key = ?',
      [_versionKey],
    );
    if (rows.isEmpty) return null;
    return int.tryParse(rows.first['value'] as String);
  }

  @override
  Future<void> writeVersion(int version) async {
    _db.execute(
      'INSERT OR REPLACE INTO $tableName (key, value) VALUES (?, ?)',
      [_versionKey, version.toString()],
    );
  }
}
