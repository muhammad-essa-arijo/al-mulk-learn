import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../settings/settings_controller.dart';
import 'audio_controller.dart';

/// Sticky player at the bottom of every screen while an ayah is loaded.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioController>();
    final s = context.watch<SettingsController>();
    final n = audio.currentAyah;
    if (n == null) return const SizedBox.shrink();
    final c = Theme.of(context).colorScheme;

    // Small tappable chip. Tapping it goes to the NEXT value in a list
    // (speed: 0.75 -> 1 -> 1.25 -> 1.5 -> back to 0.75).
    // We do NOT use a pop-up menu here: this player lives above the app's
    // Navigator (see main.dart), and pop-up menus / tooltips need one.
    Widget cycleChip(String text, IconData icon, String label, VoidCallback onTap) =>
        Semantics(
          button: true,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  border: Border.all(color: c.primary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 16, color: c.primary),
                const SizedBox(width: 4),
                Text(text),
              ]),
            ),
          ),
        );

    // Allowed values for the two chips.
    const speeds = [0.75, 1.0, 1.25, 1.5];
    const repeats = [1, 2, 3, 5, 10, 0]; // 0 = loop forever
    final nextSpeed = speeds[(speeds.indexOf(s.audioSpeed) + 1) % speeds.length];
    final nextRepeat = repeats[(repeats.indexOf(s.repeatCount) + 1) % repeats.length];

    return Material(
      color: c.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Progress bar of the current ayah
          StreamBuilder<Duration?>(
            stream: audio.durationStream,
            builder: (context, durSnap) => StreamBuilder<Duration>(
              stream: audio.positionStream,
              builder: (context, posSnap) {
                final total = durSnap.data?.inMilliseconds ?? 0;
                final pos = posSnap.data?.inMilliseconds ?? 0;
                return LinearProgressIndicator(
                    value: total == 0 ? 0 : (pos / total).clamp(0.0, 1.0),
                    minHeight: 3);
              },
            ),
          ),
          // Row 1: title + close button
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
            child: Row(children: [
              Expanded(
                child: Text(
                  audio.hasError
                      ? context.tr('audioError')
                      : '${context.tr('ayah')} $n',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Semantics(
                label: context.tr('stop'),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: audio.stop,
                ),
              ),
            ]),
          ),
          // Row 2: controls
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Semantics(
                label: context.tr('prevAyah'),
                child: IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: n > 1 ? audio.previous : null,
                ),
              ),
              Semantics(
                label: context.tr(audio.playing ? 'pause' : 'play'),
                child: IconButton.filled(
                  icon: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  onPressed: audio.togglePlayPause,
                ),
              ),
              Semantics(
                label: context.tr('nextAyah'),
                child: IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: n < audio.repo.ayahs.length ? audio.next : null,
                ),
              ),
              // Tap to change speed.
              cycleChip('${s.audioSpeed}×', Icons.speed_rounded,
                  context.tr('speed'), () => audio.setSpeed(nextSpeed)),
              // Tap to change how many times each ayah repeats.
              cycleChip(s.repeatCount == 0 ? '∞' : '×${s.repeatCount}',
                  Icons.repeat_rounded, context.tr('repeat'),
                  () => audio.setRepeat(nextRepeat)),
            ]),
          ),
        ]),
      ),
    );
  }
}
