import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/quiz_generator.dart';
import '../../core/strings.dart';
import '../../data/quran_repository.dart';
import '../audio/audio_controller.dart';
import '../common/practice_controller.dart';
import '../common/progress_controller.dart';
import 'match_view.dart';

class _Mistake {
  final QuizQuestion q;
  final String yourAnswer; // for match questions: empty, see wrongTaps
  final int wrongTaps;
  const _Mistake(this.q, this.yourAnswer, {this.wrongTaps = 0});
}

/// Plays one quiz: question by question, instant feedback, then a score
/// screen with a review of the mistakes.
class QuizScreen extends StatefulWidget {
  final String quizId; // saved in history, e.g. "mixed"
  final String title;
  final List<QuizQuestion> questions;
  const QuizScreen({super.key, required this.quizId, required this.title, required this.questions});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _i = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _lastCorrect = false;
  bool _finished = false;
  final List<_Mistake> _mistakes = [];
  final AudioPlayer _player = AudioPlayer(); // separate from the main player

  QuizQuestion get _q => widget.questions[_i];

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _promptKey(QuizType t) => const {
        QuizType.meaning: 'qMeaning',
        QuizType.reverse: 'qReverse',
        QuizType.fillBlank: 'qFill',
        QuizType.match: 'qMatch',
        QuizType.listen: 'qListen',
        QuizType.root: 'qRoot',
      }[t]!;

  /// Explanation in the app language (word meanings stay English: that is
  /// the only meaning data we have).
  String _explain(BuildContext context, QuizQuestion q) => q.explainKey.isEmpty
      ? q.explanation
      : context.trArgs(q.explainKey, q.explainArgs);

  Future<void> _playListen() async {
    final n = _q.audioAyah;
    if (n == null) return;
    final main = context.read<AudioController>();
    final asset = context.read<QuranRepository>().ayah(n).audioAsset;
    try {
      if (main.currentAyah != null) await main.stop(); // hide the mini-player
      await _player.setAsset(asset);
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } catch (_) {/* no sound is not a crash */}
  }

  void _answerChoice(int i) {
    if (_answered) return;
    final correct = i == _q.correctIndex;
    final practice = context.read<PracticeController>();
    for (final k in _q.wordKeys) {
      practice.recordAnswer(k, correct);
    }
    setState(() {
      _selected = i;
      _answered = true;
      _lastCorrect = correct;
      if (correct) {
        _score++;
      } else {
        _mistakes.add(_Mistake(_q, _q.options[i]));
      }
    });
  }

  void _answerMatch(int mistakes, Set<String> wrongKeys) {
    final practice = context.read<PracticeController>();
    for (final k in _q.wordKeys) {
      practice.recordAnswer(k, !wrongKeys.contains(k));
    }
    setState(() {
      _answered = true;
      _lastCorrect = mistakes == 0;
      if (mistakes == 0) {
        _score++;
      } else {
        _mistakes.add(_Mistake(_q, '', wrongTaps: mistakes));
      }
    });
  }

  void _next() {
    if (_i + 1 >= widget.questions.length) {
      context.read<PracticeController>().addQuizResult(widget.quizId, _score, widget.questions.length);
      context.read<ProgressController>().recordActivity();
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _i++;
      _selected = null;
      _answered = false;
    });
    if (_q.type == QuizType.listen) _playListen(); // tap on "Next" allows sound
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _finished ? _result(context) : _question(context),
    );
  }

  // ---------- one question ----------
  Widget _question(BuildContext context) {
    final q = _q;
    final c = Theme.of(context).colorScheme;
    final isLast = _i + 1 >= widget.questions.length;
    return Column(children: [
      LinearProgressIndicator(value: (_i + (_answered ? 1 : 0)) / widget.questions.length, minHeight: 4),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('${context.tr('question')} ${_i + 1} / ${widget.questions.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.secondary)),
          const SizedBox(height: 8),
          Text(context.tr(_promptKey(q.type)), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (q.arabic.isNotEmpty)
            Center(
              child: Text(q.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: q.type == QuizType.fillBlank ? 28 : 48,
                      height: 2)),
            ),
          if (q.type == QuizType.reverse)
            Center(
                child: Text('"${q.promptText}"',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: c.primary))),
          if (q.type == QuizType.meaning || q.type == QuizType.root)
            Center(child: Text(q.promptText, style: Theme.of(context).textTheme.bodyMedium)),
          if (q.type == QuizType.listen)
            Center(
              child: FilledButton.icon(
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(context.tr('playAudio')),
                onPressed: _playListen,
              ),
            ),
          const SizedBox(height: 12),
          if (q.type == QuizType.match)
            MatchView(key: ValueKey('match$_i'), pairs: q.pairs, onDone: _answerMatch)
          else
            for (var i = 0; i < q.options.length; i++) _option(context, q, i),
          if (_answered) ...[
            const SizedBox(height: 8),
            Card(
              color: (_lastCorrect ? const Color(0xFF2E8B57) : const Color(0xFFD9534F)).withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr(_lastCorrect ? 'correct' : 'wrong'),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(_explain(context, q)),
                ]),
              ),
            ),
          ],
        ]),
      ),
      if (_answered)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(context.tr(isLast ? 'finish' : 'next')),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _option(BuildContext context, QuizQuestion q, int i) {
    final c = Theme.of(context).colorScheme;
    const green = Color(0xFF2E8B57);
    const red = Color(0xFFD9534F);
    Color? bg;
    IconData? icon; // icons too, so colour is not the only signal
    if (_answered) {
      if (i == q.correctIndex) {
        bg = green.withValues(alpha: 0.2);
        icon = Icons.check_circle_rounded;
      } else if (i == _selected) {
        bg = red.withValues(alpha: 0.2);
        icon = Icons.cancel_rounded;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg ?? c.surface,
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _answered ? null : () => _answerChoice(i),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Expanded(
                child: Text(q.options[i],
                    textAlign: TextAlign.center,
                    textDirection: q.optionsAreArabic ? TextDirection.rtl : null,
                    style: q.optionsAreArabic
                        ? TextStyle(fontFamily: 'AmiriQuran', fontSize: q.type == QuizType.listen ? 22 : 28, height: 1.8)
                        : Theme.of(context).textTheme.bodyLarge),
              ),
              if (icon != null) Icon(icon, color: i == q.correctIndex ? green : red),
            ]),
          ),
        ),
      ),
    );
  }

  // ---------- score screen ----------
  Widget _result(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final total = widget.questions.length;
    final msgKey = _score == total ? 'perfect' : _score >= total * 0.7 ? 'greatJob' : 'keepPracticing';
    return ListView(padding: const EdgeInsets.all(16), children: [
      Icon(_score == total ? Icons.emoji_events_rounded : Icons.flag_rounded, size: 72, color: c.secondary),
      Center(child: Text(context.tr(msgKey), style: Theme.of(context).textTheme.headlineSmall)),
      const SizedBox(height: 4),
      Center(
        child: Text('${context.tr('score')}: $_score / $total',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.primary)),
      ),
      const SizedBox(height: 16),
      Text(context.tr('reviewMistakes'), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (_mistakes.isEmpty)
        Text(context.tr('noMistakes'))
      else
        for (final m in _mistakes)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr(_promptKey(m.q.type)), style: Theme.of(context).textTheme.labelLarge),
                if (m.q.arabic.isNotEmpty)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(m.q.arabic, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, height: 1.8)),
                  ),
                if (m.q.type == QuizType.reverse) Text('"${m.q.promptText}"'),
                const SizedBox(height: 4),
                Text('${context.tr('yourAnswer')}: ${m.q.type == QuizType.match ? context.trArgs('wrongTaps', {'n': '${m.wrongTaps}'}) : m.yourAnswer}'),
                Text('${context.tr('correctAnswer')}: ${m.q.correctText}'),
                const SizedBox(height: 4),
                Text(_explain(context, m.q), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
      const SizedBox(height: 16),
      FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('done'))),
    ]);
  }
}
