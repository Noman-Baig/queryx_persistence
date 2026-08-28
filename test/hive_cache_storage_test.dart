import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:queryx_persistence/queryx_persistence.dart';
import 'package:test/test.dart';

void main() {
  group('HiveCacheStorage', () {
    setUp(() async {
      await setUpTestHive();
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    test('write then read round-trips a value', () async {
      final box = await Hive.openBox('queryx_cache_test');
      final storage = HiveCacheStorage(box);

      await storage.write('users', {
        'names': ['ada', 'linus']
      });
      final result = await storage.read('users');

      expect(result, {
        'names': ['ada', 'linus']
      });
    });

    test('read returns null for a missing key', () async {
      final box = await Hive.openBox('queryx_cache_test_2');
      final storage = HiveCacheStorage(box);
      expect(await storage.read('missing'), isNull);
    });

    test('delete removes only the target key', () async {
      final box = await Hive.openBox('queryx_cache_test_3');
      final storage = HiveCacheStorage(box);
      await storage.write('a', {'x': 1});
      await storage.write('b', {'x': 2});

      await storage.delete('a');

      expect(await storage.read('a'), isNull);
      expect(await storage.read('b'), {'x': 2});
    });

    test('clear removes cached entries but preserves the version key',
        () async {
      final box = await Hive.openBox('queryx_cache_test_4');
      final storage = HiveCacheStorage(box);
      await storage.writeVersion(5);
      await storage.write('a', {'x': 1});
      await storage.write('b', {'x': 2});

      await storage.clear();

      expect(await storage.read('a'), isNull);
      expect(await storage.read('b'), isNull);
      expect(await storage.readVersion(), 5,
          reason: 'clear() must not wipe the version key');
    });

    test('version round-trips', () async {
      final box = await Hive.openBox('queryx_cache_test_5');
      final storage = HiveCacheStorage(box);
      expect(await storage.readVersion(), isNull);
      await storage.writeVersion(2);
      expect(await storage.readVersion(), 2);
    });
  });
}
