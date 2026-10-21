import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../widgets/translation_text.dart';
import '../audio/audio_controller.dart';
import '../common/library_controller.dart';
import '../common/note_dialog.dart';
import '../common/progress_controller.dart';
import '../settings/settings_controller.dart';
import '../word_detail/word_detail_sheet.dart';
import 'grammar_panel.dart';
import 'word_explanation.dart';
import 'share_dialog.dart';

/// One ayah: Arabic (plain or word-by-word), translations, notes, explanation.
class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final bool highlighted; // used by the audio player in a later step
  const AyahCard({super.key, required this.ayah, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final lib = context.watch<LibraryController>();
    final progress = context.watch<ProgressController>();
    final c = Theme.of(context).colorScheme;
    // Is this the ayah that is loaded / playing right now?
    final isCurrent = context
        .select<AudioController, bool>((a) => a.currentAyah == ayah.number);
    final isPlaying = context.select<AudioController, bool>(
        (a) => a.currentAyah == ayah.number && a.playing);
    final audio = context.read<AudioController>();
    final bookmarked = lib.bookmarks.contains(ayah.number);
    final studied = progress.studiedAyahs.contains(ayah.number);
    final note = lib.notes[LibraryController.ayahNoteKey(ayah.number)];

    // Only languages the user chose AND that have data for this ayah.
    final langs = s.translationLangs.where(ayah.translations.containsKey).toList();

    // Explanation (tafseer): the data has none yet, so this is usually empty.
    String? tafseerLang;
    for (final l in [...s.translationLangs, 'en']) {
      if (ayah.tafseer.containsKey(l)) {
        tafseerLang = l;
        break;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (highlighted || isCurrent) ? c.secondary : Colors.transparent,
            width: 2),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Top row: number badge + action buttons (they wrap on small phones)
            Row(children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primary.withValues(alpha: 0.12),
                    border: Border.all(color: c.secondary)),
                child: Text('${ayah.number}',
                    style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Wrap(alignment: WrapAlignment.end, children: [
                  IconButton(
                    tooltip: context.tr(isPlaying ? 'pause' : 'play'),
                    icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_outline_rounded,
                        color: c.primary),
                    onPressed: () => isCurrent
                        ? audio.togglePlayPause()
                        : audio.playAyah(ayah.number),
                  ),
                  IconButton(
                    tooltip: context.tr('grammar'),
                    icon: const Icon(Icons.account_tree_outlined),
                    onPressed: () => showAyahGrammar(context, ayah),
                  ),
                  IconButton(
                    tooltip: context.tr('addNote'),
                    icon: Icon(
                        note == null ? Icons.edit_note_rounded : Icons.sticky_note_2_rounded,
                        color: note == null ? null : c.secondary),
                    onPressed: () => showNoteDialog(context,
                        noteKey: LibraryController.ayahNoteKey(ayah.number),
                        title: '${context.tr('notes')} • ${ayah.number}'),
                  ),
                  IconButton(
                    tooltip: context.tr('bookmark'),
                    icon: Icon(
                        bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: bookmarked ? c.secondary : null),
                    onPressed: () => lib.toggleBookmark(ayah.number),
                  ),
                  PopupMenuButton<String>(
                    tooltip: context.tr('more'),
                    onSelected: (v) => v == 'studied'
                        ? progress.toggleAyahStudied(ayah.number)
                        : showShareDialog(context, ayah),
                    itemBuilder: (_) => [
                      CheckedPopupMenuItem(
                          value: 'studied',
                          checked: studied,
                          child: Text(context.tr('markStudied'))),
                      PopupMenuItem(
                          value: 'share', child: Text(context.tr('share'))),
                    ],
                  ),
                ]),
              ),
            ]),

            // Arabic text
            if (s.wordByWordView && ayah.words.isNotEmpty)
              _wordWrap(context, s)
            else
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(ayah.arabic,
                    style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: s.arabicSize,
                        height: s.lineSpacing + 0.3)),
              ),

            // Translations
            const SizedBox(height: 8),
            if (langs.isEmpty)
              Text(context.tr('translationNA'),
                  style: Theme.of(context).textTheme.bodySmall)
            else
              for (final l in langs)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TranslationText(
                      lang: l, text: ayah.translations[l]!, size: s.translationSize),
                ),

            // Personal note
            if (note != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: c.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(note),
              ),

            // Expandable explanation (tafseer)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(context.tr('explanation'),
                    style: Theme.of(context).textTheme.titleSmall),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: tafseerLang == null
                        // No tafseer in the data: show the word-by-word
                        // explanation built from the verified word data.
                        ? WordExplanation(ayah: ayah)
                        : TranslationText(
                            lang: tafseerLang,
                            text: ayah.tafseer[tafseerLang]!,
                            size: s.translationSize),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Word-by-word view: tappable words wrapped right-to-left.
  Widget _wordWrap(BuildContext context, SettingsController s) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        children: [
          for (final w in ayah.words)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showWordDetail(context, w),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48, maxWidth: 110),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(w.arabic,
                        style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: s.arabicSize,
                            height: 1.8)),
                    if (s.showTranslit && w.translit.isNotEmpty)
                      Text(w.translit,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context).textTheme.labelSmall),
                    if (s.showWordMeanings && w.meaning.isNotEmpty)
                      Text(w.meaning,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
