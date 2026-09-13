import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

class HabitProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<Habit> _habits = [];

  List<Habit> get habits => _habits;

  void loadHabits() {
    _habits = DbService.getAllHabits();
    notifyListeners();
  }

  Future<void> _syncReminder(Habit habit) async {
    if (habit.reminderHour != null && habit.reminderMinute != null) {
      await NotificationService.scheduleHabitReminder(
        habit.id,
        habit.name,
        TimeOfDay(hour: habit.reminderHour!, minute: habit.reminderMinute!),
      );
    } else {
      await NotificationService.cancelHabitReminder(habit.id);
    }
  }

  Future<void> addHabit(
    String name,
    String iconName, {
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      iconName: iconName,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    await DbService.addHabit(habit);
    await _syncReminder(habit);
    loadHabits();
    unawaited(SyncService.pushHabit(habit));
  }

  Future<void> updateHabit(
    Habit habit,
    String name,
    String iconName, {
    int? reminderHour,
    int? reminderMinute,
  }) async {
    habit.name = name;
    habit.iconName = iconName;
    habit.reminderHour = reminderHour;
    habit.reminderMinute = reminderMinute;
    await DbService.updateHabit(habit);
    await _syncReminder(habit);
    loadHabits();
    unawaited(SyncService.pushHabit(habit));
  }

  Future<void> deleteHabit(Habit habit) async {
    await DbService.deleteHabit(habit.id);
    await NotificationService.cancelHabitReminder(habit.id);
    loadHabits();
    unawaited(SyncService.deleteHabitRemote(habit.id));
  }

  Future<void> toggleHabit(String habitId) async {
    final (logId, added) = await DbService.toggleHabitLog(habitId);
    notifyListeners();
    if (added) {
      final log = DbService.habitLogBox.get(logId);
      if (log != null) unawaited(SyncService.pushHabitLog(log));
    } else {
      unawaited(SyncService.deleteHabitLogRemote(logId));
    }
  }

  bool isHabitDoneToday(String habitId) {
    return DbService.isHabitDoneToday(habitId);
  }
}
