import 'package:queryx_persistence/queryx_persistence.dart';
import 'package:test/test.dart';

class TestUser {
  const TestUser(this.name);
  final String name;

  @override
  bool operator ==(Object other) => other is TestUser && other.name == name;
  @override
  int get hashCode => name.hashCode;
}

final userSerializer = Serializer<TestUser>(
  encode: (u) => {'name': u.name},
  decode: (json) => TestUser(json['name'] as String),
);

void main() {
  group('initializePersistentCache', () {
    test('writes the version on first run', () async {
      final storage = InMemoryCacheStorage();
      await initializePersistentCache(storage: storage, version: 1);
      expect(await storage.readVersion(), 1);
    });

    test('leaves data alone when the version matches', () async {
      final storage = InMemoryCacheStorage();
      await storage.writeVersion(2);
      await storage.write('users', {'name': 'ada'});

      await initializePersistentCache(storage: storage, version: 2);

      expect(await storage.read('users'), {'name': 'ada'});
    });

    test('wipes storage when the version differs, then writes the new version',
        () async {
      final storage = InMemoryCacheStorage();
      await storage.writeVersion(1);
      await storage.write('users', {'name': 'ada'});

      await initializePersistentCache(storage: storage, version: 2);

      expect(await storage.read('users'), isNull);
      expect(await storage.readVersion(), 2);
    });
  });

  group('hydrateQuery', () {
    test('writes persisted data straight into the QueryClient cache', () async {
      final client = QueryClient();
      final storage = InMemoryCacheStorage();
      final key = QueryKey(['currentUser']);
      await storage.write(key.id, userSerializer.encode(const TestUser('ada')));

      await hydrateQuery<TestUser>(
        client: client,
        key: key,
        storage: storage,
        serializer: userSerializer,
      );

      expect(client.getQueryData<TestUser>(key), const TestUser('ada'));
    });

    test('does nothing when there is no persisted entry', () async {
      final client = QueryClient();
      final storage = InMemoryCacheStorage();
      final key = QueryKey(['currentUser']);

      await hydrateQuery<TestUser>(
        client: client,
        key: key,
        storage: storage,
        serializer: userSerializer,
      );

      expect(client.getQueryData<TestUser>(key), isNull);
    });

    test('drops (rather than crashes on) a corrupt entry', () async {
      final client = QueryClient();
      final storage = InMemoryCacheStorage();
      final key = QueryKey(['currentUser']);
      // Missing the 'name' field the serializer's decode expects.
      await storage.write(key.id, {'unexpected': true});

      await hydrateQuery<TestUser>(
        client: client,
        key: key,
        storage: storage,
        serializer: userSerializer,
      );

      expect(client.getQueryData<TestUser>(key), isNull);
      expect(await storage.read(key.id), isNull,
          reason: 'corrupt entry should be dropped');
    });
  });
}
