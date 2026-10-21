import 'package:flutter/material.dart';
import '../../core/strings.dart';

/// Credits and licenses. Names are kept exactly as the sources require.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget section(String title, List<String> lines) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final l in lines)
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(l)),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('credits'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        section(context.tr('secSources'), const [
          'Arabic text and English/Urdu translations: AlQuran Cloud API (alquran.cloud). '
              'English: Saheeh International. Urdu: Fateh Muhammad Jalandhry.',
          'Word-by-word meanings and transliteration: Quran.com (Quran Foundation).',
          'Grammar, roots and morphology: The Quranic Arabic Corpus (corpus.quran.com), '
              'Kais Dukes, University of Leeds, under the GNU General Public License.',
          'Audio recitation: Mishary Rashid Alafasy via EveryAyah.com.',
        ]),
        section(context.tr('secFonts'), const [
          'Amiri Quran - SIL Open Font License 1.1',
          'Noto Nastaliq Urdu - SIL Open Font License 1.1',
          'Inter - SIL Open Font License 1.1',
        ]),
        section(context.tr('secPackages'), const [
          'provider, shared_preferences, scrollable_positioned_list, just_audio, '
              'share_plus, file_picker, flutter_local_notifications, timezone, '
              'flutter_timezone, flutter_localizations (Flutter SDK).',
        ]),
        section('GPL', [context.tr('gplNote')]),
        const SizedBox(height: 4),
        FilledButton.icon(
          icon: const Icon(Icons.description_outlined),
          label: Text(context.tr('openLicenses')),
          onPressed: () => showLicensePage(
              context: context, applicationName: 'Al-Mulk Learn', applicationVersion: '1.0.0'),
        ),
      ]),
    );
  }
}
