import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

/// Loads assets/quran.json once and keeps everything in memory.
class QuranRepository {
  final String surahName;
  final int surahNumber;
  final List<Ayah> ayahs;

  QuranRepository._(this.surahName, this.surahNumber, this.ayahs) {
    // Build helper lookups once, so screens stay fast.
    for (final a in ayahs) {
      for (final w in a.words) {
        allWords.add(w);
        if (w.root.isNotEmpty) {
          _byRoot.putIfAbsent(w.root, () => []).add(w);
        }
        _byGroup.putIfAbsent(w.groupKey, () => []).add(w);
      }
    }
  }

  final List<Word> allWords = [];
  final Map<String, List<Word>> _byRoot = {};
  final Map<String, List<Word>> _byGroup = {};

  /// Reads and parses the JSON file from the app bundle (works offline).
  static Future<QuranRepository> load() async {
    final text = await rootBundle.loadString('assets/quran.json');
    final json = jsonDecode(text) as Map<String, dynamic>;
    final list = (json['ayahs'] as List)
        .map((a) => Ayah.fromJson(a as Map<String, dynamic>))
        .toList();
    return QuranRepository._(
      (json['surah'] ?? 'Al-Mulk') as String,
      (json['number'] as num?)?.toInt() ?? 67,
      list,
    );
  }

  Ayah ayah(int number) => ayahs[number - 1];

  /// Every language code that has data for at least one ayah.
  /// Adding Sindhi ("sd") to the JSON makes it appear automatically.
  Set<String> get translationLanguages =>
      {for (final a in ayahs) ...a.translations.keys};

  /// All words in the surah that share a root with [w] (including itself).
  List<Word> wordsWithRoot(String root) => _byRoot[root] ?? const [];

  /// How many times this word (by lemma) appears in the surah.
  int frequency(Word w) => _byGroup[w.groupKey]?.length ?? 1;

  /// One representative word per lemma - used by vocabulary and quizzes.
  List<Word> get uniqueWords =>
      [for (final list in _byGroup.values) list.first];
}
