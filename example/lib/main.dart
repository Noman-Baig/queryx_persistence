// Run with: dart run example/lib/main.dart
//
// Uses the sqlite3 backend since it needs no Flutter/platform setup to run
// here. Swap SqliteCacheStorage for HiveCacheStorage the same way — same
// interface either way.
// ignore_for_file: avoid_print

import 'package:queryx_persistence/queryx_persistence.dart';
import 'package:sqlite3/sqlite3.dart';

class User {
  const User(this.id, this.name);
  final int id;
  final String name;

  @override
  String toString() => 'User($id, $name)';
}

final usersSerializer = Serializer<List<User>>(
  encode: (users) => {
    'users': users.map((u) => {'id': u.id, 'name': u.name}).toList(),
  },
  decode: (json) => (json['users'] as List)
      .map((u) => User(u['id'] as int, u['name'] as String))
      .toList(),
);

Future<void> main() async {
  // In a real app this file would live at a real on-disk path (e.g. via
  // path_provider in Flutter); an in-memory db is fine for this example.
  final db = sqlite3.openInMemory();
  final storage = SqliteCacheStorage(db);

  const cacheVersion = 1;
  await initializePersistentCache(storage: storage, version: cacheVersion);

  final client = QueryClient(logger: QueryxLogger(enabled: true));
  final usersKey = QueryKey(['users']);

  // 1. Hydrate from disk before the first frame / first request — if this
  //    were a second app launch, `client.getQueryData` would already have
  //    yesterday's users here.
  await hydrateQuery<List<User>>(
    client: client,
    key: usersKey,
    storage: storage,
    serializer: usersSerializer,
  );
  print('After hydration (first run, nothing on disk yet): '
      '${client.getQueryData<List<User>>(usersKey)}');

  // 2. A normal query, wrapped with persistedFetcher so every successful
  //    fetch is also written to disk.
  var networkCallCount = 0;
  final usersQuery = client.query<List<User>>(
    usersKey,
    persistedFetcher<List<User>>(
      key: usersKey,
      fetcher: () async {
        networkCallCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return [const User(1, 'Ada'), const User(2, 'Linus')];
      },
      storage: storage,
      serializer: usersSerializer,
    ),
  );

  final users = await usersQuery.ensureFetched();
  print(
      'Fetched from network: $users (network calls so far: $networkCallCount)');

  // 3. Simulate a fresh app start: new QueryClient, same storage. Hydration
  //    now finds what step 2 persisted, with zero network calls.
  final freshClient = QueryClient();
  await hydrateQuery<List<User>>(
    client: freshClient,
    key: usersKey,
    storage: storage,
    serializer: usersSerializer,
  );
  print('After "restart", hydrated from disk: '
      '${freshClient.getQueryData<List<User>>(usersKey)}');

  usersQuery.dispose();
  db.dispose();
}
