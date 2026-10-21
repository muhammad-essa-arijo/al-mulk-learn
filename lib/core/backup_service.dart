import 'dart:convert';
import '../data/user_data_store.dart';

/// Backup = one JSON text with all the user's saved data. No internet.
class BackupService {
  static const _marker = 'al_mulk_learn_backup';

  static String export(UserDataStore store) {
    final data = {
      for (final e in store.exportAll().entries)
        if (UserDataStore.dataKeys.contains(e.key)) e.key: e.value,
    };
    return const JsonEncoder.withIndent('  ').convert({
      'app': _marker,
      'version': 1,
      'created': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  /// Returns true if the text was a valid backup and was restored.
  static Future<bool> restore(UserDataStore store, String text) async {
    try {
      final j = jsonDecode(text);
      if (j is! Map || j['app'] != _marker || j['data'] is! Map) return false;
      final data = <String, String>{};
      for (final e in (j['data'] as Map).entries) {
        if (e.value is String) data[e.key.toString()] = e.value as String;
      }
      await store.importAll(data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
