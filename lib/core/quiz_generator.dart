// Builds quiz questions from the surah's real data. No Flutter code here,
// so it can be unit-tested. Wrong options ("distractors") always come from
// other words in the surah, preferring the same part of speech so they look
// believable.
import 'dart:math';
import '../data/models.dart';
import 'text_utils.dart';

enum QuizType { meaning, reverse, fillBlank, match, listen, root }

class MatchPair {
  final String key;     // word group key
  final String arabic;
  final String meaning;
  const MatchPair(this.key, this.arabic, this.meaning);
}

class QuizQuestion {
  final QuizType type;
  final String arabic;        // big Arabic text (word / sentence with blank)
  final String promptText;    // e.g. the English meaning for "reverse"
  final List<String> options;
  final bool optionsAreArabic;
  final int correctIndex;
  final String explanation;   // English fallback (used in tests)
  final String explainKey;    // key of a translated template (see strings.dart)
  final Map<String, String> explainArgs; // values inserted into the template
  final int? audioAyah;       // for "listen"
  final List<MatchPair> pairs; // for "match"
  final List<String> wordKeys; // words involved (used for weak-word tracking)
  final List<String> usedKeys; // used to avoid repeating questions

  const QuizQuestion({
    required this.type,
    this.arabic = '',
    this.promptText = '',
    this.options = const [],
    this.optionsAreArabic = false,
    this.correctIndex = 0,
    this.explanation = '',
    this.explainKey = '',
    this.explainArgs = const {},
    this.audioAyah,
    this.pairs = const [],
    this.wordKeys = const [],
    this.usedKeys = const [],
  });

  String get signature => '${type.name}|${([...usedKeys]..sort()).join(',')}';
  String get correctText =>
      type == QuizType.match
          ? pairs.map((p) => '${p.arabic} = ${p.meaning}').join('\n')
          : options[correctIndex];
}

class QuizGenerator {
  final List<Ayah> ayahs;
  final Random rng;
  late final List<Word> _all;
  late final List<Word> _unique;
  late final Map<String, List<Word>> _occurrences;

  QuizGenerator(this.ayahs, {Random? rng}) : rng = rng ?? Random() {
    _all = [for (final a in ayahs) ...a.words];
    _occurrences = {};
    for (final w in _all) {
      _occurrences.putIfAbsent(w.groupKey, () => []).add(w);
    }
    _unique = [for (final l in _occurrences.values) l.first];
  }

  /// Beginners get simpler question types and 3 options.
  static List<QuizType> typesForLevel(String level) => level == 'intermediate'
      ? QuizType.values
      : [QuizType.meaning, QuizType.reverse, QuizType.listen, QuizType.match, QuizType.fillBlank];

  static String _n(String s) => normalizeArabic(s).toLowerCase().trim();

  List<QuizQuestion> generate({
    String level = 'beginner',
    List<QuizType>? types,
    Set<String>? focusKeys,
    int count = 10,
  }) {
    final typePool = [...(types ?? typesForLevel(level))]..shuffle(rng);
    final optionCount = level == 'intermediate' ? 4 : 3;

    // Words that have an English meaning can be asked about.
    var base = _unique.where((w) => w.meaning.isNotEmpty).toList();
    if (level != 'intermediate') {
      // Beginners: prefer words that appear more than once (more familiar).
      final common = base.where((w) => _occurrences[w.groupKey]!.length > 1).toList();
      if (common.length >= 15) base = common;
    }
    List<Word> focus = [];
    if (focusKeys != null && focusKeys.isNotEmpty) {
      focus = _unique.where((w) => focusKeys.contains(w.groupKey) && w.meaning.isNotEmpty).toList();
    }
    final pool = focus.isNotEmpty ? focus : base;

    final questions = <QuizQuestion>[];
    final seen = <String>{};
    final usedKeys = <String>{};
    var attempts = 0;
    while (questions.length < count && attempts < count * 60) {
      attempts++;
      final type = typePool[questions.length % typePool.length];
      final relax = attempts > count * 15; // allow reuse only if we must
      final q = _make(type, pool, base, optionCount, usedKeys, relax);
      if (q == null || seen.contains(q.signature)) continue;
      seen.add(q.signature);
      usedKeys.addAll(q.usedKeys);
      questions.add(q);
    }
    return questions;
  }

  Word _pick(List<Word> pool, Set<String> used, bool relax) {
    final fresh = pool.where((w) => !used.contains(w.groupKey)).toList();
    final list = (fresh.isEmpty || relax) ? pool : fresh;
    return list[rng.nextInt(list.length)];
  }

  /// Wrong options: other words, same part of speech first, all different.
  List<Word> _distractors(Word target, int n, String Function(Word) text) {
    final samePos = _unique.where((w) => w.groupKey != target.groupKey && w.pos == target.pos).toList()..shuffle(rng);
    final others = _unique.where((w) => w.groupKey != target.groupKey && w.pos != target.pos).toList()..shuffle(rng);
    final seen = {_n(text(target))};
    final out = <Word>[];
    for (final w in [...samePos, ...others]) {
      final t = _n(text(w));
      if (t.isEmpty || !seen.add(t)) continue;
      out.add(w);
      if (out.length == n) break;
    }
    return out;
  }

  /// Puts the correct text among the wrong ones in random order.
  (List<String>, int) _shuffleOptions(String correct, List<String> wrong) {
    final all = [correct, ...wrong]..shuffle(rng);
    return (all, all.indexOf(correct));
  }

  QuizQuestion? _make(QuizType type, List<Word> pool, List<Word> base, int nOpt, Set<String> used, bool relax) {
    switch (type) {
      case QuizType.meaning:
      case QuizType.reverse:
        final t = _pick(pool, used, relax);
        final reverse = type == QuizType.reverse;
        final d = _distractors(t, nOpt - 1, (w) => reverse ? w.arabic : w.meaning);
        if (d.length < nOpt - 1) return null;
        final (opts, idx) = _shuffleOptions(
            reverse ? t.arabic : t.meaning, [for (final w in d) reverse ? w.arabic : w.meaning]);
        return QuizQuestion(
          type: type,
          arabic: reverse ? '' : t.arabic,
          promptText: reverse ? t.meaning : t.translit,
          options: opts,
          optionsAreArabic: reverse,
          correctIndex: idx,
          explanation: '${t.arabic} (${t.translit}) means "${t.meaning}".',
          explainKey: 'exMeaning',
          explainArgs: {'arabic': t.arabic, 'translit': t.translit, 'meaning': t.meaning},
          wordKeys: [t.groupKey],
          usedKeys: [t.groupKey],
        );

      case QuizType.root:
        final rootPool = pool.where((w) => w.root.isNotEmpty).toList();
        if (rootPool.isEmpty) return null;
        final t = _pick(rootPool, used, relax);
        // Other roots, preferring ones with the same number of letters.
        final roots = _unique.map((w) => w.root).where((r) => r.isNotEmpty && r != t.root).toSet().toList()..shuffle(rng);
        final sameLen = roots.where((r) => r.length == t.root.length).toList();
        final rest = roots.where((r) => r.length != t.root.length).toList();
        final wrong = [...sameLen, ...rest].take(nOpt - 1).toList();
        if (wrong.length < nOpt - 1) return null;
        final (opts, idx) = _shuffleOptions(t.root, wrong);
        return QuizQuestion(
          type: type,
          arabic: t.arabic,
          promptText: t.translit,
          options: opts,
          optionsAreArabic: true,
          correctIndex: idx,
          explanation: '${t.arabic} (${t.meaning}) comes from the root ${t.root}.',
          explainKey: 'exRoot',
          explainArgs: {'arabic': t.arabic, 'meaning': t.meaning, 'root': t.root},
          wordKeys: [t.groupKey],
          usedKeys: [t.groupKey],
        );

      case QuizType.fillBlank:
        final t = _pick(pool, used, relax);
        // Choose one place where this word occurs, in an ayah with 4+ words.
        final spots = _occurrences[t.groupKey]!.where((w) => ayahs[w.ayah - 1].words.length >= 4).toList();
        if (spots.isEmpty) return null;
        final spot = spots[rng.nextInt(spots.length)];
        final ayah = ayahs[spot.ayah - 1];
        final d = _distractors(spot, nOpt - 1, (w) => w.arabic);
        if (d.length < nOpt - 1) return null;
        final sentence = [for (final w in ayah.words) w.position == spot.position ? '_____' : w.arabic].join(' ');
        final (opts, idx) = _shuffleOptions(spot.arabic, [for (final w in d) w.arabic]);
        return QuizQuestion(
          type: type,
          arabic: sentence,
          options: opts,
          optionsAreArabic: true,
          correctIndex: idx,
          explanation: 'Ayah ${ayah.number}: the missing word is ${spot.arabic} (${spot.translit}) - "${spot.meaning}".',
          explainKey: 'exFill',
          explainArgs: {'ayah': '${ayah.number}', 'arabic': spot.arabic, 'translit': spot.translit, 'meaning': spot.meaning},
          wordKeys: [t.groupKey],
          usedKeys: [t.groupKey],
        );

      case QuizType.match:
        final chosen = <Word>[];
        final seenMeaning = <String>{};
        // Shuffle each group separately: words not used yet come first.
        final candidates = [
          ...(pool.where((w) => !used.contains(w.groupKey)).toList()..shuffle(rng)),
          ...([...pool]..shuffle(rng)),
          ...([...base]..shuffle(rng)),
        ];
        for (final w in candidates) {
          if (chosen.any((c) => c.groupKey == w.groupKey)) continue;
          if (!seenMeaning.add(_n(w.meaning))) continue;
          chosen.add(w);
          if (chosen.length == 5) break;
        }
        if (chosen.length < 5) return null;
        return QuizQuestion(
          type: type,
          pairs: [for (final w in chosen) MatchPair(w.groupKey, w.arabic, w.meaning)],
          explanation: 'Each Arabic word is shown with its meaning.',
          explainKey: 'exMatch',
          wordKeys: [for (final w in chosen) w.groupKey],
          usedKeys: [for (final w in chosen) w.groupKey],
        );

      case QuizType.listen:
        // Pick the ayah: from a focus word if we have one, else at random.
        final t = _pick(pool, used, relax);
        final occ = _occurrences[t.groupKey]!;
        final ayahNo = occ[rng.nextInt(occ.length)].ayah;
        final key = 'ayah:$ayahNo';
        if (used.contains(key)) return null;
        String snippet(Ayah a) => '${a.words.take(5).map((w) => w.arabic).join(' ')} ...';
        final correct = snippet(ayahs[ayahNo - 1]);
        final others = ayahs.where((a) => a.number != ayahNo).toList()..shuffle(rng);
        final wrong = <String>[];
        for (final a in others) {
          final s = snippet(a);
          if (s != correct && !wrong.contains(s)) wrong.add(s);
          if (wrong.length == nOpt - 1) break;
        }
        if (wrong.length < nOpt - 1) return null;
        final (opts, idx) = _shuffleOptions(correct, wrong);
        return QuizQuestion(
          type: type,
          options: opts,
          optionsAreArabic: true,
          correctIndex: idx,
          audioAyah: ayahNo,
          explanation: 'You heard ayah $ayahNo.',
          explainKey: 'exListen',
          explainArgs: {'ayah': '$ayahNo'},
          wordKeys: [t.groupKey],
          usedKeys: [key],
        );
    }
  }
}
