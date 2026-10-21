// Pure functions (no Flutter) so they are easy to unit-test and explain.

/// Turns a date into a text key like "2026-10-21".
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Current streak = number of days in a row the user was active.
/// Rules:
///  - If today is active, count back from today.
///  - If today is NOT active yet but yesterday was, the streak is still alive
///    (the user has until midnight), so count back from yesterday.
///  - Otherwise the streak is 0 (a day was missed).
int currentStreak(Set<String> activeDays, DateTime today) {
  // Use only the date part so time of day never matters.
  var day = DateTime(today.year, today.month, today.day);
  if (!activeDays.contains(dayKey(day))) {
    day = DateTime(day.year, day.month, day.day - 1);
    if (!activeDays.contains(dayKey(day))) return 0;
  }
  var count = 0;
  while (activeDays.contains(dayKey(day))) {
    count++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return count;
}
