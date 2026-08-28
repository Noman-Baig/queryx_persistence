<p align="center">
  <img
    src="https://raw.githubusercontent.com/Noman-Baig/queryx_dio/main/assets/logo.jpg"
    alt="QueryX Persistence"
    width="220"
    style="border-radius: 24px;"
  />
</p>

<h1 align="center">queryx_persistence</h1>

<p align="center">
  Persistent cache adapters for QueryX with offline-first support.
</p>

<p align="center">
  <a href="https://pub.dev/packages/queryx_persistence">
    <img src="https://img.shields.io/pub/v/queryx_persistence.svg" alt="pub.dev version"/>
  </a>
  <a href="https://pub.dev/packages/queryx_persistence/score">
    <img src="https://img.shields.io/pub/likes/queryx_persistence.svg" alt="pub.dev likes"/>
  </a>
  <a href="https://github.com/Noman-Baig/queryx_persistence/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/Noman-Baig/queryx_persistence/test.yml" alt="CI"/>
  </a>
  <img src="https://img.shields.io/badge/Pure%20Dart-compatible-blueviolet" alt="Pure Dart"/>
</p>

<p align="center">
  Disk-backed caching for QueryX — Hive and SQLite storage,
  startup hydration, cache versioning, and write-through persistence.
</p>

---
# Details

Persistent cache adapters for [`queryx`](../queryx) — disk-backed
`CacheStorage` implementations, plus the two things that turn "a place to
save bytes" into actual offline-first behavior: hydrating the in-memory
cache from disk at startup, and writing successful fetches back to disk.

Pure Dart, like [`queryx`](https://pub.dev/packages/queryx) and
[`queryx_dio`](https://pub.dev/packages/queryx_dio) — neither Hive's core package nor
sqlite3's FFI bindings need Flutter, so this is unit-testable with plain
`dart test`.

## Backends

| Backend | Class | Notes |
|---|---|---|
| Hive | `HiveCacheStorage` | Wraps an already-open `Box`. You own `Hive.init(...)`/`Hive.openBox(...)` — this class doesn't manage Hive's storage path, so it works the same in Flutter (with `hive_flutter`/`path_provider`) or plain Dart. |
| sqlite3 | `SqliteCacheStorage` | Wraps an already-open `Database`. Pure-Dart FFI, no platform channels. |
| In-memory | `InMemoryCacheStorage` | Doesn't actually persist across restarts — useful for tests, or as a reference for writing your own `CacheStorage`. |

Isar isn't included yet (its code-generation step didn't fit this
package's zero-build-step philosophy) — see `CHANGELOG.md`. The
`CacheStorage` interface is small enough that adding it, or any other
backend, is mostly copying `SqliteCacheStorage`'s shape.

## Setup

```dart
// Hive
await Hive.initFlutter(); // or Hive.init(path) outside Flutter
final storage = HiveCacheStorage(await Hive.openBox('queryx_cache'));

// or sqlite3
final storage = SqliteCacheStorage(sqlite3.open('queryx_cache.db'));

const cacheVersion = 1; // bump when a cached model's shape changes
await initializePersistentCache(storage: storage, version: cacheVersion);
```

`initializePersistentCache` is spec §71 (Cache Versioning): if the version
on disk doesn't match, the whole store is wiped rather than risking a
crash deserializing an old, incompatible shape. Call it once per app
launch, before hydrating any individual query.

## Hydration (disk → memory, on startup)

```dart
final client = QueryClient();

await hydrateQuery<List<User>>(
  client: client,
  key: QueryKey(['users']),
  storage: storage,
  serializer: Serializer(
    encode: (users) => {'users': users.map((u) => u.toJson()).toList()},
    decode: (json) => (json['users'] as List).map((u) => User.fromJson(u)).toList(),
  ),
);

// client.getQueryData<List<User>>(QueryKey(['users'])) is now populated —
// the first frame can show yesterday's data before any network request.
```

A corrupt or unexpectedly-shaped individual entry is dropped (and deleted
from storage) rather than crashing startup — only that one key is
affected, not the whole hydration pass.

Call `hydrateQuery` explicitly per query you want restored at launch,
rather than one generic "hydrate everything" call — the spec's own "No
Magic" principle (§91) applies here too: what gets restored from disk, and
with what serializer, should be visible in your startup code, not implicit.

## Write-through (memory → disk, on every successful fetch)

```dart
final users = client.query<List<User>>(
  QueryKey(['users']),
  persistedFetcher<List<User>>(
    key: QueryKey(['users']),
    fetcher: () => api.getUsers(),
    storage: storage,
    serializer: usersSerializer,
  ),
);
```

`persistedFetcher` wraps any fetcher; the query behaves exactly as it
would without persistence (same dedup, retry, staleTime) — successful
results are just also written to disk. A failing disk write never surfaces
as a query failure; it's swallowed so a full disk degrades to "this one
result didn't get persisted," not "the app's queries are now broken."

## Full example

See `example/lib/main.dart` for hydration → fetch → write-through →
simulated restart → hydration again, all against an in-memory sqlite3 `db`
so it runs standalone with `dart run example/lib/main.dart`.

## Installation

```yaml
dependencies:
  queryx_persistence: ^0.1.0
```
