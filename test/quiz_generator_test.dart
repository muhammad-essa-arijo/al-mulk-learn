import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/quiz_generator.dart';
import 'package:quran_app/data/models.dart';

void main() {
  // Uses the real data file, so the test checks real questions.
  final json = jsonDecode(File('assets/quran.json').readAsStringSync());
  final ayahs = [
    for (final a in json['ayahs']) Ayah.fromJson(a as Map<String, dynamic>)
  ];

  for (final level in ['beginner', 'intermediate']) {
    test('$level quiz: 10 valid, unique questions', () {
      for (var seed = 0; seed < 20; seed++) {
        final gen = QuizGenerator(ayahs, rng: Random(seed));
        final qs = gen.generate(level: level);
        expect(qs.length, 10);
        expect(qs.map((q) => q.signature).toSet().length, 10,
            reason: 'no repeated question');
        for (final q in qs) {
          if (q.type == QuizType.match) {
            expect(q.pairs.length, 5);
            continue;
          }
          expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
          expect(q.options.toSet().length, q.options.length,
              reason: 'options are all different');
          expect(q.options.length, level == 'intermediate' ? 4 : 3);
        }
      }
    });
  }

  test('beginner level never asks root questions', () {
    final qs = QuizGenerator(ayahs, rng: Random(1)).generate(level: 'beginner');
    expect(qs.any((q) => q.type == QuizType.root), false);
  });

  test('meaning question: correct option is the real meaning', () {
    final all = [for (final a in ayahs) ...a.words];
    final qs = QuizGenerator(ayahs, rng: Random(3))
        .generate(types: [QuizType.meaning]);
    for (final q in qs) {
      final correct = q.options[q.correctIndex];
      expect(all.any((w) => w.meaning == correct && w.translit == q.promptText),
          true);
    }
  });

  test('fill-blank hides exactly one word', () {
    final qs = QuizGenerator(ayahs, rng: Random(5))
        .generate(types: [QuizType.fillBlank]);
    for (final q in qs) {
      expect('_____'.allMatches(q.arabic).length, 1);
    }
  });

  test('focus keys: weak-word quiz asks about those words', () {
    final gen = QuizGenerator(ayahs, rng: Random(2));
    final key = ayahs.first.words.first.groupKey;
    final qs = gen.generate(
        types: [QuizType.meaning], focusKeys: {key}, count: 1);
    expect(qs.single.wordKeys, [key]);
  });
}
