import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = TokenStorage();
  ref.onDispose(storage.dispose);
  return storage;
});

/// Holds the backend JWT (valid 60 days, no refresh endpoint), the signed-in
/// user returned by `auth/signIn`, and a per-install device id used when
/// registering the FCM token.
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _sessionUserKey = 'session_user';
  static const _deviceIdKey = 'device_id';

  final FlutterSecureStorage _storage;
  final _sessionExpired = StreamController<void>.broadcast();

  TokenStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  /// Fires when the backend rejects the stored token (HTTP 401).
  Stream<void> get sessionExpired => _sessionExpired.stream;

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<void> saveSessionUser(Map<String, dynamic> userJson) =>
      _storage.write(key: _sessionUserKey, value: jsonEncode(userJson));

  Future<Map<String, dynamic>?> getSessionUser() async {
    final raw = await _storage.read(key: _sessionUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<String> getDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  /// Clears the session but keeps the device id.
  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _sessionUserKey),
    ]);
  }

  Future<void> expireSession() async {
    await clearAll();
    _sessionExpired.add(null);
  }

  void dispose() => _sessionExpired.close();
}
