import 'package:flutter/foundation.dart';
import '../../app/app_theme.dart';
import '../../data/user_data_store.dart';

/// Holds every user setting and saves it whenever something changes.
class SettingsController extends ChangeNotifier {
  final UserDataStore _store;

  AppThemeKind themeKind = AppThemeKind.light; // bright by default
  String uiLang = 'en';                        // 'en' or 'ur'
  Set<String> translationLangs = {'en'};      // shown in the reader
  String level = 'beginner';
  int dailyGoal = 10;                          // words per day
  bool onboardingDone = false;
  double arabicSize = 28;
  double translationSize = 16;
  double lineSpacing = 1.8;
  bool showTranslit = true;
  bool showWordMeanings = true;
  bool wordByWordView = false;                 // reader default view
  double audioSpeed = 1.0;                     // 0.75 .. 1.5
  int repeatCount = 1;                         // times each ayah plays; 0 = loop forever
  bool autoNext = true;                        // play next ayah automatically
  bool reminderEnabled = false;
  int reminderHour = 20;
  int reminderMinute = 0;

  SettingsController(this._store) {
    reload();
  }

  /// Reads everything from storage (also used after a Restore).
  void reload() {
    final j = _store.readJson('settings', <String, dynamic>{});
    final m = j is Map ? Map<String, dynamic>.from(j) : <String, dynamic>{};
    final t = m['theme'] as int?;
    themeKind = (t != null && t >= 0 && t < AppThemeKind.values.length)
        ? AppThemeKind.values[t]
        : AppThemeKind.light;
    uiLang = (m['uiLang'] as String?) ?? 'en';
    final langs = m['translationLangs'];
    translationLangs = (langs is List && langs.isNotEmpty)
        ? langs.map((e) => e.toString()).toSet()
        : {'en'};
    level = (m['level'] as String?) ?? 'beginner';
    dailyGoal = (m['dailyGoal'] as num?)?.toInt() ?? 10;
    onboardingDone = (m['onboardingDone'] as bool?) ?? false;
    arabicSize = (m['arabicSize'] as num?)?.toDouble() ?? 28;
    translationSize = (m['translationSize'] as num?)?.toDouble() ?? 16;
    lineSpacing = (m['lineSpacing'] as num?)?.toDouble() ?? 1.8;
    showTranslit = (m['showTranslit'] as bool?) ?? true;
    showWordMeanings = (m['showWordMeanings'] as bool?) ?? true;
    wordByWordView = (m['wordByWordView'] as bool?) ?? false;
    audioSpeed = (m['audioSpeed'] as num?)?.toDouble() ?? 1.0;
    repeatCount = (m['repeatCount'] as num?)?.toInt() ?? 1;
    autoNext = (m['autoNext'] as bool?) ?? true;
    reminderEnabled = (m['reminderEnabled'] as bool?) ?? false;
    reminderHour = (m['reminderHour'] as num?)?.toInt() ?? 20;
    reminderMinute = (m['reminderMinute'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  /// Change one or more values, then save and refresh the screens.
  void update(VoidCallback change) {
    change();
    _store.writeJson('settings', {
      'theme': themeKind.index,
      'uiLang': uiLang,
      'translationLangs': translationLangs.toList(),
      'level': level,
      'dailyGoal': dailyGoal,
      'onboardingDone': onboardingDone,
      'arabicSize': arabicSize,
      'translationSize': translationSize,
      'lineSpacing': lineSpacing,
      'showTranslit': showTranslit,
      'showWordMeanings': showWordMeanings,
      'wordByWordView': wordByWordView,
      'audioSpeed': audioSpeed,
      'repeatCount': repeatCount,
      'autoNext': autoNext,
      'reminderEnabled': reminderEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
    });
    notifyListeners();
  }
}
