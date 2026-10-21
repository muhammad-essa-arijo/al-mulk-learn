import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/quran_repository.dart';
import '../../widgets/translation_text.dart';
import '../settings/settings_controller.dart';

/// Shows a preview card of the ayah. On Android it can be shared as an image.
/// On Chrome (web) we only offer "Copy text", because image sharing is not
/// reliable in browsers.
Future<void> showShareDialog(BuildContext context, Ayah ayah) {
  return showDialog<void>(
      context: context, builder: (_) => _ShareDialog(ayah: ayah));
}

class _ShareDialog extends StatelessWidget {
  final Ayah ayah;
  _ShareDialog({required this.ayah});

  final GlobalKey _cardKey = GlobalKey(); // lets us "photograph" the card

  /// First chosen language that has text for this ayah (or null).
  String? _lang(SettingsController s) {
    for (final l in s.translationLangs) {
      if (ayah.translations.containsKey(l)) return l;
    }
    return null;
  }

  String _reference(QuranRepository repo) =>
      'Surah ${repo.surahName} ${repo.surahNumber}:${ayah.number}';

  String _plainText(QuranRepository repo, String? lang) => [
        ayah.arabic,
        if (lang != null) ayah.translations[lang]!,
        _reference(repo),
      ].join('\n\n');

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('copied'))));
    }
  }

  Future<void> _share(BuildContext context, String text) async {
    try {
      // Turn the card widget into a PNG picture.
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();
      await SharePlus.instance.share(ShareParams(
        text: text,
        files: [
          XFile.fromData(bytes,
              mimeType: 'image/png', name: 'al_mulk_${ayah.number}.png')
        ],
      ));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('shareFailed'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final s = context.watch<SettingsController>();
    final lang = _lang(s);
    final text = _plainText(repo, lang);
    // Fixed colours so the picture looks the same in every app theme.
    const cream = Color(0xFFFBF8F1);
    const emerald = Color(0xFF1F7A5C);
    const gold = Color(0xFFC9A24B);
    const ink = Color(0xFF2A3A36);

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold, width: 3)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_reference(repo),
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        color: emerald,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const Divider(color: gold, height: 24),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(ayah.arabic,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 26,
                          height: 2,
                          color: ink)),
                ),
                if (lang != null) ...[
                  const SizedBox(height: 10),
                  TranslationText(
                      lang: lang,
                      text: ayah.translations[lang]!,
                      size: 14,
                      color: ink),
                ],
                const Divider(color: gold, height: 24),
                const Text('Al-Mulk Learn',
                    style: TextStyle(
                        fontFamily: 'Inter', color: gold, fontSize: 12)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
            if (!kIsWeb)
              FilledButton.icon(
                icon: const Icon(Icons.share_rounded),
                label: Text(context.tr('shareBtn')),
                onPressed: () => _share(context, text),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_rounded),
              label: Text(context.tr('copyText')),
              onPressed: () => _copy(context, text),
            ),
          ]),
        ]),
      ),
    );
  }
}
