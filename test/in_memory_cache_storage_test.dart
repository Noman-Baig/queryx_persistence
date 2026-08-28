import 'package:queryx_persistence/queryx_persistence.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryCacheStorage', () {
    test('write then read round-trips a value', () async {
      final storage = InMemoryCacheStorage();
      await storage.write('users', {'names': ['ada', 'linus']});
      final result = await storage.read('users');
      expect(result, {'names': ['ada', 'linus']});
    });

    test('read returns null for a missing key', () async {
      final storage = InMemoryCacheStorage();
      expect(await storage.read('missing'), isNull);
    });

    test('delete removes a key', () async {
      final storage = InMemoryCacheStorage();
      await storage.write('users', {'a': 1});
      await storage.delete('users');
      expect(await storage.read('users'), isNull);
    });

    test('clear removes everything', () async {
      final storage = InMemoryCacheStorage();
      await storage.write('a', {'x': 1});
      await storage.write('b', {'x': 2});
      await storage.clear();
      expect(await storage.read('a'), isNull);
      expect(await storage.read('b'), isNull);
    });

    test('version defaults to null and round-trips once written', () async {
      final storage = InMemoryCacheStorage();
      expect(await storage.readVersion(), isNull);
      await storage.writeVersion(3);
      expect(await storage.readVersion(), 3);
    });
  });
}
