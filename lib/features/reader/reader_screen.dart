import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/quran_repository.dart';
import '../audio/audio_controller.dart';
import '../common/progress_controller.dart';
import '../settings/settings_controller.dart';
import 'ayah_card.dart';

/// The main reading screen: Bismillah header + all ayahs.
class ReaderScreen extends StatefulWidget {
  final int initialAyah; // which ayah to open at
  const ReaderScreen({super.key, this.initialAyah = 1});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _positions = ItemPositionsListener.create();
  final _scroll = ItemScrollController();
  late final ProgressController _progress;
  late final AudioController _audio;
  int? _lastScrolled;
  int _firstVisible = 1;

  @override
  void initState() {
    super.initState();
    // Keep a reference now, because we need it in dispose().
    _progress = context.read<ProgressController>();
    _audio = context.read<AudioController>();
    _audio.addListener(_followAudio);
    _firstVisible = widget.initialAyah;
    _positions.itemPositions.addListener(() {
      final shown = _positions.itemPositions.value
          .where((p) => p.itemTrailingEdge > 0)
          .map((p) => p.index)
          .toList()
        ..sort();
      if (shown.isNotEmpty) {
        // Index 0 is the Bismillah, so ayah n sits at index n.
        _firstVisible = shown.first == 0 ? 1 : shown.first;
      }
    });
  }

  /// While audio plays, scroll so the playing ayah stays on screen.
  void _followAudio() {
    final n = _audio.currentAyah;
    if (n == null) {
      _lastScrolled = null;
      return;
    }
    if (n == _lastScrolled || !_audio.playing) return;
    _lastScrolled = n;
    final visible = _positions.itemPositions.value.any(
        (p) => p.index == n && p.itemLeadingEdge >= 0 && p.itemTrailingEdge <= 1);
    if (!visible && _scroll.isAttached) {
      _scroll.scrollTo(
          index: n,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _audio.removeListener(_followAudio);
    // Remember where the user stopped (saved once, not on every scroll).
    _progress.setLastAyah(_firstVisible);
    super.dispose();
  }

  void _options() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Consumer<SettingsController>(
        builder: (context, s, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(context.tr('readingOptions'),
                style: Theme.of(context).textTheme.titleMedium),
            _slider(context.tr('arabicSize'), s.arabicSize, 20, 44,
                (v) => s.update(() => s.arabicSize = v)),
            _slider(context.tr('translationSize'), s.translationSize, 12, 26,
                (v) => s.update(() => s.translationSize = v)),
            _slider(context.tr('lineSpacing'), s.lineSpacing, 1.4, 2.4,
                (v) => s.update(() => s.lineSpacing = v)),
            SwitchListTile(
              title: Text(context.tr('showTranslit')),
              value: s.showTranslit,
              onChanged: (v) => s.update(() => s.showTranslit = v),
            ),
            SwitchListTile(
              title: Text(context.tr('showMeanings')),
              value: s.showWordMeanings,
              onChanged: (v) => s.update(() => s.showWordMeanings = v),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(children: [
      SizedBox(width: 120, child: Text(label)),
      Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final s = context.watch<SettingsController>();
    final c = Theme.of(context).colorScheme;
    final start = widget.initialAyah <= 1 ? 0 : widget.initialAyah;

    return Scaffold(
      appBar: AppBar(
        title: Text(repo.surahName),
        actions: [
          IconButton(
            tooltip: context.tr('playAll'),
            icon: const Icon(Icons.playlist_play_rounded),
            onPressed: () => _audio.playAyah(1, continuous: true),
          ),
          IconButton(
            tooltip: context.tr('wordByWord'),
            isSelected: s.wordByWordView,
            icon: const Icon(Icons.notes_rounded),
            selectedIcon: const Icon(Icons.view_week_rounded),
            onPressed: () => s.update(() => s.wordByWordView = !s.wordByWordView),
          ),
          IconButton(
            tooltip: context.tr('readingOptions'),
            icon: const Icon(Icons.text_fields_rounded),
            onPressed: _options,
          ),
        ],
      ),
      body: ScrollablePositionedList.builder(
        itemCount: repo.ayahs.length + 1,
        initialScrollIndex: start,
        itemPositionsListener: _positions,
        itemScrollController: _scroll,
        padding: const EdgeInsets.only(bottom: 24),
        itemBuilder: (context, i) {
          if (i == 0) {
            // Decorative Bismillah header
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.secondary, width: 1.5),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(bismillah,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: s.arabicSize + 4,
                        height: 2,
                        color: c.primary)),
              ),
            );
          }
          return AyahCard(ayah: repo.ayah(i));
        },
      ),
    );
  }
}
