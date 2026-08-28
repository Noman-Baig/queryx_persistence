import 'package:queryx_persistence/queryx_persistence.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteCacheStorage', () {
    late Database db;

    setUp(() {
      db = sqlite3.openInMemory();
    });

    tearDown(() {
      db.dispose();
    });

    test('write then read round-trips a value', () async {
      final storage = SqliteCacheStorage(db);
      await storage.write('users', {'names': ['ada', 'linus']});
      final result = await storage.read('users');
      expect(result, {'names': ['ada', 'linus']});
    });

    test('read returns null for a missing key', () async {
      final storage = SqliteCacheStorage(db);
      expect(await storage.read('missing'), isNull);
    });

    test('write with the same key overwrites (INSERT OR REPLACE)', () async {
      final storage = SqliteCacheStorage(db);
      await storage.write('users', {'v': 1});
      await storage.write('users', {'v': 2});
      expect(await storage.read('users'), {'v': 2});
    });

    test('delete removes only the target key', () async {
      final storage = SqliteCacheStorage(db);
      await storage.write('a', {'x': 1});
      await storage.write('b', {'x': 2});
      await storage.delete('a');
      expect(await storage.read('a'), isNull);
      expect(await storage.read('b'), {'x': 2});
    });

    test('clear removes cached entries but preserves the version key', () async {
      final storage = SqliteCacheStorage(db);
      await storage.writeVersion(5);
      await storage.write('a', {'x': 1});
      await storage.write('b', {'x': 2});

      await storage.clear();

      expect(await storage.read('a'), isNull);
      expect(await storage.read('b'), isNull);
      expect(await storage.readVersion(), 5);
    });

    test('version round-trips', () async {
      final storage = SqliteCacheStorage(db);
      expect(await storage.readVersion(), isNull);
      await storage.writeVersion(4);
      expect(await storage.readVersion(), 4);
    });

    test('two SqliteCacheStorage instances over the same db share the table',
        () async {
      final a = SqliteCacheStorage(db);
      final b = SqliteCacheStorage(db); // CREATE TABLE IF NOT EXISTS is idempotent
      await a.write('shared', {'x': 1});
      expect(await b.read('shared'), {'x': 1});
    });
  });
}
