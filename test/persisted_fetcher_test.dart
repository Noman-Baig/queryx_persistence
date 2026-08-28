import 'package:queryx_persistence/queryx_persistence.dart';
import 'package:test/test.dart';

final intSerializer = Serializer<int>(
  encode: (n) => {'value': n},
  decode: (json) => json['value'] as int,
);

class _FailingStorage extends InMemoryCacheStorage {
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    throw Exception('disk full');
  }
}

void main() {
  group('persistedFetcher', () {
    test('writes the result to storage after a successful fetch', () async {
      final storage = InMemoryCacheStorage();
      final key = QueryKey(['counter']);
      final fetcher = persistedFetcher<int>(
        key: key,
        fetcher: () async => 42,
        storage: storage,
        serializer: intSerializer,
      );

      final result = await fetcher();

      expect(result, 42);
      expect(await storage.read(key.id), {'value': 42});
    });

    test('a persistence failure does not break the fetch result', () async {
      final storage = _FailingStorage();
      final key = QueryKey(['counter']);
      final fetcher = persistedFetcher<int>(
        key: key,
        fetcher: () async => 7,
        storage: storage,
        serializer: intSerializer,
      );

      final result = await fetcher();

      expect(result, 7, reason: 'a failing disk write must not surface as a fetch failure');
    });

    test('composes with QueryClient like any other fetcher', () async {
      final client = QueryClient();
      final storage = InMemoryCacheStorage();
      final key = QueryKey(['counter']);

      final query = client.query<int>(
        key,
        persistedFetcher<int>(
          key: key,
          fetcher: () async => 99,
          storage: storage,
          serializer: intSerializer,
        ),
      );

      final result = await query.ensureFetched();

      expect(result, 99);
      expect(await storage.read(key.id), {'value': 99});
    });
  });
}
