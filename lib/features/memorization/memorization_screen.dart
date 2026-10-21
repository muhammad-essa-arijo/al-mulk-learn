import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/quran_repository.dart';
import '../audio/audio_controller.dart';
import '../common/practice_controller.dart';
import '../common/progress_controller.dart';

/// Memorization: hide some words, try to recall them, tap to reveal,
/// then say whether you remembered the ayah.
class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});
  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  RangeValues _range = const RangeValues(1, 3);
  String _mode = 'hide25'; // show, hide25, hide50, hide100, first
  bool _started = false;
  final Set<String> _revealed = {}; // "ayah:index"

  /// Which word positions of an ayah are hidden. The same ayah always gives
  /// the same answer (seeded by the ayah number), so it does not flicker.
  Set<int> _hiddenFor(Ayah a) {
    final n = a.words.length;
    final all = List.generate(n, (i) => i);
    Set<int> hidden;
    switch (_mode) {
      case 'show':
        hidden = {};
      case 'first':
        hidden = all.skip(1).toSet(); // show only the first word
      case 'hide100':
        hidden = all.toSet();
      default:
        final fraction = _mode == 'hide25' ? 0.25 : 0.5;
        final k = (n * fraction).round().clamp(1, n);
        hidden = (all..shuffle(Random(a.number))).take(k).toSet();
    }
    return hidden.where((i) => !_revealed.contains('${a.number}:$i')).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('memorization'))),
      body: _started ? _session(context) : _setup(context),
    );
  }

  Widget _setup(BuildContext context) {
    final modes = {
      'show': context.tr('showAll'),
      'hide25': context.tr('hide25'),
      'hide50': context.tr('hide50'),
      'hide100': context.tr('hide100'),
      'first': context.tr('firstWordOnly'),
    };
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('${context.tr('fromTo')}: ${_range.start.round()} – ${_range.end.round()}',
          style: Theme.of(context).textTheme.titleMedium),
      RangeSlider(
        values: _range,
        min: 1,
        max: 30,
        divisions: 29,
        labels: RangeLabels('${_range.start.round()}', '${_range.end.round()}'),
        onChanged: (v) => setState(() => _range = v),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in modes.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: _mode == e.key,
            onSelected: (_) => setState(() => _mode = e.key),
          ),
      ]),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => setState(() {
          _revealed.clear();
          _started = true;
        }),
        child: Text(context.tr('startPractice')),
      ),
    ]);
  }

  Widget _session(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final practice = context.watch<PracticeController>();
    final c = Theme.of(context).colorScheme;
    final from = _range.start.round();
    final to = _range.end.round();
    final ayahs = [for (var n = from; n <= to; n++) repo.ayah(n)];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Text(context.tr('tapToReveal'), style: Theme.of(context).textTheme.bodySmall)),
          TextButton(
            onPressed: () => setState(() => _started = false),
            child: Text(context.tr('memorization')),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: ayahs.length,
          itemBuilder: (context, i) {
            final a = ayahs[i];
            final hidden = _hiddenFor(a);
            final done = practice.memorized.contains(a.number);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    CircleAvatar(
                        radius: 16,
                        backgroundColor: c.primary.withValues(alpha: 0.12),
                        child: Text('${a.number}', style: TextStyle(color: c.primary))),
                    const SizedBox(width: 8),
                    if (done) Icon(Icons.check_circle_rounded, color: c.primary, size: 20),
                    if (done) Text(' ${context.tr('memorized')}'),
                  ]),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Wrap(spacing: 8, runSpacing: 6, children: [
                      for (var k = 0; k < a.words.length; k++)
                        hidden.contains(k)
                            ? InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(() => _revealed.add('${a.number}:$k')),
                                child: Container(
                                  width: (a.words[k].arabic.length * 11.0).clamp(44.0, 110.0),
                                  height: 48,
                                  decoration: BoxDecoration(
                                      color: c.primary.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              )
                            : Text(a.words[k].arabic,
                                style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 28, height: 1.9)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    TextButton.icon(
                      icon: const Icon(Icons.headphones_rounded),
                      label: Text(context.tr('listen')),
                      onPressed: () => context.read<AudioController>().playAyah(a.number),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.visibility_rounded),
                      label: Text(context.tr('revealAll')),
                      onPressed: () => setState(() {
                        for (var k = 0; k < a.words.length; k++) {
                          _revealed.add('${a.number}:$k');
                        }
                      }),
                    ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.check_rounded),
                        label: Text(context.tr('remembered'), textAlign: TextAlign.center),
                        onPressed: () {
                          practice.setMemorized(a.number, true);
                          context.read<ProgressController>().markAyahStudied(a.number);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close_rounded),
                        label: Text(context.tr('forgot'), textAlign: TextAlign.center),
                        onPressed: () {
                          practice.setMemorized(a.number, false);
                          context.read<ProgressController>().recordActivity();
                        },
                      ),
                    ),
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
