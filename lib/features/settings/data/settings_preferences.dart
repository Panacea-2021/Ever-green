import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/key_value_store.dart';

/// Device-local app preferences from the Settings screen. The backend has no
/// per-user preference storage, so these live in shared preferences.
class SettingsPreferences {
  final bool darkMode;
  final String language;

  /// Company branding accent colour (ARGB), or null for the EverGreen green.
  final int? brandAccent;

  const SettingsPreferences({
    this.darkMode = false,
    this.language = 'English',
    this.brandAccent,
  });

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsPreferences copyWith({
    bool? darkMode,
    String? language,
    int? brandAccent,
  }) {
    return SettingsPreferences(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      brandAccent: brandAccent ?? this.brandAccent,
    );
  }

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'language': language,
        'brandAccent': brandAccent,
      };

  factory SettingsPreferences.fromJson(Map<String, dynamic> json) {
    return SettingsPreferences(
      darkMode: json['darkMode'] == true,
      language: json['language']?.toString() ?? 'English',
      brandAccent: (json['brandAccent'] as num?)?.toInt(),
    );
  }
}

class SettingsPreferencesNotifier extends StateNotifier<SettingsPreferences> {
  SettingsPreferencesNotifier(this._store)
      : super(const SettingsPreferences()) {
    _load();
  }

  final KeyValueStore _store;

  static const String _storageKey = 'settings_preferences_v1';

  Future<void> _load() async {
    final raw = await _store.read(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      state = SettingsPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // Corrupt value: keep the defaults.
    }
  }

  Future<void> _persist() =>
      _store.write(_storageKey, jsonEncode(state.toJson()));

  Future<void> setDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
    return _persist();
  }

  Future<void> setLanguage(String value) {
    state = state.copyWith(language: value);
    return _persist();
  }

  Future<void> setBrandAccent(int argb) {
    state = state.copyWith(brandAccent: argb);
    return _persist();
  }
}

final settingsPreferencesProvider =
    StateNotifierProvider<SettingsPreferencesNotifier, SettingsPreferences>(
        (ref) {
  return SettingsPreferencesNotifier(ref.watch(keyValueStoreProvider));
});
