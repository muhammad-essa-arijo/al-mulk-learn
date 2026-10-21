import 'package:flutter/foundation.dart';
import '../../core/streak.dart';
import '../../data/user_data_store.dart';

/// Learning progress: learned words, studied ayahs, activity days, time spent.
class ProgressController extends ChangeNotifier {
  final UserDataStore _store;

  Set<String> learnedWords = {};      // word group keys (lemma), one per unique word
  Set<int> studiedAyahs = {};
  int lastAyah = 1;                   // for "continue where you left off"
  Map<String, int> wordsPerDay = {};  // "2026-10-21" -> words learned that day
  Set<String> activeDays = {};        // days the user did something
  int secondsSpent = 0;               // total time with the app open
  bool nightActivity = false;         // studied between 10 pm and 4 am (badge)

  ProgressController(this._store) {
    reload();
  }

  void reload() {
    final j = _store.readJson('progress', <String, dynamic>{});
    final m = j is Map ? Map<String, dynamic>.from(j) : <String, dynamic>{};
    learnedWords = ((m['learned'] as List?) ?? []).map((e) => '$e').toSet();
    studiedAyahs =
        ((m['studied'] as List?) ?? []).map((e) => (e as num).toInt()).toSet();
    lastAyah = (m['lastAyah'] as num?)?.toInt() ?? 1;
    final perDay = Map<String, dynamic>.from((m['perDay'] as Map?) ?? {});
    wordsPerDay = {for (final e in perDay.entries) e.key: (e.value as num).toInt()};
    activeDays = ((m['days'] as List?) ?? []).map((e) => '$e').toSet();
    secondsSpent = (m['seconds'] as num?)?.toInt() ?? 0;
    nightActivity = (m['night'] as bool?) ?? false;
    notifyListeners();
  }

  int get streak => currentStreak(activeDays, DateTime.now());
  int get wordsToday => wordsPerDay[dayKey(DateTime.now())] ?? 0;

  Map<String, dynamic> _toJson() => {
        'learned': learnedWords.toList(),
        'studied': studiedAyahs.toList(),
        'lastAyah': lastAyah,
        'perDay': wordsPerDay,
        'days': activeDays.toList(),
        'seconds': secondsSpent,
        'night': nightActivity,
      };

  void _save() {
    _store.writeJson('progress', _toJson());
    notifyListeners();
  }

  /// Called every few seconds while the app is open. Saved quietly (no
  /// screen refresh) so the UI does not rebuild all the time.
  void addSeconds(int s) {
    secondsSpent += s;
    _store.writeJson('progress', _toJson());
  }

  /// Call this whenever the user does any learning action.
  void recordActivity() {
    final now = DateTime.now();
    activeDays.add(dayKey(now));
    if (now.hour >= 22 || now.hour < 4) nightActivity = true;
    _save();
  }

  void markWordLearned(String id) {
    if (learnedWords.add(id)) {
      final k = dayKey(DateTime.now());
      wordsPerDay[k] = (wordsPerDay[k] ?? 0) + 1;
    }
    recordActivity();
  }

  /// Undo "learned". Also takes one off today's count so the goal ring
  /// cannot be inflated by switching the button on and off.
  void unmarkWordLearned(String id) {
    if (learnedWords.remove(id)) {
      final k = dayKey(DateTime.now());
      final n = wordsPerDay[k] ?? 0;
      if (n > 0) wordsPerDay[k] = n - 1;
    }
    _save();
  }

  void markAyahStudied(int number) {
    studiedAyahs.add(number);
    lastAyah = number;
    recordActivity();
  }

  void toggleAyahStudied(int number) {
    if (studiedAyahs.contains(number)) {
      studiedAyahs.remove(number);
      _save();
    } else {
      markAyahStudied(number);
    }
  }

  void setLastAyah(int number) {
    lastAyah = number;
    _save();
  }

  /// Settings > Reset progress.
  void reset() {
    learnedWords = {};
    studiedAyahs = {};
    lastAyah = 1;
    wordsPerDay = {};
    activeDays = {};
    secondsSpent = 0;
    nightActivity = false;
    _save();
  }
}
