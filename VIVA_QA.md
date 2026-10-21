# Viva questions and short answers

1. **How is the app organised?**
   `core/` = pure logic (no screens), `data/` = models + loading + saving,
   `features/` = one folder per screen group, `widgets/` = shared pieces.

2. **How does the app work offline?**
   Everything is bundled: `quran.json`, 30 mp3 files, fonts. There are no
   network calls and the release manifest has no INTERNET permission.

3. **Why not SQLite?**
   It does not run on Chrome. The JSON is small (333 words), so it is loaded
   into memory once. User data is small too, so `shared_preferences` is enough.

4. **How is state managed?**
   With `provider`. Each controller is a `ChangeNotifier`; screens call
   `context.watch` to rebuild when data changes and `context.read` to act.

5. **How does the grammar parser work?**
   A word's grammar is text like `bi=P:PREFIX|bi+ ; yadi=N:STEM|FS|GEN`. We
   split on ` ; ` into parts, read `TAG:ROLE`, then translate each feature
   through a lookup table (English or Urdu). Unknown tags are shown raw.

6. **Why is ACC handled specially?**
   As the first tag it is an accusative *particle*; as a later feature it is
   the accusative *case*. The parser reads the position to tell them apart.

7. **How do flashcards decide when a card comes back?**
   Leitner boxes 1 to 5 with delays of 0, 1, 3, 7 and 14 days. Again = box 1,
   Hard = same box, Good = +1 box, Easy = +2 boxes.

8. **How does the streak work?**
   We store the days the user was active. If today is active we count
   backwards; if only yesterday is active the streak is still alive; any
   missed day gives 0. (`core/streak.dart`, unit tested.)

9. **How does the quiz avoid unfair or repeated questions?**
   Wrong options come from other surah words with the same part of speech and
   all options are different. A set of "signatures" stops repeats. Tests run
   20 random quizzes on the real data.

10. **How is the Arabic text protected?**
    It is only read from JSON and displayed. Search uses a simplified *copy*
    (no diacritics) for matching and never changes the shown text.

11. **How do Urdu and right-to-left work?**
    Setting the app locale to Urdu flips the layout. Quran/Urdu text is
    wrapped in `Directionality`. Strings are a simple map in `strings.dart`
    with English fallback.

12. **How do backup and restore work?**
    All saved keys are put into one JSON text. Restore checks a marker,
    writes the keys back, and every controller re-reads its data.

13. **What could not be done, and why?**
    Tajweed colours and per-word audio highlighting (no data), tafseer and
    Sindhi (no data), Urdu word meanings (no data). None were faked.

14. **What are the licence risks?**
    The Quranic Arabic Corpus is GPL, so publishing needs a licence check.
    Fonts are SIL OFL. All credits are on the Credits screen.
