// Simple Leitner-box spaced repetition. Easy to explain in a viva:
//   - A card lives in a box from 1 to 5.
//   - Higher box = you know it better = it comes back after more days.
//   - Box -> days until next review:  1:0  2:1  3:3  4:7  5:14
//   - "Again" sends the card back to box 1 (see it again today).
//   - "Hard" keeps the box but waits at least 1 day.
//   - "Good" moves up 1 box, "Easy" moves up 2 boxes.
import 'streak.dart';

enum Rating { again, hard, good, easy }

const List<int> boxDays = [0, 1, 3, 7, 14]; // index = box - 1
const int maxBox = 5;

class CardState {
  final int box;     // 1..5
  final String due;  // day key like "2026-10-21"
  const CardState(this.box, this.due);

  Map<String, dynamic> toJson() => {'b': box, 'd': due};
  factory CardState.fromJson(Map<String, dynamic> j) => CardState(
      ((j['b'] as num?)?.toInt() ?? 1).clamp(1, maxBox), (j['d'] ?? '') as String);
}

DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Returns the new state after the user rates a card. [old] is null for a
/// card that has never been reviewed.
CardState reviewCard(CardState? old, Rating rating, DateTime today) {
  final box = old?.box ?? 1;
  int newBox;
  int days;
  switch (rating) {
    case Rating.again:
      newBox = 1;
      days = 0;
      break;
    case Rating.hard:
      newBox = box;
      days = boxDays[box - 1] < 1 ? 1 : boxDays[box - 1];
      break;
    case Rating.good:
      newBox = (box + 1).clamp(1, maxBox);
      days = boxDays[newBox - 1];
      break;
    case Rating.easy:
      newBox = (box + 2).clamp(1, maxBox);
      days = boxDays[newBox - 1];
      break;
  }
  return CardState(newBox, dayKey(_addDays(today, days)));
}

/// A card is due if it is new, or its due day is today or earlier.
/// (Day keys like "2026-10-21" compare correctly as text.)
bool isDue(CardState? s, DateTime today) =>
    s == null || s.due.compareTo(dayKey(today)) <= 0;

/// Tracks mistakes for one word. A word is "weak" if the user got it wrong
/// and has not yet answered it correctly twice in a row afterwards.
class WordStat {
  int wrong;
  int streak; // correct answers in a row
  WordStat([this.wrong = 0, this.streak = 0]);

  void record(bool correct) {
    if (correct) {
      streak++;
    } else {
      wrong++;
      streak = 0;
    }
  }

  bool get isWeak => wrong > 0 && streak < 2;

  Map<String, dynamic> toJson() => {'w': wrong, 's': streak};
  factory WordStat.fromJson(Map<String, dynamic> j) =>
      WordStat((j['w'] as num?)?.toInt() ?? 0, (j['s'] as num?)?.toInt() ?? 0);
}
