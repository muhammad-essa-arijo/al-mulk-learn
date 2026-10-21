import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/text_utils.dart';

void main() {
  test('Arabic search ignores diacritics and alef shapes', () {
    expect(normalizeArabic('ٱلْمُلْكُ'), normalizeArabic('الملك'));
    expect(normalizeArabic('تَبَـٰرَكَ'), normalizeArabic('تبرك'));
  });

  test('Latin search ignores accents', () {
    expect(normalizeLatin('tabāraka'), 'tabaraka');
    expect(normalizeLatin('ʿalā'), 'ala');
  });
}
