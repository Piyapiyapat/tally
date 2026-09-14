import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/mood_entry.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/journal_entry.dart';
import '../theme/app_colors.dart';

/// Custom journal tags are unbounded storage-wise, but capped in the UI so
/// the tag picker (and the synced copy in Firestore) stays a manageable,
/// glanceable list rather than growing without limit.
const kMaxCustomJournalTags = 20;

class DbService {
  static const String _moodBox = 'mood_entries';
  static const String _habitBox = 'habits';
  static const String _habitLogBox = 'habit_logs';
  static const String _journalBox = 'journal_entries';
  static const String _settingsBox = 'settings';

  // ── Init ──────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitLogAdapter());
    Hive.registerAdapter(JournalEntryAdapter());

    await Hive.openBox<MoodEntry>(_moodBox);
    await Hive.openBox<Habit>(_habitBox);
    await Hive.openBox<HabitLog>(_habitLogBox);
    await Hive.openBox<JournalEntry>(_journalBox);
    await Hive.openBox<String>(_settingsBox);
  }

  // ── Getters ───────────────────────────────────────────
  static Box<MoodEntry> get moodBox => Hive.box<MoodEntry>(_moodBox);
  static Box<Habit> get habitBox => Hive.box<Habit>(_habitBox);
  static Box<HabitLog> get habitLogBox => Hive.box<HabitLog>(_habitLogBox);
  static Box<JournalEntry> get journalBox =>
      Hive.box<JournalEntry>(_journalBox);
  static Box<String> get settingsBox => Hive.box<String>(_settingsBox);

  // ── Settings / Profile ─────────────────────────────────
  static String getDisplayName() => settingsBox.get('displayName') ?? 'You';

  // Unlike [getDisplayName], doesn't fall back to 'You' — lets callers
  // (e.g. the home screen greeting) tell "no name set" apart from an
  // actual name, so they can use their own no-name phrasing instead of
  // literally saying "Good morning, You".
  static String? getDisplayNameRaw() => settingsBox.get('displayName');

  static Future<void> setDisplayName(String name) async =>
      await settingsBox.put('displayName', name);

  static ThemeMode getThemeMode() {
    switch (settingsBox.get('themeMode')) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        // No preference saved yet — light, not the device's setting, so a
        // fresh install always opens the same way regardless of whether
        // the phone happens to be in dark mode. Still fully changeable
        // from Settings afterwards.
        return ThemeMode.light;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async =>
      await settingsBox.put('themeMode', mode.name);

  // Whether this device has ever explicitly set these — as opposed to just
  // reading the applied default — so cloud sync can tell "never touched,
  // safe to adopt the cloud's value" apart from "deliberately set locally".
  static bool isThemeModeSet() => settingsBox.containsKey('themeMode');

  static AppPalette getAppPalette() {
    switch (settingsBox.get('appPalette')) {
      case 'pink':
        return AppPalette.pink;
      case 'blue':
        return AppPalette.blue;
      case 'lavender':
        return AppPalette.lavender;
      case 'sunset':
        return AppPalette.sunset;
      default:
        return AppPalette.forest;
    }
  }

  static Future<void> setAppPalette(AppPalette palette) async =>
      await settingsBox.put('appPalette', palette.name);

  static bool isAppPaletteSet() => settingsBox.containsKey('appPalette');

  // Whether the user has made it past the first-launch Guest/Sign-up
  // choice screen. Checked once at startup; never re-shown after this
  // is true.
  static bool getOnboardingComplete() =>
      settingsBox.get('onboardingComplete') == 'true';

  static Future<void> setOnboardingComplete(bool value) async =>
      await settingsBox.put('onboardingComplete', value.toString());

  static String? getProfilePicture() => settingsBox.get('profilePicture');

  static Future<void> setProfilePicture(String? value) async {
    if (value == null) {
      await settingsBox.delete('profilePicture');
    } else {
      await settingsBox.put('profilePicture', value);
    }
  }

  // ── Daily reminder ──────────────────────────────────────
  static const TimeOfDay defaultReminderTime = TimeOfDay(hour: 20, minute: 0);

  static bool getReminderEnabled() =>
      settingsBox.get('reminderEnabled') == 'true';

  static Future<void> setReminderEnabled(bool enabled) async =>
      await settingsBox.put('reminderEnabled', enabled.toString());

  static bool isReminderEnabledSet() =>
      settingsBox.containsKey('reminderEnabled');

  // ── App lock ────────────────────────────────────────────
  // The PIN itself lives in secure storage (see AppLockService); these are
  // just the on/off flags, no more sensitive than any other preference.
  static bool getAppLockEnabled() =>
      settingsBox.get('appLockEnabled') == 'true';

  static Future<void> setAppLockEnabled(bool enabled) async =>
      await settingsBox.put('appLockEnabled', enabled.toString());

  static bool getAppLockBiometricEnabled() =>
      settingsBox.get('appLockBiometric') == 'true';

  static Future<void> setAppLockBiometricEnabled(bool enabled) async =>
      await settingsBox.put('appLockBiometric', enabled.toString());

  static TimeOfDay getReminderTime() {
    final hour = int.tryParse(settingsBox.get('reminderHour') ?? '');
    final minute = int.tryParse(settingsBox.get('reminderMinute') ?? '');
    if (hour == null || minute == null) return defaultReminderTime;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> setReminderTime(TimeOfDay time) async {
    await settingsBox.put('reminderHour', time.hour.toString());
    await settingsBox.put('reminderMinute', time.minute.toString());
  }

  static bool isReminderTimeSet() => settingsBox.containsKey('reminderHour');

  // ── Mood ──────────────────────────────────────────────
  static Future<void> saveMood(MoodEntry entry) async =>
      await moodBox.put(entry.id, entry);

  static MoodEntry? getMoodForToday() => getMoodForDate(DateTime.now());

  static MoodEntry? getMoodForDate(DateTime date) {
    try {
      return moodBox.values.firstWhere(
        (m) =>
            m.createdAt.year == date.year &&
            m.createdAt.month == date.month &&
            m.createdAt.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Habit ─────────────────────────────────────────────
  static Future<void> addHabit(Habit habit) async =>
      await habitBox.put(habit.id, habit);

  static Future<void> updateHabit(Habit habit) async => await habit.save();

  static Future<void> deleteHabit(String id) async {
    await habitBox.delete(id);
    final logsToDelete = habitLogBox.values
        .where((l) => l.habitId == id)
        .map((l) => l.id)
        .toList();
    await habitLogBox.deleteAll(logsToDelete);
  }

  static List<Habit> getAllHabits() => habitBox.values.toList();

  // ── Habit Log ─────────────────────────────────────────
  static Future<(String id, bool added)> toggleHabitLog(String habitId) async {
    final today = DateTime.now();
    try {
      final existing = habitLogBox.values.firstWhere(
        (l) =>
            l.habitId == habitId &&
            l.date.year == today.year &&
            l.date.month == today.month &&
            l.date.day == today.day,
      );
      await habitLogBox.delete(existing.id);
      return (existing.id, false);
    } catch (_) {
      final log = HabitLog(
        id: '${habitId}_${today.toIso8601String()}',
        habitId: habitId,
        date: today,
      );
      await habitLogBox.put(log.id, log);
      return (log.id, true);
    }
  }

  static bool isHabitDoneToday(String habitId) {
    final today = DateTime.now();
    return habitLogBox.values.any(
      (l) =>
          l.habitId == habitId &&
          l.date.year == today.year &&
          l.date.month == today.month &&
          l.date.day == today.day,
    );
  }

  // ── Journal ───────────────────────────────────────────
  static Future<void> saveJournal(JournalEntry entry) async =>
      await journalBox.put(entry.id, entry);

  static Future<void> deleteJournal(String id) async =>
      await journalBox.delete(id);

  static List<JournalEntry> getAllJournals() {
    final entries = journalBox.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  // ── Custom journal tags (user-added, on top of the built-in set) ─
  static List<String> getCustomJournalTags() {
    final raw = settingsBox.get('customJournalTags');
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  static Future<void> setCustomJournalTags(List<String> tags) async =>
      await settingsBox.put('customJournalTags', jsonEncode(tags));

  // ── Clear local data (keeps settingsBox / displayName) ─
  static Future<void> clearAllUserData() async {
    await moodBox.clear();
    await habitBox.clear();
    await habitLogBox.clear();
    await journalBox.clear();
  }
}
