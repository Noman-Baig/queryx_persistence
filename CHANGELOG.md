# Changelog

## 0.1.0

Initial release.

- `HiveCacheStorage` — `CacheStorage` backed by a Hive `Box`.
- `SqliteCacheStorage` — `CacheStorage` backed by `sqlite3` (pure-Dart FFI,
  no platform channels).
- `InMemoryCacheStorage` — non-persistent reference implementation, used
  in this package's own tests.
- `initializePersistentCache` — schema-version check on startup; wipes
  storage on a version mismatch instead of risking a crash deserializing
  incompatible data.
- `hydrateQuery<T>` — reads + decodes a persisted entry straight into a
  `QueryClient`'s in-memory cache via `setQueryData`; drops (rather than
  crashes on) a corrupt individual entry.
- `persistedFetcher<T>` — wraps any fetcher for write-through persistence;
  a failing disk write never surfaces as a query failure.
- Test suite (plain `dart test`): full CRUD + version behavior for all
  three `CacheStorage` implementations (Hive via `hive_test`'s in-memory
  setup, sqlite3 via `sqlite3.openInMemory()`), hydration success/empty/
  corrupt-entry paths, version-mismatch wiping, and write-through
  composed with a real `QueryClient` query.

### Not included yet

- **Isar** adapter — Isar's code-generation step (`isar_generator` +
  `build_runner`) didn't fit this package's zero-build-step philosophy
  for a first release. The `CacheStorage` interface is small; an Isar
  adapter is a welcome contribution following `SqliteCacheStorage`'s
  shape.
