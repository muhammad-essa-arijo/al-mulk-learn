import 'package:flutter/foundation.dart';
import '../../data/user_data_store.dart';
import '../common/library_controller.dart';
import '../common/practice_controller.dart';
import '../common/progress_controller.dart';
import 'badges.dart';

/// Watches the other controllers; whenever something changes it checks the
/// badge rules and unlocks new badges. [onUnlock] lets the app show a message.
class AchievementsController extends ChangeNotifier {
  final UserDataStore _store;
  final ProgressController progress;
  final LibraryController library;
  final PracticeController practice;
  final int ayahTotal;

  Map<String, String> unlocked = {}; // badge id -> date unlocked
  void Function(AppBadge badge)? onUnlock;

  AchievementsController(this._store, this.progress, this.library,
      this.practice, this.ayahTotal) {
    reload();
    progress.addListener(_check);
    library.addListener(_check);
    practice.addListener(_check);
  }

  /// Reads saved badges. Existing progress unlocks badges silently.
  void reload() {
    final j = _store.readJson('achievements', <String, dynamic>{});
    final m = j is Map ? Map<String, dynamic>.from(j) : <String, dynamic>{};
    unlocked = {for (final e in m.entries) e.key: '${e.value}'};
    _check(silent: true);
    notifyListeners();
  }

  BadgeStats get _stats => BadgeStats(
        streak: progress.streak,
        learned: progress.learnedWords.length,
        studied: progress.studiedAyahs.length,
        notes: library.notes.length,
        bookmarks: library.bookmarks.length,
        quizzes: practice.history.length,
        memorized: practice.memorized.length,
        reviews: practice.reviewCount,
        perfectQuiz: practice.history.any((h) => h.total >= 5 && h.score == h.total),
        night: progress.nightActivity,
        ayahTotal: ayahTotal,
      );

  void _check({bool silent = false}) {
    final s = _stats;
    final fresh = <AppBadge>[];
    for (final b in allBadges) {
      if (!unlocked.containsKey(b.id) && b.earned(s)) {
        unlocked[b.id] = DateTime.now().toIso8601String();
        fresh.add(b);
      }
    }
    if (fresh.isEmpty) return;
    _store.writeJson('achievements', unlocked);
    notifyListeners();
    if (!silent) {
      for (final b in fresh) {
        onUnlock?.call(b);
      }
    }
  }

  /// Settings > Reset progress.
  void reset() {
    unlocked = {};
    _store.writeJson('achievements', unlocked);
    notifyListeners();
  }

  @override
  void dispose() {
    progress.removeListener(_check);
    library.removeListener(_check);
    practice.removeListener(_check);
    super.dispose();
  }
}
