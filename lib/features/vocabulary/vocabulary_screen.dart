import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../../core/text_utils.dart';
import '../../data/models.dart';
import '../../data/quran_repository.dart';
import '../common/library_controller.dart';
import '../common/practice_controller.dart';
import '../common/progress_controller.dart';
import '../flashcards/flashcards_screen.dart';
import '../word_detail/word_detail_sheet.dart';

/// All unique words (grouped by lemma) with filters and sorting.
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});
  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  String _filter = 'all'; // all, saved, learned, weak
  String _sort = 'order'; // order, freq, alpha

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final lib = context.watch<LibraryController>();
    final progress = context.watch<ProgressController>();
    final practice = context.watch<PracticeController>();
    final c = Theme.of(context).colorScheme;

    // 1) filter
    var words = repo.uniqueWords.toList();
    switch (_filter) {
      case 'saved':
        words = words.where((w) => lib.savedWords.contains(w.groupKey)).toList();
      case 'learned':
        words = words.where((w) => progress.learnedWords.contains(w.groupKey)).toList();
      case 'weak':
        words = words.where((w) => practice.weakKeys.contains(w.groupKey)).toList();
    }
    // 2) sort
    int order(Word a, Word b) =>
        a.ayah != b.ayah ? a.ayah.compareTo(b.ayah) : a.position.compareTo(b.position);
    switch (_sort) {
      case 'freq':
        words.sort((a, b) {
          final f = repo.frequency(b).compareTo(repo.frequency(a));
          return f != 0 ? f : order(a, b);
        });
      case 'alpha':
        words.sort((a, b) => normalizeArabic(a.lemma.isEmpty ? a.arabic : a.lemma)
            .compareTo(normalizeArabic(b.lemma.isEmpty ? b.arabic : b.lemma)));
      default:
        words.sort(order);
    }

    final filters = {
      'all': context.tr('filterAll'),
      'saved': context.tr('filterSaved'),
      'learned': context.tr('filterLearned'),
      'weak': context.tr('filterWeak'),
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('vocabulary'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(children: [
            Expanded(
              child: Wrap(spacing: 6, children: [
                for (final e in filters.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _filter == e.key,
                    onSelected: (_) => setState(() => _filter = e.key),
                  ),
              ]),
            ),
            PopupMenuButton<String>(
              tooltip: context.tr('sortBy'),
              icon: const Icon(Icons.sort_rounded),
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => [
                CheckedPopupMenuItem(value: 'order', checked: _sort == 'order', child: Text(context.tr('sortOrder'))),
                CheckedPopupMenuItem(value: 'freq', checked: _sort == 'freq', child: Text(context.tr('sortFreq'))),
                CheckedPopupMenuItem(value: 'alpha', checked: _sort == 'alpha', child: Text(context.tr('sortAlpha'))),
              ],
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Text('${words.length} / ${repo.uniqueWords.length}',
                style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            if (_filter == 'saved' || _filter == 'weak')
              if (words.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.style_rounded),
                  label: Text(context.tr('reviewSaved')),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FlashcardsScreen(filter: _filter))),
                ),
          ]),
        ),
        Expanded(
          child: words.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inbox_outlined, size: 56, color: c.secondary),
                    const SizedBox(height: 8),
                    Text(context.tr('nothingHere')),
                  ]),
                )
              : ListView.builder(
                  itemCount: words.length,
                  itemBuilder: (context, i) {
                    final w = words[i];
                    final saved = lib.savedWords.contains(w.groupKey);
                    final learned = progress.learnedWords.contains(w.groupKey);
                    return ListTile(
                      onTap: () => showWordDetail(context, w),
                      leading: SizedBox(
                        width: 84,
                        child: Text(w.arabic,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, height: 1.8)),
                      ),
                      title: Text(w.meaning.isEmpty ? '—' : w.meaning),
                      subtitle: Text(
                          '${w.translit} • ×${repo.frequency(w)} ${context.tr('times')}'
                          '${w.root.isEmpty ? '' : ' • ${w.root}'}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (learned) Icon(Icons.check_circle_rounded, color: c.primary, size: 20),
                        IconButton(
                          tooltip: context.tr('saveVocab'),
                          icon: Icon(saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                              color: saved ? c.secondary : null),
                          onPressed: () => lib.toggleSavedWord(w.groupKey),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
