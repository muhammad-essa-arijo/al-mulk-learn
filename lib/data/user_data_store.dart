import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny wrapper around shared_preferences. Every feature saves its data as a
/// JSON string under its own key, so backup/restore is easy later.
class UserDataStore {
  final SharedPreferences _prefs;
  UserDataStore._(this._prefs);

  static Future<UserDataStore> open() async =>
      UserDataStore._(await SharedPreferences.getInstance());

  /// Reads JSON; returns [fallback] if missing or broken (never crashes).
  dynamic readJson(String key, dynamic fallback) {
    final text = _prefs.getString(key);
    if (text == null) return fallback;
    try {
      return jsonDecode(text);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> writeJson(String key, dynamic value) =>
      _prefs.setString(key, jsonEncode(value));

  /// All saved keys as one map - used by Backup (phase 5).
  Map<String, String> exportAll() => {
        for (final k in _prefs.getKeys())
          if (_prefs.get(k) is String) k: _prefs.getString(k)!,
      };

  /// Replaces our saved data with [data] (used by Restore). Only known keys.
  Future<void> importAll(Map<String, String> data) async {
    for (final key in dataKeys) {
      await _prefs.remove(key);
      final v = data[key];
      if (v != null) await _prefs.setString(key, v);
    }
  }

  Future<void> removeKey(String key) => _prefs.remove(key);

  /// Every key this app uses.
  static const dataKeys = ['settings', 'progress', 'library', 'practice', 'achievements'];

  Future<void> clearAll() => _prefs.clear();
}
