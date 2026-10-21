import 'package:flutter/foundation.dart';
import '../../data/user_data_store.dart';

/// The user's own collection: bookmarked ayahs, saved vocabulary words
/// and personal notes. Saved automatically.
class LibraryController extends ChangeNotifier {
  final UserDataStore _store;
  Set<int> bookmarks = {};            // ayah numbers
  Set<String> savedWords = {};        // word group keys (lemma)
  Map<String, String> notes = {};     // "a:3" = ayah note, "w:3:2" = word note

  LibraryController(this._store) {
    reload();
  }

  /// Reads from storage (also used after a Restore).
  void reload() {
    final j = _store.readJson('library', <String, dynamic>{});
    final m = j is Map ? Map<String, dynamic>.from(j) : <String, dynamic>{};
    bookmarks = ((m['bookmarks'] as List?) ?? []).map((e) => (e as num).toInt()).toSet();
    savedWords = ((m['savedWords'] as List?) ?? []).map((e) => '$e').toSet();
    final n = Map<String, dynamic>.from((m['notes'] as Map?) ?? {});
    notes = {for (final e in n.entries) e.key: '${e.value}'};
    notifyListeners();
  }

  static String ayahNoteKey(int ayah) => 'a:$ayah';
  static String wordNoteKey(int ayah, int position) => 'w:$ayah:$position';

  void _save() {
    _store.writeJson('library', {
      'bookmarks': bookmarks.toList(),
      'savedWords': savedWords.toList(),
      'notes': notes,
    });
    notifyListeners();
  }

  void toggleBookmark(int ayah) {
    if (!bookmarks.remove(ayah)) bookmarks.add(ayah);
    _save();
  }

  void toggleSavedWord(String key) {
    if (!savedWords.remove(key)) savedWords.add(key);
    _save();
  }

  /// An empty text deletes the note.
  void setNote(String key, String text) {
    final t = text.trim();
    if (t.isEmpty) {
      notes.remove(key);
    } else {
      notes[key] = t;
    }
    _save();
  }
}
