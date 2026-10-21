// Turns the raw Quranic Arabic Corpus grammar string into friendly text,
// in English or Urdu. We only translate the grammar TERMS (noun, verb,
// genitive...). We never add facts the data does not contain.
//
// Raw example:  bi=P:PREFIX|bi+ ; yadi=N:STEM|POS:N|LEM:yad|ROOT:ydy|FS|GEN ; hi=PRON:SUFFIX|PRON:3MS
// A word has several parts separated by " ; ". Each part is  form=TAG:ROLE|FEATURE|FEATURE...

/// One piece of a word: a prefix, the stem, or a suffix.
class GrammarPart {
  final String form;
  final String tag;
  final String role;
  final List<String> features;
  final String explanation;   // short student-friendly sentence
  final List<String> unknown; // tokens we could not translate (shown small)

  const GrammarPart({
    required this.form,
    required this.tag,
    required this.role,
    required this.features,
    required this.explanation,
    required this.unknown,
  });
}

class GrammarParser {
  // ---------------- English tables ----------------
  static const Map<String, String> tagNames = {
    'N': 'Noun', 'PN': 'Proper noun (a name)', 'ADJ': 'Adjective', 'V': 'Verb',
    'P': 'Preposition', 'PRON': 'Pronoun', 'REL': 'Relative pronoun (who / which)',
    'DEM': 'Demonstrative (this / that)', 'DET': 'Definite article "the"',
    'CONJ': 'Conjunction "and"', 'NEG': 'Negation particle',
    'INTG': 'Question particle', 'COND': 'Conditional particle (if)',
    'T': 'Time adverb', 'LOC': 'Location adverb', 'ACC': 'Accusative particle',
    'REM': 'Resumption particle', 'CIRC': 'Circumstantial particle',
    'CERT': 'Particle of certainty', 'RES': 'Restriction particle',
    'SUB': 'Subordinating conjunction', 'ANS': 'Answer particle',
    'RET': 'Retraction particle', 'SUR': 'Surprise particle',
    'PREV': 'Preventive particle', 'CAUS': 'Particle of cause',
    'SUP': 'Supplemental particle', 'RSLT': 'Result particle',
    'PRP': 'Purpose particle', 'EMPH': 'Emphasis particle', 'FUT': 'Future particle',
  };
  static const Map<String, String> _featEn = {
    'PERF': 'past tense', 'IMPF': 'present/future tense', 'IMPV': 'command',
    'NOM': 'nominative case (marfūʿ)', 'ACC': 'accusative case (manṣūb)',
    'GEN': 'genitive case (majrūr)', 'INDEF': 'indefinite',
    'VN': 'verbal noun', 'M': 'masculine', 'F': 'feminine',
    'MOOD:SUBJ': 'subjunctive mood', 'MOOD:JUS': 'jussive mood',
  };
  static const Map<String, String> _formEn = {
    '(I)': 'Form I', '(II)': 'Form II', '(III)': 'Form III', '(IV)': 'Form IV',
    '(V)': 'Form V', '(VI)': 'Form VI', '(VII)': 'Form VII',
    '(VIII)': 'Form VIII', '(IX)': 'Form IX', '(X)': 'Form X',
  };

  // ---------------- Urdu tables (standard grammar terms) ----------------
  static const Map<String, String> _tagUr = {
    'N': 'اسم', 'PN': 'اسمِ علم (نام)', 'ADJ': 'صفت', 'V': 'فعل',
    'P': 'حرفِ جار', 'PRON': 'ضمیر', 'REL': 'اسمِ موصول (جو / جس)',
    'DEM': 'اسمِ اشارہ (یہ / وہ)', 'DET': 'حرفِ تعریف "ال" (the)',
    'CONJ': 'حرفِ عطف "اور"', 'NEG': 'حرفِ نفی', 'INTG': 'سوالیہ حرف',
    'COND': 'حرفِ شرط (اگر)', 'T': 'ظرفِ زمان', 'LOC': 'ظرفِ مکان',
    'ACC': 'نصب دینے والا حرف', 'REM': 'بات آگے بڑھانے والا حرف',
    'CIRC': 'حال بتانے والا حرف', 'CERT': 'یقین کا حرف',
    'RES': 'حصر (صرف) کا حرف', 'SUB': 'ماتحت جملہ جوڑنے والا حرف',
    'ANS': 'جواب کا حرف', 'RET': 'اضراب (بات پلٹنے) کا حرف',
    'SUR': 'حیرت کا حرف', 'PREV': 'روکنے والا حرف',
    'CAUS': 'سبب بتانے والا حرف', 'SUP': 'اضافی حرف',
    'RSLT': 'نتیجہ بتانے والا حرف', 'PRP': 'مقصد بتانے والا حرف',
    'EMPH': 'تاکید کا حرف', 'FUT': 'مستقبل کا حرف',
  };
  static const Map<String, String> _featUr = {
    'PERF': 'ماضی', 'IMPF': 'مضارع (حال / مستقبل)', 'IMPV': 'امر (حکم)',
    'NOM': 'مرفوع', 'ACC': 'منصوب', 'GEN': 'مجرور', 'INDEF': 'نکرہ',
    'VN': 'مصدر', 'M': 'مذکر', 'F': 'مؤنث',
    'MOOD:SUBJ': 'مضارع منصوب', 'MOOD:JUS': 'مضارع مجزوم',
  };
  static const Map<String, String> _formUr = {
    '(I)': 'ثلاثی مجرد (Form I)', '(II)': 'باب تفعیل (Form II)',
    '(III)': 'باب مفاعلہ (Form III)', '(IV)': 'باب افعال (Form IV)',
    '(V)': 'باب تفعّل (Form V)', '(VI)': 'باب تفاعل (Form VI)',
    '(VII)': 'باب انفعال (Form VII)', '(VIII)': 'باب افتعال (Form VIII)',
    '(IX)': 'باب افعلال (Form IX)', '(X)': 'باب استفعال (Form X)',
  };

  static bool _ur(String lang) => lang == 'ur';

  /// Friendly name of a main tag (also used for the "part of speech" row).
  static String? tagName(String tag, String lang) =>
      (_ur(lang) ? _tagUr[tag] : null) ?? tagNames[tag];

  static String roleName(String role, String lang) {
    const en = {'PREFIX': 'prefix', 'STEM': 'stem', 'SUFFIX': 'suffix'};
    const ur = {'PREFIX': 'سابقہ', 'STEM': 'اصل لفظ', 'SUFFIX': 'لاحقہ'};
    return (_ur(lang) ? ur[role] : en[role]) ?? role.toLowerCase();
  }

  /// Person + gender + number code such as 3MS, 2MP, 1S, MS, FP.
  /// Returns null if the token is not such a code.
  static String? personCode(String token, {required bool asPronoun, String lang = 'en'}) {
    final m = RegExp(r'^([123])?([MF])?([SDP])$').firstMatch(token);
    if (m == null) return null;
    final ur = _ur(lang);
    final person = m.group(1);
    final gender = m.group(2);
    final number = m.group(3)!;

    final personWords = ur
        ? const {'1': 'متکلم', '2': 'مخاطب', '3': 'غائب'}
        : const {'1': '1st person', '2': '2nd person', '3': '3rd person'};
    final genderWords = ur
        ? const {'M': 'مذکر', 'F': 'مؤنث'}
        : const {'M': 'masculine', 'F': 'feminine'};
    final numberWords = ur
        ? const {'S': 'واحد', 'D': 'تثنیہ', 'P': 'جمع'}
        : const {'S': 'singular', 'D': 'dual', 'P': 'plural'};

    final words = [
      if (person != null) personWords[person]!,
      if (gender != null) genderWords[gender]!,
      numberWords[number]!,
    ];
    var text = words.join(ur ? '، ' : ', ');

    if (person != null) {
      final Map<String, String> hint;
      if (asPronoun) {
        hint = ur
            ? const {
                '1S': 'میں / مجھے / میرا', '1P': 'ہم / ہمیں / ہمارا',
                '2MS': 'تم / آپ (مذکر واحد)', '2FS': 'تم (مؤنث واحد)',
                '2MP': 'تم سب (مذکر)',
                '3MS': 'وہ / اسے / اس کا (مذکر)', '3FS': 'وہ / اسے / اس کا (مؤنث)',
                '3MP': 'وہ سب / ان کا (مذکر)', '3FP': 'وہ سب (مؤنث)',
              }
            : const {
                '1S': 'I / me / my', '1P': 'we / us / our',
                '2MS': 'you (m.)', '2FS': 'you (f.)', '2MP': 'you all (m.)',
                '3MS': 'he / him / his', '3FS': 'she / her',
                '3MP': 'they / them / their (m.)', '3FP': 'they / them (f.)',
              };
      } else {
        hint = ur
            ? const {
                '3MS': 'وہ (مذکر)', '3FS': 'وہ (مؤنث)', '3MP': 'وہ سب (مذکر)',
                '3FP': 'وہ سب (مؤنث)', '2MS': 'تم (مذکر)', '2MP': 'تم سب (مذکر)',
                '1S': 'میں', '1P': 'ہم',
              }
            : const {
                '3MS': 'he / it', '3FS': 'she / it', '3MP': 'they (m.)',
                '3FP': 'they (f.)', '2MS': 'you (m.)', '2MP': 'you all (m.)',
                '1S': 'I', '1P': 'we',
              };
      }
      final h = hint[token];
      if (h != null) text = '$text = $h';
    }
    return text;
  }

  /// Splits the whole word string into parts. Never throws.
  static List<GrammarPart> parse(String raw, {String lang = 'en'}) {
    if (raw.trim().isEmpty) return const [];
    final parts = <GrammarPart>[];
    for (final piece in raw.split(' ; ')) {
      try {
        parts.add(_parsePart(piece.trim(), lang));
      } catch (_) {
        parts.add(_failed(piece, lang));
      }
    }
    return parts;
  }

  static GrammarPart _failed(String piece, String lang) => GrammarPart(
      form: '', tag: '?', role: '', features: const [],
      explanation: _ur(lang) ? 'دستیاب نہیں' : 'Not available', unknown: [piece]);

  static GrammarPart _parsePart(String piece, String lang) {
    final ur = _ur(lang);
    final eq = piece.indexOf('=');
    if (eq < 0) return _failed(piece, lang);
    final form = piece.substring(0, eq);
    final tokens = piece.substring(eq + 1).split('|');

    // First token is "TAG:ROLE", e.g. "N:STEM" or "P:PREFIX".
    final first = tokens.first.split(':');
    final tag = first.first;
    final role = first.length > 1 ? first[1] : '';
    final features = tokens.skip(1).toList();

    final feat = ur ? _featUr : _featEn;
    final forms = ur ? _formUr : _formEn;
    final unknown = <String>[];
    final bits = <String>[]; // person/gender/number phrases
    final plain = <String>[]; // simple names like feminine, genitive
    var verbForm = '';
    var isParticiple = false, isPassive = false, isActive = false;

    for (final f in features) {
      if (f.startsWith('LEM:') || f.startsWith('ROOT:') ||
          f.startsWith('POS:') || f.startsWith('SP:')) {
        continue; // shown elsewhere in the app
      }
      if (f.endsWith('+')) continue; // prefix helper like "bi+" or "Al+"
      if (forms.containsKey(f)) {
        verbForm = forms[f]!;
        continue;
      }
      if (f.startsWith('PRON:')) {
        final code = personCode(f.substring(5), asPronoun: true, lang: lang);
        code != null ? bits.add(code) : unknown.add(f);
        continue;
      }
      final person = personCode(f, asPronoun: tag == 'PRON', lang: lang);
      if (person != null) {
        bits.add(person);
        continue;
      }
      if (f == 'ACT') { isActive = true; continue; }
      if (f == 'PASS') { isPassive = true; continue; }
      if (f == 'PCPL') { isParticiple = true; continue; }
      final name = feat[f];
      name != null ? plain.add(name) : unknown.add(f);
    }

    if (isParticiple) {
      plain.insert(
          0,
          isPassive
              ? (ur ? 'اسمِ مفعول' : 'passive participle')
              : isActive
                  ? (ur ? 'اسمِ فاعل' : 'active participle')
                  : (ur ? 'مشتق (participle)' : 'participle'));
    } else {
      if (isActive) plain.add(ur ? 'معروف' : 'active');
      if (isPassive) plain.add(ur ? 'مجہول' : 'passive');
    }

    final sentence = <String>[];
    final label = tagName(tag, lang);
    if (label != null) {
      sentence.add(label);
    } else {
      sentence.add(ur ? 'حصہ "$tag"' : 'Part "$tag"');
      unknown.add(tag);
    }
    if (role == 'PREFIX') {
      sentence.add(ur ? 'لفظ کے شروع میں جڑا ہوا' : 'attached to the start of the word');
    } else if (role == 'SUFFIX') {
      sentence.add(ur ? 'لفظ کے آخر میں جڑا ہوا' : 'attached to the end of the word');
    }
    if (verbForm.isNotEmpty) {
      sentence.add(ur ? 'فعل کا وزن: $verbForm' : '$verbForm verb pattern');
    }
    sentence..addAll(plain)..addAll(bits);

    return GrammarPart(
      form: form, tag: tag, role: role, features: features,
      explanation: sentence.join(ur ? '، ' : ', '),
      unknown: unknown,
    );
  }

  /// One-sentence summary for a whole word, built only from its parts.
  /// "Follows a preposition" is added only when the data shows a P prefix on
  /// the same word and a genitive stem - that is supported by the data.
  static String summarize(String raw, {String lang = 'en'}) {
    final parts = parse(raw, lang: lang);
    if (parts.isEmpty) return _ur(lang) ? 'گرامر دستیاب نہیں' : 'Grammar not available';
    final hasPrepPrefix = parts.any((p) => p.tag == 'P' && p.role == 'PREFIX');
    final reason = _ur(lang)
        ? '(کیونکہ اس سے حرفِ جار جڑا ہوا ہے)'
        : '(because it follows the preposition attached to it)';
    return parts.map((p) {
      final extra = p.role == 'STEM' && hasPrepPrefix && p.features.contains('GEN');
      return extra ? '${p.explanation} $reason' : p.explanation;
    }).join(' + ');
  }
}
