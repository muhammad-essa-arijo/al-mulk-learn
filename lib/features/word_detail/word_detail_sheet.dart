import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/grammar_parser.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/quran_repository.dart';
import '../common/library_controller.dart';
import '../common/note_dialog.dart';
import '../common/progress_controller.dart';
import '../settings/settings_controller.dart';

/// Opens the Word Detail bottom sheet for one word.
void showWordDetail(BuildContext context, Word word) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _WordDetail(word: word, scroll: scroll),
    ),
  );
}

class _WordDetail extends StatelessWidget {
  final Word word;
  final ScrollController scroll;
  const _WordDetail({required this.word, required this.scroll});

  // One labelled row, e.g. "Root   برك"
  Widget _row(BuildContext context, String label, Widget value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary))),
          Expanded(child: value),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final lib = context.watch<LibraryController>();
    final progress = context.watch<ProgressController>();
    final c = Theme.of(context).colorScheme;
    final lang = context.watch<SettingsController>().uiLang;
    final parts = GrammarParser.parse(word.grammar, lang: lang);
    final saved = lib.savedWords.contains(word.groupKey);
    final learned = progress.learnedWords.contains(word.groupKey);
    final sameRoot = word.root.isEmpty
        ? <Word>[]
        : repo.wordsWithRoot(word.root).where((w) => w.id != word.id).toList();
    final noteKey = LibraryController.wordNoteKey(word.ayah, word.position);
    final note = lib.notes[noteKey];

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Center(
          child: Text(word.arabic,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontFamily: 'AmiriQuran', fontSize: 52, height: 1.9)),
        ),
        Center(
            child: Text(word.translit,
                style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height: 4),
        Center(
            child: Text(word.meaning.isEmpty ? '—' : word.meaning,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: c.primary, fontWeight: FontWeight.w700))),
        const SizedBox(height: 4),
        Center(
            child: Text(context.tr('meaningNote'),
                style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(height: 12),

        // Save + learned buttons
        Row(children: [
          Expanded(
            child: FilledButton.tonalIcon(
              icon: Icon(saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined),
              label: Text(context.tr(saved ? 'savedVocab' : 'saveVocab'),
                  textAlign: TextAlign.center),
              onPressed: () => lib.toggleSavedWord(word.groupKey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              icon: Icon(learned ? Icons.check_circle_rounded : Icons.check_circle_outline),
              label: Text(context.tr(learned ? 'learnedDone' : 'markLearned'),
                  textAlign: TextAlign.center),
              onPressed: () => learned
                  ? progress.unmarkWordLearned(word.groupKey)
                  : progress.markWordLearned(word.groupKey),
            ),
          ),
        ]),
        const Divider(height: 28),

        _row(context, context.tr('root'),
            Text(word.root.isEmpty ? context.tr('noRoot') : word.root,
                textDirection: word.root.isEmpty ? null : TextDirection.rtl,
                style: TextStyle(
                    fontFamily: word.root.isEmpty ? null : 'AmiriQuran',
                    fontSize: word.root.isEmpty ? 15 : 24))),
        _row(context, context.tr('lemma'),
            Text(word.lemma.isEmpty ? '—' : word.lemma,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 22))),
        _row(context, context.tr('partOfSpeech'),
            Text(GrammarParser.tagName(word.pos, lang) ?? (word.pos.isEmpty ? '—' : word.pos))),
        const Divider(height: 28),

        // Grammar breakdown: each prefix / stem / suffix explained simply.
        Text(context.tr('grammarBreakdown'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final p in parts)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(p.explanation),
              subtitle: Text(
                [
                  if (p.role.isNotEmpty) GrammarParser.roleName(p.role, lang),
                  if (p.form.isNotEmpty) '"${p.form}"',
                  // Tags we do not know are shown small and raw, never hidden.
                  if (p.unknown.isNotEmpty) 'raw: ${p.unknown.join(', ')}',
                ].join(' • '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(GrammarParser.summarize(word.grammar, lang: lang),
            style: Theme.of(context).textTheme.bodyMedium),
        const Divider(height: 28),

        // Other words with the same root (computed from the data)
        Text(context.tr('sameRoot'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (sameRoot.isEmpty)
          Text(word.root.isEmpty ? context.tr('noRoot') : '—')
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final w in sameRoot)
              ActionChip(
                label: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text('${w.arabic}  (${w.ayah}:${w.position})',
                      style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  showWordDetail(context, w);
                },
              ),
          ]),
        const Divider(height: 28),

        // Personal note on this word
        if (note != null)
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(note))),
        TextButton.icon(
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(context.tr(note == null ? 'addNote' : 'editNote')),
          onPressed: () => showNoteDialog(context,
              noteKey: noteKey, title: '${word.arabic}  ${word.translit}'),
        ),
      ],
    );
  }
}
