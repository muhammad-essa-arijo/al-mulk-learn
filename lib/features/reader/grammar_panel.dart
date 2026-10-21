import 'package:flutter/material.dart';
import '../../core/grammar_parser.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../settings/settings_controller.dart';
import '../word_detail/word_detail_sheet.dart';

/// Lists every word of an ayah with its grammar in friendly language.
void showAyahGrammar(BuildContext context, Ayah ayah) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: ayah.words.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${context.tr('ayahGrammar')} (${ayah.number})',
                  style: Theme.of(context).textTheme.titleMedium),
            );
          }
          final w = ayah.words[i - 1];
          final lang = context.watch<SettingsController>().uiLang;
          final unknown = [
            for (final p in GrammarParser.parse(w.grammar, lang: lang)) ...p.unknown
          ];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              onTap: () => showWordDetail(context, w),
              contentPadding: const EdgeInsets.all(12),
              title: Row(children: [
                Text(w.arabic,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 28, height: 1.8)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('${w.translit} • ${w.meaning}',
                        style: Theme.of(context).textTheme.bodyMedium)),
              ]),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  GrammarParser.summarize(w.grammar, lang: lang) +
                      (unknown.isEmpty ? '' : '\nraw: ${unknown.join(', ')}'),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
