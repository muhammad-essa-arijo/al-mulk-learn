// Helpers used ONLY for searching. The text shown on screen is never changed;
// we compare simplified copies so that typing "ملك" finds "ٱلْمُلْكُ".

/// Removes Arabic diacritics and unifies letter shapes (for matching only).
String normalizeArabic(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final isMark = (r >= 0x064B && r <= 0x065F) || // fathah, kasrah, shaddah...
        r == 0x0670 || // dagger alif
        (r >= 0x06D6 && r <= 0x06ED) || // Quran small marks
        r == 0x0640; // tatweel (the stretch line)
    if (isMark) continue;
    if (r == 0x0671 || r == 0x0623 || r == 0x0625 || r == 0x0622) {
      b.writeCharCode(0x0627); // all alef shapes -> plain alef
    } else if (r == 0x0649) {
      b.writeCharCode(0x064A); // alef maqsura -> ya
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// Lower-cases and removes accents from transliteration, so "tabaraka"
/// matches "tabāraka".
String normalizeLatin(String s) {
  const map = {
    'ā': 'a', 'ī': 'i', 'ū': 'u', 'ḥ': 'h', 'ṣ': 's', 'ḍ': 'd', 'ṭ': 't',
    'ẓ': 'z', 'ġ': 'g', 'š': 's', 'ḳ': 'q',
  };
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(map[ch] ?? ch);
  }
  // Drop quote-like marks such as ʿ ʾ ` '
  return b.toString().replaceAll(RegExp(r"[ʿʾ`']"), '');
}
