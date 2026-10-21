import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/grammar_parser.dart';

void main() {
  urduTests();
  test('splits a word into prefix, stem and suffix', () {
    final parts = GrammarParser.parse(
        'bi=P:PREFIX|bi+ ; yadi=N:STEM|POS:N|LEM:yad|ROOT:ydy|FS|GEN ; hi=PRON:SUFFIX|PRON:3MS');
    expect(parts.length, 3);
    expect(parts[0].tag, 'P');
    expect(parts[0].role, 'PREFIX');
    expect(parts[1].explanation, contains('Noun'));
    expect(parts[1].explanation, contains('feminine'));
    expect(parts[1].explanation, contains('genitive'));
    expect(parts[2].explanation, contains('he / him / his'));
  });

  test('explains a verb', () {
    final p = GrammarParser.parse(
        'taba`raka=V:STEM|POS:V|PERF|(VI)|LEM:tabaAraka|ROOT:brk|3MS').first;
    expect(p.explanation, contains('Verb'));
    expect(p.explanation, contains('past tense'));
    expect(p.explanation, contains('Form VI'));
  });

  test('ACC first = particle, ACC later = case', () {
    final particle = GrammarParser.parse('anna=ACC:STEM|POS:ACC|LEM:>an~a').first;
    expect(particle.explanation, contains('Accusative particle'));
    final noun = GrammarParser.parse('x=N:STEM|POS:N|MS|ACC').first;
    expect(noun.explanation, contains('accusative case'));
  });

  test('unknown tags and bad input never crash', () {
    final p = GrammarParser.parse('zz=QQQ:STEM|WEIRD').first;
    expect(p.unknown, contains('QQQ'));
    expect(p.unknown, contains('WEIRD'));
    expect(GrammarParser.parse('').isEmpty, true);
    expect(GrammarParser.parse('garbage').first.explanation, 'Not available');
  });
}

// Urdu explanations use standard grammar terms.
void urduTests() {
  test('Urdu: noun, feminine singular, genitive', () {
    final p = GrammarParser.parse(
        'yadi=N:STEM|POS:N|LEM:yad|ROOT:ydy|FS|GEN', lang: 'ur').first;
    expect(p.explanation, contains('اسم'));
    expect(p.explanation, contains('مؤنث'));
    expect(p.explanation, contains('مجرور'));
  });

  test('Urdu: verb past tense', () {
    final p = GrammarParser.parse(
        'x=V:STEM|POS:V|PERF|(VI)|ROOT:brk|3MS', lang: 'ur').first;
    expect(p.explanation, contains('فعل'));
    expect(p.explanation, contains('ماضی'));
  });

  test('Urdu: bad input still never crashes', () {
    expect(GrammarParser.parse('garbage', lang: 'ur').first.explanation, 'دستیاب نہیں');
  });
}
