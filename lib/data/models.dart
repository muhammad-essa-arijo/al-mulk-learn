// Plain data classes for the Quran data. They only READ the JSON;
// the Arabic text is never changed in any way.

/// One word of an ayah.
class Word {
  final int ayah;        // which ayah this word is in
  final int position;    // position inside the ayah (starts at 1)
  final String arabic;
  final String translit;
  final String meaning;  // English only (no Urdu/Sindhi data exists)
  final String root;     // Arabic root letters, may be empty
  final String lemma;
  final String pos;      // part of speech code from the data
  final String grammar;  // raw corpus string, see grammar_parser.dart

  const Word({
    required this.ayah, required this.position, required this.arabic,
    required this.translit, required this.meaning, required this.root,
    required this.lemma, required this.pos, required this.grammar,
  });

  /// Unique key for saving progress, e.g. "3:2" = ayah 3, word 2.
  String get id => '$ayah:$position';

  /// Key used to group "the same word". Lemma if we have it, else the Arabic.
  String get groupKey => lemma.isNotEmpty ? lemma : arabic;

  // Missing fields become empty text so the app never crashes.
  factory Word.fromJson(int ayah, Map<String, dynamic> j) => Word(
        ayah: ayah,
        position: (j['position'] as num?)?.toInt() ?? 0,
        arabic: (j['arabic'] ?? '') as String,
        translit: (j['translit'] ?? '') as String,
        meaning: (j['meaning'] ?? '') as String,
        root: (j['root'] ?? '') as String,
        lemma: (j['lemma'] ?? '') as String,
        pos: (j['pos'] ?? '') as String,
        grammar: (j['grammar'] ?? '') as String,
      );
}

/// One ayah with its translations, optional tafseer and words.
class Ayah {
  final int number;
  final String arabic;
  final Map<String, String> translations; // language code -> text
  final Map<String, String> tafseer;      // optional, empty for now
  final List<Word> words;

  const Ayah({
    required this.number, required this.arabic, required this.translations,
    required this.tafseer, required this.words,
  });

  /// Audio file for this ayah, e.g. assets/audio/067001.mp3
  String get audioAsset =>
      'assets/audio/067${number.toString().padLeft(3, '0')}.mp3';

  static Map<String, String> _stringMap(dynamic v) {
    if (v is! Map) return {};
    return {
      for (final e in v.entries)
        if (e.value is String && (e.value as String).isNotEmpty)
          e.key.toString(): e.value as String,
    };
  }

  factory Ayah.fromJson(Map<String, dynamic> j) {
    final n = (j['number'] as num?)?.toInt() ?? 0;
    final rawWords = (j['words'] as List?) ?? const [];
    return Ayah(
      number: n,
      arabic: (j['arabic'] ?? '') as String,
      translations: _stringMap(j['translations']),
      tafseer: _stringMap(j['tafseer']), // add "tafseer": {"en": "..."} later
      words: [
        for (final w in rawWords) Word.fromJson(n, w as Map<String, dynamic>)
      ],
    );
  }
}
