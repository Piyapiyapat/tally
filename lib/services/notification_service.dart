import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps the single daily reminder that nudges the user to log their mood
/// and check their habits. One notification, one id — enabling it
/// (re-)schedules id [_reminderId]; disabling it cancels that id.
class NotificationService {
  static const int _reminderId = 1;
  static const _channelId = 'daily_reminder';
  static const _channelName = 'Daily reminder';
  static const _channelDescription =
      'Reminds you to log your mood and check your habits';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // We don't pull in a native "get device timezone name" plugin (it's
    // more trouble than it's worth on this toolchain — see the Kotlin
    // build failure this replaced). Instead, [_nextInstanceOf] computes the
    // target fire time using the device's local clock directly and wraps
    // it as a UTC-based TZDateTime, which `timezone`'s bundled UTC location
    // supports with zero native code.
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    _initialized = true;
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Requests the Android 13+ POST_NOTIFICATIONS runtime permission, plus
  /// (best-effort) permission to schedule exact alarms. Exact alarms are
  /// what make the reminder fire right at the set time instead of being
  /// silently deferred by Doze/battery optimization — without it, Android
  /// only promises the notification "eventually" arrives. Declining the
  /// exact-alarm prompt isn't fatal: [scheduleDailyReminder] falls back to
  /// inexact scheduling.
  static Future<bool> requestPermission() async {
    final androidPlugin = _android;
    if (androidPlugin == null) return true;
    final granted = await androidPlugin.requestNotificationsPermission();
    await androidPlugin.requestExactAlarmsPermission();
    return granted ?? true;
  }

  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    final canExact = await _android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      _reminderId,
      'How are you doing today?',
      "Take a moment to log your mood and check off today's habits.",
      _nextInstanceOf(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      // Android-only app; this param only affects iOS's zonedSchedule path.
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder() async {
    await _plugin.cancel(_reminderId);
  }

  static const _habitChannelId = 'habit_reminder';
  static const _habitChannelName = 'Habit reminders';
  static const _habitChannelDescription =
      'Reminds you about a specific habit at its own time';

  /// Deterministic per-habit notification id, offset away from
  /// [_reminderId] so it can never collide with the daily reminder.
  static int _habitReminderId(String habitId) =>
      2 + (habitId.hashCode & 0x7fffffff) % 1000000;

  static Future<void> scheduleHabitReminder(
    String habitId,
    String habitName,
    TimeOfDay time,
  ) async {
    final canExact = await _android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      _habitReminderId(habitId),
      'Time for "$habitName"',
      "Don't forget to check it off in Tally.",
      _nextInstanceOf(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _habitChannelId,
          _habitChannelName,
          channelDescription: _habitChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelHabitReminder(String habitId) async {
    await _plugin.cancel(_habitReminderId(habitId));
  }

  /// Builds the next occurrence of [time] in the device's local clock, then
  /// re-expresses that same instant as a UTC-based [tz.TZDateTime] (required
  /// by `zonedSchedule`). Every conversion here goes through Dart's
  /// built-in, OS-backed [DateTime] — no IANA zone name lookup needed.
  static tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled.toUtc(), tz.UTC);
  }
}
