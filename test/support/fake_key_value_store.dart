import 'package:evergreen/core/storage/key_value_store.dart';

/// In-memory [KeyValueStore] for tests — no SharedPreferences / platform.
/// Lets provider tests seed, mutate and assert persistence deterministically.
class FakeKeyValueStore implements KeyValueStore {
  FakeKeyValueStore([Map<String, String>? initial]) : _data = {...?initial};

  final Map<String, String> _data;

  /// Writes observed, for asserting that mutations persisted.
  int writeCount = 0;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
    writeCount++;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  /// Raw peek at what's persisted under [key] (null if nothing).
  String? peek(String key) => _data[key];
}
