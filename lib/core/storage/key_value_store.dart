import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A tiny persistence seam for the app's feature providers.
///
/// Every feature notifier (tasks, AMCs, users, equipment, analytics history,
/// PM schedules, audit log) persists its state as a single JSON string keyed
/// by a storage key. Instead of each notifier reaching for
/// [SharedPreferences] directly, they read [keyValueStoreProvider] and go
/// through this interface.
///
/// ---------------------------------------------------------------------------
/// THE SWAP POINT
/// ---------------------------------------------------------------------------
/// This is the one place to change when moving off local-only storage:
///
///   * Local-only (today): [SharedPreferencesStore] — the default override in
///     [keyValueStoreProvider].
///   * Backend-backed (later): write a `RemoteKeyValueStore` that implements
///     this same interface (e.g. GET/PUT a document per key against the API
///     in `EnvironmentConfig.apiBaseUrl`, optionally cached in SharedPreferences
///     for offline use), then flip the override in `main.dart`:
///
///         keyValueStoreProvider.overrideWithValue(RemoteKeyValueStore(...))
///
/// No feature provider needs to change: they only speak [read]/[write]/[remove].
abstract class KeyValueStore {
  /// Returns the stored string for [key], or `null` if nothing is stored.
  Future<String?> read(String key);

  /// Persists [value] under [key], overwriting any previous value.
  Future<void> write(String key, String value);

  /// Deletes any value stored under [key].
  Future<void> remove(String key);
}

/// The default, local-only implementation backed by [SharedPreferences].
///
/// This preserves the exact behavior the feature notifiers had before the
/// seam: a best-effort read and a fire-and-forget write that silently no-ops
/// if the platform store is unavailable (keeping the session in memory).
class SharedPreferencesStore implements KeyValueStore {
  const SharedPreferencesStore();

  @override
  Future<String?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Session-only fallback — nothing to persist to.
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // Session-only fallback.
    }
  }
}

/// Resolves the active [KeyValueStore] for the app.
///
/// Defaults to [SharedPreferencesStore]. Override this in `main.dart` (or in
/// tests) to point the whole data layer at a different backend:
///
///     ProviderScope(
///       overrides: [
///         keyValueStoreProvider.overrideWithValue(RemoteKeyValueStore(...)),
///       ],
///       child: const EverGreenApp(),
///     )
final keyValueStoreProvider = Provider<KeyValueStore>((ref) {
  return const SharedPreferencesStore();
});
