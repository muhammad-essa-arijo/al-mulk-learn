import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/quran_repository.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/translation_text.dart';
import '../achievements/achievements_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../progress/progress_screen.dart';
import '../quiz/practice_screen.dart';
import '../vocabulary/vocabulary_screen.dart';
import '../common/progress_controller.dart';
import '../reader/reader_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final settings = context.watch<SettingsController>();
    final progress = context.watch<ProgressController>();
    final c = Theme.of(context).colorScheme;

    // Same word / ayah all day, a new one tomorrow (no randomness).
    final dayNumber =
        DateTime.now().difference(DateTime(2026, 1, 1)).inDays.abs();
    final pool = repo.uniqueWords.where((w) => w.meaning.isNotEmpty).toList();
    final Word? wotd = pool.isEmpty ? null : pool[dayNumber % pool.length];
    final dayAyah = repo.ayahs[dayNumber % repo.ayahs.length];
    final last = repo.ayah(progress.lastAyah.clamp(1, repo.ayahs.length));

    final goal = settings.dailyGoal;
    final done = progress.wordsToday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Al-Mulk Learn'),
        actions: [
          IconButton(
            tooltip: context.tr('search'),
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _go(context, const SearchScreen()),
          ),
          IconButton(
            tooltip: context.tr('badges'),
            icon: const Icon(Icons.emoji_events_rounded),
            onPressed: () => _go(context, const AchievementsScreen()),
          ),
          IconButton(
            tooltip: context.tr('bookmarks'),
            icon: const Icon(Icons.bookmarks_rounded),
            onPressed: () => _go(context, const BookmarksScreen()),
          ),
          IconButton(
            tooltip: context.tr('settings'),
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(context.tr('greeting'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),

          // Continue card
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _go(context, ReaderScreen(initialAyah: last.number)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.play_circle_fill_rounded, size: 40, color: c.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('continue'),
                              style: Theme.of(context).textTheme.titleSmall),
                          Text('${repo.surahName} • ${context.tr('ayah')} ${last.number}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Goal ring + streak
          Row(children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    ProgressRing(
                      value: goal == 0 ? 0 : done / goal,
                      child: Text('$done/$goal',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    Text('${context.tr('goal')} (${context.tr('words')})',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 48, color: c.secondary),
                    Text('${progress.streak}',
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text(context.tr('streak'),
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Quick buttons
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final b in [
              ('read', Icons.menu_book_rounded),
              ('practice', Icons.quiz_rounded),
              ('flashcards', Icons.style_rounded),
              ('vocabulary', Icons.translate_rounded),
              ('progress', Icons.insights_rounded),
            ])
              ActionChip(
                avatar: Icon(b.$2, size: 18, color: c.primary),
                label: Text(context.tr(b.$1)),
                onPressed: () {
                  switch (b.$1) {
                    case 'read':
                      _go(context, ReaderScreen(initialAyah: last.number));
                    case 'practice':
                      _go(context, const PracticeScreen());
                    case 'flashcards':
                      _go(context, const FlashcardsScreen());
                    case 'vocabulary':
                      _go(context, const VocabularyScreen());
                    default: // 'progress'
                      _go(context, const ProgressScreen());
                  }
                },
              ),
          ]),
          const SizedBox(height: 12),

          // Word of the day
          if (wotd != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text(context.tr('wordOfDay'),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: c.secondary)),
                  Text(wotd.arabic,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontFamily: 'AmiriQuran', fontSize: 38, height: 1.9)),
                  Text(wotd.translit,
                      style: Theme.of(context).textTheme.bodyMedium),
                  // Word meanings exist in English only.
                  Text(wotd.meaning,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: c.primary)),
                ]),
              ),
            ),
          const SizedBox(height: 12),

          // Ayah of the day
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text('${context.tr('ayahOfDay')} • ${dayAyah.number}',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: c.secondary)),
                const SizedBox(height: 8),
                Text(dayAyah.arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: settings.arabicSize,
                        height: 2)),
                // Show the first chosen language that has data for this ayah.
                for (final lang in settings.translationLangs
                    .where(dayAyah.translations.containsKey)
                    .take(1))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TranslationText(
                        lang: lang,
                        text: dayAyah.translations[lang]!,
                        size: settings.translationSize),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
