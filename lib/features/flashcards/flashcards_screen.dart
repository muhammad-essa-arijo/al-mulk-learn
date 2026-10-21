import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/spaced_repetition.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/quran_repository.dart';
import '../common/library_controller.dart';
import '../common/practice_controller.dart';
import '../common/progress_controller.dart';
import '../settings/settings_controller.dart';

/// Flashcards using Leitner boxes (see core/spaced_repetition.dart).
/// Today's session = cards that are due + a few new cards (your daily goal).
class FlashcardsScreen extends StatefulWidget {
  final String filter; // all, saved, weak
  const FlashcardsScreen({super.key, this.filter = 'all'});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late String _filter;
  List<Word> _queue = [];
  int _i = 0;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
    _buildQueue();
  }

  void _buildQueue() {
    final repo = context.read<QuranRepository>();
    final lib = context.read<LibraryController>();
    final practice = context.read<PracticeController>();
    final goal = context.read<SettingsController>().dailyGoal;
    final now = DateTime.now();

    var words = repo.uniqueWords.where((w) => w.meaning.isNotEmpty);
    if (_filter == 'saved') words = words.where((w) => lib.savedWords.contains(w.groupKey));
    if (_filter == 'weak') words = words.where((w) => practice.weakKeys.contains(w.groupKey));

    final due = <Word>[];
    final fresh = <Word>[];
    for (final w in words) {
      final s = practice.cards[w.groupKey];
      if (s == null) {
        fresh.add(w);
      } else if (isDue(s, now)) {
        due.add(w);
      }
    }
    // Due cards come first, oldest due date first.
    due.sort((a, b) => practice.cards[a.groupKey]!.due.compareTo(practice.cards[b.groupKey]!.due));
    _queue = [...due, ...fresh.take(goal)];
    _i = 0;
    _flipped = false;
  }

  void _rate(Rating r) {
    final w = _queue[_i];
    context.read<PracticeController>().reviewFlashcard(w.groupKey, r);
    context.read<ProgressController>().recordActivity();
    setState(() {
      if (r == Rating.again) _queue.add(w); // see it again in this session
      _i++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final filters = {
      'all': context.tr('filterAll'),
      'saved': context.tr('filterSaved'),
      'weak': context.tr('filterWeak'),
    };
    final finished = _i >= _queue.length;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('flashcards'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Wrap(spacing: 8, children: [
            for (final e in filters.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _filter == e.key,
                onSelected: (_) => setState(() {
                  _filter = e.key;
                  _buildQueue();
                }),
              ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: finished ? _doneView(context) : _cardView(context, c),
          ),
        ]),
      ),
    );
  }

  Widget _doneView(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final empty = _queue.isEmpty;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(empty ? Icons.inbox_outlined : Icons.celebration_rounded, size: 64, color: c.secondary),
        const SizedBox(height: 12),
        Text(context.tr(empty ? 'noCards' : 'allDone'),
            style: Theme.of(context).textTheme.titleLarge),
        if (!empty) Text(context.tr('allDoneBody')),
      ]),
    );
  }

  Widget _cardView(BuildContext context, ColorScheme c) {
    final w = _queue[_i];
    final left = _queue.length - _i;
    return Column(children: [
      Text('$left ${context.tr('cardsLeft')}', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _flipped = !_flipped),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Card(
              key: ValueKey('${w.groupKey}-$_flipped-$_i'),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _flipped ? _back(context, w, c) : _front(context, w),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (_flipped)
        Row(children: [
          for (final r in Rating.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FilledButton.tonal(
                  onPressed: () => _rate(r),
                  child: Text(context.tr(r.name)),
                ),
              ),
            ),
        ])
      else
        const SizedBox(height: 48),
    ]);
  }

  Widget _front(BuildContext context, Word w) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(w.arabic,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 56, height: 2)),
        const SizedBox(height: 12),
        Text(context.tr('tapToFlip'), style: Theme.of(context).textTheme.bodySmall),
      ]);

  Widget _back(BuildContext context, Word w, ColorScheme c) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(w.meaning,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(w.translit, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (w.root.isNotEmpty)
          Text('${context.tr('root')}: ${w.root}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24)),
      ]);
}
