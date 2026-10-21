import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/streak.dart';
import '../../core/strings.dart';
import '../../data/quran_repository.dart';
import '../common/practice_controller.dart';
import '../common/progress_controller.dart';
import '../quiz/practice_screen.dart';

/// Progress dashboard: numbers, quiz chart, activity heatmap, weak words.
/// Charts are drawn by hand (CustomPainter), so they work on Chrome too.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  String _time(BuildContext context, int seconds) {
    final m = seconds ~/ 60;
    if (m < 60) return '$m ${context.tr('minutes')}';
    return '${m ~/ 60}${context.tr('hours')} ${m % 60}${context.tr('minutes')}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final progress = context.watch<ProgressController>();
    final practice = context.watch<PracticeController>();
    final c = Theme.of(context).colorScheme;

    final totalWords = repo.uniqueWords.length;
    final history = practice.history;
    final average = history.isEmpty
        ? null
        : history.map((h) => h.total == 0 ? 0.0 : h.score / h.total).reduce((a, b) => a + b) /
            history.length;
    final last10 = history.length > 10 ? history.sublist(history.length - 10) : history;
    final weakWords = repo.uniqueWords.where((w) => practice.weakKeys.contains(w.groupKey)).toList();

    Widget bar(String label, int value, int total) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
              Text('$value / $total'),
            ]),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total == 0 ? 0 : value / total),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: v, minHeight: 10),
              ),
            ),
          ]),
        );

    Widget tile(IconData icon, String value, String label) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Icon(icon, color: c.secondary),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('progress'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          tile(Icons.local_fire_department_rounded, '${progress.streak}', context.tr('streak')),
          tile(Icons.timer_outlined, _time(context, progress.secondsSpent), context.tr('timeSpent')),
          tile(Icons.quiz_rounded, average == null ? '—' : '${(average * 100).round()}%', context.tr('quizAverage')),
        ]),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              bar(context.tr('ayahsStudied'), progress.studiedAyahs.length, repo.ayahs.length),
              bar(context.tr('wordsLearned'), progress.learnedWords.length, totalWords),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // Quiz history chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('quizHistory'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (last10.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text(context.tr('noQuizYet'))),
                )
              else
                SizedBox(
                  height: 150,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _QuizBars(
                      [for (final h in last10) h.total == 0 ? 0.0 : h.score / h.total],
                      bar: c.primary,
                      track: c.primary.withValues(alpha: 0.10),
                      text: c.onSurface,
                    ),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // Activity heatmap
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('activity'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _Heatmap(activeDays: progress.activeDays),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // Weak words
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('weakWords'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (weakWords.isEmpty)
                Text(context.tr('noWeak'))
              else ...[
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final w in weakWords.take(30))
                    Chip(
                      label: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(w.arabic, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20)),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ]),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.healing_rounded),
                  label: Text(context.tr('practiceWeak')),
                  onPressed: () => startQuiz(context, 'weak', context.tr('practiceWeak'),
                      focus: practice.weakKeys),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Simple bar chart: one bar per recent quiz, height = score percent.
class _QuizBars extends CustomPainter {
  final List<double> values; // 0..1
  final Color bar, track, text;
  _QuizBars(this.values, {required this.bar, required this.track, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 18.0;
    final chartH = size.height - labelH;
    final n = values.length;
    const gap = 8.0;
    final barW = ((size.width - gap * (n + 1)) / n).clamp(8.0, 40.0);
    final totalW = n * barW + (n + 1) * gap;
    final startX = (size.width - totalW) / 2 + gap;
    for (var i = 0; i < n; i++) {
      final x = startX + i * (barW + gap);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, labelH, barW, chartH), const Radius.circular(6)),
          Paint()..color = track);
      final h = chartH * values[i].clamp(0.0, 1.0);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, labelH + chartH - h, barW, h), const Radius.circular(6)),
          Paint()..color = bar);
      final tp = TextPainter(
        text: TextSpan(
            text: '${(values[i] * 100).round()}',
            style: TextStyle(color: text, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + (barW - tp.width) / 2, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _QuizBars old) => old.values != values;
}

/// 12 weeks x 7 days. The last square is today. Filled = active that day.
class _Heatmap extends StatelessWidget {
  final Set<String> activeDays;
  const _Heatmap({required this.activeDays});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final today = DateTime.now();
    const weeks = 12;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var col = 0; col < weeks; col++)
          Column(children: [
            for (var row = 0; row < 7; row++)
              Builder(builder: (context) {
                final daysAgo = (weeks * 7 - 1) - (col * 7 + row);
                final d = DateTime(today.year, today.month, today.day - daysAgo);
                final active = activeDays.contains(dayKey(d));
                return Tooltip(
                  message: dayKey(d),
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: active ? c.primary : c.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
          ]),
      ]),
    );
  }
}
