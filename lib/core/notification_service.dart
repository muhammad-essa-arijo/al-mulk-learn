import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily reminder using local notifications. Works on Android only.
/// Every method does nothing on the web (Chrome), so it never crashes there.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get supported => !kIsWeb;

  static Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      // Use the phone's own time zone so the reminder fires at local time.
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {/* falls back to UTC; reminder still works */}
    await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    _ready = true;
  }

  /// Asks permission (Android 13+) and schedules a notification every day.
  /// Returns false if it could not be set (web or permission refused).
  static Future<bool> enableDaily(TimeOfDay time,
      {required String title, required String body}) async {
    if (!supported) return false;
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? true;
    if (!granted) return false;

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      1,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_reminder', 'Daily reminder',
            channelDescription: 'A gentle daily reminder to study'),
      ),
      // "Inexact" needs no special exact-alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat every day
    );
    return true;
  }

  static Future<void> cancel() async {
    if (!supported) return;
    await _init();
    await _plugin.cancel(1);
  }
}
