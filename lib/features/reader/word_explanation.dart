import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/grammar_parser.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../settings/settings_controller.dart';

/// Explanation built ONLY from the data we already have (word meaning,
/// root and grammar from quran.json). Nothing is invented here.
/// It is shown when the ayah has no scholarly tafseer in the data.
class WordExplanation extends StatelessWidget {
  final Ayah ayah;
  const WordExplanation({super.key, required this.ayah});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsController>().uiLang;
    final small = Theme.of(context).textTheme.bodySmall;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Honest note: this is not a tafseer.
      Text(context.tr('explanationFromData'), style: small),
      const SizedBox(height: 8),
      for (final w in ayah.words)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Arabic word (right-to-left font)
            Text(w.arabic,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // transliteration + English meaning
                Text('${w.translit} • ${w.meaning}',
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodyMedium),
                // root letters, only if the data has them
                if (w.root.isNotEmpty)
                  Text('${context.tr('root')}: ${w.root}', style: small),
                // grammar sentence made by GrammarParser
                Text(GrammarParser.summarize(w.grammar, lang: lang), style: small),
              ]),
            ),
          ]),
        ),
    ]);
  }
}
