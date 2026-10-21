import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/streak.dart';

void main() {
  final today = DateTime(2026, 10, 21, 15, 30); // time of day must not matter

  test('no activity = 0', () => expect(currentStreak({}, today), 0));

  test('3 days in a row ending today = 3', () {
    expect(currentStreak({'2026-10-21', '2026-10-20', '2026-10-19'}, today), 3);
  });

  test('today not done yet but yesterday was: streak still alive', () {
    expect(currentStreak({'2026-10-20', '2026-10-19'}, today), 2);
  });

  test('a missed day resets the streak', () {
    expect(currentStreak({'2026-10-19', '2026-10-18'}, today), 0);
  });

  test('a gap stops the count', () {
    expect(currentStreak({'2026-10-21', '2026-10-20', '2026-10-18'}, today), 2);
  });

  test('works across month and year ends', () {
    expect(currentStreak({'2027-01-01', '2026-12-31', '2026-12-30'},
        DateTime(2027, 1, 1)), 3);
  });
}
