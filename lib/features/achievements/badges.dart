import 'package:flutter/material.dart';

/// A snapshot of the numbers used to decide which badges are earned.
class BadgeStats {
  final int streak, learned, studied, notes, bookmarks, quizzes, memorized, reviews;
  final bool perfectQuiz, night;
  final int ayahTotal;
  const BadgeStats({
    required this.streak, required this.learned, required this.studied,
    required this.notes, required this.bookmarks, required this.quizzes,
    required this.memorized, required this.reviews, required this.perfectQuiz,
    required this.night, required this.ayahTotal,
  });
}

class AppBadge {
  final String id;
  final IconData icon;
  final String titleEn, titleUr, descEn, descUr;
  final bool Function(BadgeStats) earned;
  const AppBadge(this.id, this.icon, this.titleEn, this.titleUr, this.descEn,
      this.descUr, this.earned);

  String title(String lang) => lang == 'ur' ? titleUr : titleEn;
  String desc(String lang) => lang == 'ur' ? descUr : descEn;
}

/// All badges. Each one is just a rule on the numbers above.
final List<AppBadge> allBadges = [
  AppBadge('first_ayah', Icons.menu_book_rounded, 'First Ayah', 'پہلی آیت',
      'Mark your first ayah as studied.', 'اپنی پہلی آیت کو پڑھی ہوئی کا نشان لگائیں۔',
      (s) => s.studied >= 1),
  AppBadge('first_word', Icons.spellcheck_rounded, 'First Word', 'پہلا لفظ',
      'Mark your first word as learned.', 'اپنا پہلا لفظ سیکھ لیا کا نشان لگائیں۔',
      (s) => s.learned >= 1),
  AppBadge('words_10', Icons.looks_one_rounded, '10 Words', 'دس الفاظ',
      'Learn 10 words.', 'دس الفاظ سیکھیں۔', (s) => s.learned >= 10),
  AppBadge('words_50', Icons.filter_5_rounded, '50 Words', 'پچاس الفاظ',
      'Learn 50 words.', 'پچاس الفاظ سیکھیں۔', (s) => s.learned >= 50),
  AppBadge('words_100', Icons.workspace_premium_rounded, '100 Words', 'سو الفاظ',
      'Learn 100 words.', 'سو الفاظ سیکھیں۔', (s) => s.learned >= 100),
  AppBadge('streak_3', Icons.local_fire_department_rounded, '3-Day Streak',
      'تین دن کا تسلسل', 'Be active 3 days in a row.', 'مسلسل تین دن سرگرم رہیں۔',
      (s) => s.streak >= 3),
  AppBadge('streak_7', Icons.whatshot_rounded, '7-Day Streak', 'سات دن کا تسلسل',
      'Be active 7 days in a row.', 'مسلسل سات دن سرگرم رہیں۔', (s) => s.streak >= 7),
  AppBadge('perfect_quiz', Icons.emoji_events_rounded, 'Perfect Quiz',
      'مکمل درست کوئز', 'Answer every question in a quiz correctly.',
      'کوئز کے تمام سوالات درست حل کریں۔', (s) => s.perfectQuiz),
  AppBadge('quiz_5', Icons.quiz_rounded, 'Quiz Lover', 'کوئز کا شوقین',
      'Finish 5 quizzes.', 'پانچ کوئز مکمل کریں۔', (s) => s.quizzes >= 5),
  AppBadge('night_reader', Icons.nights_stay_rounded, 'Night Reader', 'رات کا قاری',
      'Study between 10 pm and 4 am.', 'رات ۱۰ بجے سے صبح ۴ بجے کے درمیان پڑھیں۔',
      (s) => s.night),
  AppBadge('note_taker', Icons.edit_note_rounded, 'Note Taker', 'نوٹ لکھنے والا',
      'Write your first note.', 'اپنا پہلا نوٹ لکھیں۔', (s) => s.notes >= 1),
  AppBadge('bookmarker', Icons.bookmark_rounded, 'Bookmarker', 'نشان لگانے والا',
      'Bookmark an ayah.', 'کسی آیت پر نشان لگائیں۔', (s) => s.bookmarks >= 1),
  AppBadge('memorizer', Icons.psychology_rounded, 'Memorizer', 'حفظ کرنے والا',
      'Remember 3 ayahs in Memorization mode.', 'حفظ موڈ میں تین آیات یاد کریں۔',
      (s) => s.memorized >= 3),
  AppBadge('flash_50', Icons.style_rounded, 'Flashcard Fan', 'فلیش کارڈ کا شوقین',
      'Review 50 flashcards.', 'پچاس فلیش کارڈز دہرائیں۔', (s) => s.reviews >= 50),
  AppBadge('surah_complete', Icons.verified_rounded, 'Surah Complete', 'سورت مکمل',
      'Study all the ayahs of the surah.', 'سورت کی تمام آیات پڑھیں۔',
      (s) => s.studied >= s.ayahTotal),
];
