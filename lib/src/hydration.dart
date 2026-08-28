import 'package:queryx/queryx.dart';

/// Call once at app startup, before hydrating any individual query. Checks
/// the schema version already on disk against [version]; if they differ,
/// wipes [storage] rather than risking a crash deserializing incompatible
/// data (spec §71: "If incompatible: invalidate old cache rather than
/// crashing").
///
/// ```dart
/// final storage = HiveCacheStorage(await Hive.openBox('queryx_cache'));
/// await initializePersistentCache(storage: storage, version: 2);
/// ```
Future<void> initializePersistentCache({
  required CacheStorage storage,
  required int version,
}) async {
  final storedVersion = await storage.readVersion();
  if (storedVersion != version) {
    await storage.clear();
    await storage.writeVersion(version);
  }
}

/// Reads [key]'s persisted value from [storage] (if any), decodes it with
/// [serializer], and writes it straight into [client]'s in-memory cache via
/// `setQueryData` — so the very first frame after app startup can show
/// cached data instantly, before any network request has even started
/// (spec §70: "Cache Hydration").
///
/// Call [initializePersistentCache] once beforehand so version mismatches
/// are already handled; this function still defends against a corrupt or
/// unexpectedly-shaped individual entry by dropping just that key rather
/// than crashing startup.
///
/// ```dart
/// await hydrateQuery<List<User>>(
///   client: queryClient,
///   key: QueryKey(['users']),
///   storage: storage,
///   serializer: Serializer(
///     encode: (users) => {'users': users.map((u) => u.toJson()).toList()},
///     decode: (json) => (json['users'] as List).map((u) => User.fromJson(u)).toList(),
///   ),
/// );
/// ```
Future<void> hydrateQuery<T>({
  required QueryClient client,
  required QueryKey key,
  required CacheStorage storage,
  required Serializer<T> serializer,
}) async {
  try {
    final raw = await storage.read(key.id);
    if (raw == null) return;
    final data = serializer.decode(raw);
    client.setQueryData<T>(key, data);
  } catch (_) {
    // Corrupt or incompatible entry for this one key — drop it and move on
    // rather than taking down the rest of startup hydration with it.
    try {
      await storage.delete(key.id);
    } catch (_) {
      // Best-effort cleanup; nothing further to do if this also fails.
    }
  }
}
