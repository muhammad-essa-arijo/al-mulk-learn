import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/quiz_generator.dart';
import '../../core/strings.dart';
import '../../data/quran_repository.dart';
import '../common/practice_controller.dart';
import '../memorization/memorization_screen.dart';
import '../settings/settings_controller.dart';
import 'quiz_screen.dart';

/// Builds a quiz for the saved level and opens it. Also used by the
/// Progress screen ("Practice weak words").
void startQuiz(BuildContext context, String id, String title,
    {List<QuizType>? types, Set<String>? focus, int count = 10}) {
  final repo = context.read<QuranRepository>();
  final level = context.read<SettingsController>().level;
  final qs = QuizGenerator(repo.ayahs)
      .generate(level: level, types: types, focusKeys: focus, count: count);
  if (qs.isEmpty) return;
  Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(quizId: id, title: title, questions: qs)));
}

/// The Practice hub: choose a quiz type, weak words, or memorization.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final practice = context.watch<PracticeController>();
    final weak = practice.weakKeys;

    Widget item(IconData icon, String title, String? subtitle, VoidCallback onTap) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            minVerticalPadding: 12,
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTap,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('practice'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(context.tr('level'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'beginner', label: Text(context.tr('beginner'))),
            ButtonSegment(value: 'intermediate', label: Text(context.tr('intermediate'))),
          ],
          selected: {s.level},
          onSelectionChanged: (v) => s.update(() => s.level = v.first),
        ),
        const SizedBox(height: 16),
        item(Icons.shuffle_rounded, context.tr('mixedQuiz'), '10',
            () => startQuiz(context, 'mixed', context.tr('mixedQuiz'))),
        item(Icons.translate_rounded, context.tr('quizMeaning'), null,
            () => startQuiz(context, 'meaning', context.tr('quizMeaning'), types: [QuizType.meaning])),
        item(Icons.swap_horiz_rounded, context.tr('quizReverse'), null,
            () => startQuiz(context, 'reverse', context.tr('quizReverse'), types: [QuizType.reverse])),
        item(Icons.edit_note_rounded, context.tr('quizFill'), null,
            () => startQuiz(context, 'fill', context.tr('quizFill'), types: [QuizType.fillBlank])),
        item(Icons.compare_arrows_rounded, context.tr('quizMatch'), '5',
            () => startQuiz(context, 'match', context.tr('quizMatch'), types: [QuizType.match], count: 5)),
        item(Icons.headphones_rounded, context.tr('quizListen'), null,
            () => startQuiz(context, 'listen', context.tr('quizListen'), types: [QuizType.listen])),
        item(Icons.account_tree_rounded, context.tr('quizRoot'), null,
            () => startQuiz(context, 'root', context.tr('quizRoot'), types: [QuizType.root])),
        const Divider(height: 28),
        item(Icons.healing_rounded, context.tr('practiceWeak'), '${weak.length}', () {
          if (weak.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('noWeak'))));
          } else {
            startQuiz(context, 'weak', context.tr('practiceWeak'), focus: weak);
          }
        }),
        item(Icons.psychology_rounded, context.tr('memorization'), null,
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemorizationScreen()))),
      ]),
    );
  }
}
