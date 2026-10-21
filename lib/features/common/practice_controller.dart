import 'package:flutter/foundation.dart';
import '../../core/spaced_repetition.dart';
import '../../data/user_data_store.dart';

/// One finished quiz, kept for the history chart (phase 6).
class QuizResultEntry {
  final String id;    // quiz kind, e.g. "mixed", "root", "weak"
  final String at;    // ISO date-time
  final int score;
  final int total;
  const QuizResultEntry(this.id, this.at, this.score, this.total);
  Map<String, dynamic> toJson() => {'id': id, 'at': at, 's': score, 'n': total};
  factory QuizResultEntry.fromJson(Map<String, dynamic> j) => QuizResultEntry(
      (j['id'] ?? '') as String, (j['at'] ?? '') as String,
      (j['s'] as num?)?.toInt() ?? 0, (j['n'] as num?)?.toInt() ?? 0);
}

/// Everything about practising: flashcard schedule, weak words,
/// quiz history and memorised ayahs. Saved automatically.
class PracticeController extends ChangeNotifier {
  final UserDataStore _store;
  Map<String, CardState> cards = {};      // word key -> Leitner state
  Map<String, WordStat> stats = {};       // word key -> mistakes
  List<QuizResultEntry> history = [];
  Set<int> memorized = {};

  int reviewCount = 0;                    // flashcards reviewed in total (badge)

  PracticeController(this._store) {
    reload();
  }

  void reload() {
    final j = _store.readJson('practice', <String, dynamic>{});
    final m = j is Map ? Map<String, dynamic>.from(j) : <String, dynamic>{};
    cards = {};
    stats = {};
    for (final e in Map<String, dynamic>.from((m['cards'] as Map?) ?? {}).entries) {
      cards[e.key] = CardState.fromJson(Map<String, dynamic>.from(e.value as Map));
    }
    for (final e in Map<String, dynamic>.from((m['stats'] as Map?) ?? {}).entries) {
      stats[e.key] = WordStat.fromJson(Map<String, dynamic>.from(e.value as Map));
    }
    history = [
      for (final h in (m['history'] as List?) ?? [])
        QuizResultEntry.fromJson(Map<String, dynamic>.from(h as Map))
    ];
    memorized = ((m['memorized'] as List?) ?? []).map((e) => (e as num).toInt()).toSet();
    reviewCount = (m['reviews'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  /// Settings > Reset progress.
  void reset() {
    cards = {};
    stats = {};
    history = [];
    memorized = {};
    reviewCount = 0;
    _save();
  }

  void _save() {
    _store.writeJson('practice', {
      'cards': {for (final e in cards.entries) e.key: e.value.toJson()},
      'stats': {for (final e in stats.entries) e.key: e.value.toJson()},
      'history': [for (final h in history) h.toJson()],
      'memorized': memorized.toList(),
      'reviews': reviewCount,
    });
    notifyListeners();
  }

  /// Words that are currently "weak".
  Set<String> get weakKeys =>
      {for (final e in stats.entries) if (e.value.isWeak) e.key};

  void reviewFlashcard(String key, Rating r) {
    cards[key] = reviewCard(cards[key], r, DateTime.now());
    reviewCount++;
    recordAnswer(key, r != Rating.again, save: false);
    _save();
  }

  void recordAnswer(String key, bool correct, {bool save = true}) {
    (stats[key] ??= WordStat()).record(correct);
    if (save) _save();
  }

  void addQuizResult(String id, int score, int total) {
    history.add(QuizResultEntry(id, DateTime.now().toIso8601String(), score, total));
    _save();
  }

  void setMemorized(int ayah, bool remembered) {
    remembered ? memorized.add(ayah) : memorized.remove(ayah);
    _save();
  }
}
