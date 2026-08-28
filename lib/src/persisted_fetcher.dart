import 'package:queryx/queryx.dart';

/// Wraps [fetcher] so that every successful result is also written to
/// [storage] via [serializer] — the "Memory Cache → Persistent Cache" half
/// of spec §19. Persistence failures never break the query itself; they're
/// swallowed so a full disk or a serialization bug degrades to "just don't
/// persist this one," not "the query is now broken."
///
/// ```dart
/// final users = client.query(
///   QueryKey(['users']),
///   persistedFetcher(
///     key: QueryKey(['users']),
///     fetcher: () => api.getUsers(),
///     storage: storage,
///     serializer: userListSerializer,
///   ),
/// );
/// ```
Fetcher<T> persistedFetcher<T>({
  required QueryKey key,
  required Fetcher<T> fetcher,
  required CacheStorage storage,
  required Serializer<T> serializer,
}) {
  return () async {
    final result = await fetcher();
    try {
      await storage.write(key.id, serializer.encode(result));
    } catch (_) {
      // See doc comment above — never let a persistence failure surface as
      // a query failure.
    }
    return result;
  };
}
