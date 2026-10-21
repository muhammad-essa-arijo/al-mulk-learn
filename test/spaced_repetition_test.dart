import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/spaced_repetition.dart';

void main() {
  final today = DateTime(2026, 10, 21);

  test('new card rated Good goes to box 2, due tomorrow', () {
    final s = reviewCard(null, Rating.good, today);
    expect(s.box, 2);
    expect(s.due, '2026-10-22');
  });

  test('Again sends the card to box 1, due today', () {
    final s = reviewCard(const CardState(4, '2026-10-21'), Rating.again, today);
    expect(s.box, 1);
    expect(s.due, '2026-10-21');
  });

  test('Easy jumps two boxes and is capped at box 5', () {
    expect(reviewCard(const CardState(1, 'x'), Rating.easy, today).box, 3);
    final top = reviewCard(const CardState(4, 'x'), Rating.easy, today);
    expect(top.box, 5);
    expect(top.due, '2026-11-04'); // +14 days, across a month end
  });

  test('Hard keeps the box and waits at least one day', () {
    final s = reviewCard(const CardState(1, 'x'), Rating.hard, today);
    expect(s.box, 1);
    expect(s.due, '2026-10-22');
    expect(reviewCard(const CardState(3, 'x'), Rating.hard, today).due, '2026-10-24');
  });

  test('isDue: new cards and past/today dates are due', () {
    expect(isDue(null, today), true);
    expect(isDue(const CardState(2, '2026-10-21'), today), true);
    expect(isDue(const CardState(2, '2026-10-20'), today), true);
    expect(isDue(const CardState(2, '2026-10-22'), today), false);
  });

  test('weak word: wrong once, then 2 correct in a row = no longer weak', () {
    final w = WordStat();
    expect(w.isWeak, false);
    w.record(false);
    expect(w.isWeak, true);
    w.record(true);
    expect(w.isWeak, true);
    w.record(true);
    expect(w.isWeak, false);
    w.record(false);
    expect(w.isWeak, true);
  });
}
