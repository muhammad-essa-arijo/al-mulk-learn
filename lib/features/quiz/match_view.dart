import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/quiz_generator.dart';

/// "Match the word": tap an Arabic word, then tap its meaning.
/// Calls [onDone] once all pairs are matched, with how many wrong taps
/// there were and which words were involved in mistakes.
class MatchView extends StatefulWidget {
  final List<MatchPair> pairs;
  final void Function(int mistakes, Set<String> wrongKeys) onDone;
  const MatchView({super.key, required this.pairs, required this.onDone});
  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  late final List<int> _rightOrder; // shuffled order of the meanings
  int? _selectedLeft;
  int? _flashRight;                 // right tile that was just wrong
  final Set<int> _matched = {};
  final Set<String> _wrong = {};
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _rightOrder = List.generate(widget.pairs.length, (i) => i)..shuffle(Random());
  }

  void _tapRight(int r) {
    final left = _selectedLeft;
    final pairIndex = _rightOrder[r];
    if (left == null || _matched.contains(pairIndex)) return;
    if (pairIndex == left) {
      setState(() {
        _matched.add(left);
        _selectedLeft = null;
      });
      if (_matched.length == widget.pairs.length) {
        widget.onDone(_mistakes, _wrong);
      }
    } else {
      setState(() {
        _mistakes++;
        _wrong.add(widget.pairs[left].key);
        _flashRight = r;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _flashRight = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    const green = Color(0xFF2E8B57);
    const red = Color(0xFFD9534F);

    Widget tile({required Widget child, required Color? color, required VoidCallback? onTap, bool done = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: color ?? c.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (done) const Icon(Icons.check_rounded, size: 18, color: green),
                  Flexible(child: child),
                ]),
              ),
            ),
          ),
        );

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(children: [
          for (var i = 0; i < widget.pairs.length; i++)
            tile(
              done: _matched.contains(i),
              color: _matched.contains(i)
                  ? green.withValues(alpha: 0.2)
                  : _selectedLeft == i
                      ? c.primary.withValues(alpha: 0.25)
                      : null,
              onTap: _matched.contains(i) ? null : () => setState(() => _selectedLeft = i),
              child: Text(widget.pairs[i].arabic,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, height: 1.8)),
            ),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(children: [
          for (var r = 0; r < _rightOrder.length; r++)
            tile(
              done: _matched.contains(_rightOrder[r]),
              color: _matched.contains(_rightOrder[r])
                  ? green.withValues(alpha: 0.2)
                  : _flashRight == r
                      ? red.withValues(alpha: 0.3)
                      : null,
              onTap: () => _tapRight(r),
              child: Text(widget.pairs[_rightOrder[r]].meaning, textAlign: TextAlign.center),
            ),
        ]),
      ),
    ]);
  }
}
