import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/mood_entry.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';

class MoodProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  MoodEntry? _todayMood;

  MoodEntry? get todayMood => _todayMood;
  bool get hasMoodToday => _todayMood != null;

  void loadMood() {
    _todayMood = DbService.getMoodForToday();
    notifyListeners();
  }

  Future<void> saveMood(
    int mood, {
    String? note,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    late final MoodEntry entry;
    if (_todayMood != null) {
      _todayMood!.mood = mood;
      _todayMood!.updatedAt = now;
      _todayMood!.note = note;
      _todayMood!.tags = tags;
      entry = _todayMood!;
      await DbService.saveMood(entry);
    } else {
      entry = MoodEntry(
        id: _uuid.v4(),
        mood: mood,
        createdAt: now,
        updatedAt: now,
        note: note,
        tags: tags,
      );
      await DbService.saveMood(entry);
    }
    // Update local state/UI immediately — don't make the user wait on a
    // network round-trip just to see the mood they picked reflected.
    loadMood();
    unawaited(SyncService.pushMood(entry));
  }

  Future<void> deleteTodayMood() async {
    final entry = _todayMood;
    if (entry == null) return;
    await DbService.moodBox.delete(entry.id);
    _todayMood = null;
    notifyListeners();
    unawaited(SyncService.deleteMoodRemote(entry.id));
  }
}
