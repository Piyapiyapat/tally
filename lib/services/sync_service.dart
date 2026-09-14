import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../theme/app_colors.dart';
import 'db_service.dart';

class SyncService {
  static String? _uid;
  static bool get isEnabled => _uid != null;

  static void setUser(String? uid) {
    _uid = uid;
  }

  static CollectionReference<Map<String, dynamic>> _col(String name) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection(name);
  }

  // ── Model <-> Map ───────────────────────────────────────
  static Map<String, dynamic> _habitToMap(Habit h) => {
    'id': h.id,
    'name': h.name,
    'createdAt': Timestamp.fromDate(h.createdAt),
    'iconName': h.iconName,
    'reminderHour': h.reminderHour,
    'reminderMinute': h.reminderMinute,
  };

  static Habit _habitFromMap(Map<String, dynamic> m) => Habit(
    id: m['id'] as String,
    name: m['name'] as String,
    createdAt: (m['createdAt'] as Timestamp).toDate(),
    iconName: m['iconName'] as String? ?? 'category',
    reminderHour: (m['reminderHour'] as num?)?.toInt(),
    reminderMinute: (m['reminderMinute'] as num?)?.toInt(),
  );

  static Map<String, dynamic> _habitLogToMap(HabitLog l) => {
    'id': l.id,
    'habitId': l.habitId,
    'date': Timestamp.fromDate(l.date),
  };

  static HabitLog _habitLogFromMap(Map<String, dynamic> m) => HabitLog(
    id: m['id'] as String,
    habitId: m['habitId'] as String,
    date: (m['date'] as Timestamp).toDate(),
  );

  static Map<String, dynamic> _moodToMap(MoodEntry e) => {
    'id': e.id,
    'mood': e.mood,
    'createdAt': Timestamp.fromDate(e.createdAt),
    'updatedAt': Timestamp.fromDate(e.updatedAt),
    'note': e.note,
    'tags': e.tags,
  };

  static MoodEntry _moodFromMap(Map<String, dynamic> m) => MoodEntry(
    id: m['id'] as String,
    mood: (m['mood'] as num).toInt(),
    createdAt: (m['createdAt'] as Timestamp).toDate(),
    updatedAt: (m['updatedAt'] as Timestamp).toDate(),
    note: m['note'] as String?,
    tags: (m['tags'] as List?)?.cast<String>() ?? [],
  );

  static Map<String, dynamic> _journalToMap(JournalEntry e) => {
    'id': e.id,
    'title': e.title,
    'content': e.content,
    'createdAt': Timestamp.fromDate(e.createdAt),
    'updatedAt': Timestamp.fromDate(e.updatedAt),
    'tags': e.tags,
  };

  static JournalEntry _journalFromMap(Map<String, dynamic> m) => JournalEntry(
    id: m['id'] as String,
    title: m['title'] as String?,
    content: m['content'] as String,
    createdAt: (m['createdAt'] as Timestamp).toDate(),
    updatedAt: (m['updatedAt'] as Timestamp).toDate(),
    tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  // ── Push single doc (เรียกจาก provider หลังเขียน local) ──
  static Future<void> pushHabit(Habit h) async {
    if (_uid == null) return;
    await _col('habits').doc(h.id).set(_habitToMap(h));
  }

  static Future<void> deleteHabitRemote(String id) async {
    if (_uid == null) return;
    await _col('habits').doc(id).delete();
    final logs = await _col('habitLogs').where('habitId', isEqualTo: id).get();
    for (final doc in logs.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> pushHabitLog(HabitLog l) async {
    if (_uid == null) return;
    await _col('habitLogs').doc(l.id).set(_habitLogToMap(l));
  }

  static Future<void> deleteHabitLogRemote(String id) async {
    if (_uid == null) return;
    await _col('habitLogs').doc(id).delete();
  }

  static Future<void> pushMood(MoodEntry e) async {
    if (_uid == null) return;
    await _col('moods').doc(e.id).set(_moodToMap(e));
  }

  static Future<void> deleteMoodRemote(String id) async {
    if (_uid == null) return;
    await _col('moods').doc(id).delete();
  }

  static Future<void> pushJournal(JournalEntry e) async {
    if (_uid == null) return;
    await _col('journalEntries').doc(e.id).set(_journalToMap(e));
  }

  static Future<void> deleteJournalRemote(String id) async {
    if (_uid == null) return;
    await _col('journalEntries').doc(id).delete();
  }

  // ── Merge ครั้งเดียวตอน login ────────────────────────────
  static Future<void> mergeAndSyncAll() async {
    if (_uid == null) return;
    await Future.wait([
      _mergeHabits(),
      _mergeHabitLogs(),
      _mergeMoods(),
      _mergeJournals(),
      _mergeProfile(),
      _mergeCustomTags(),
      _mergeSettings(),
    ]);
  }

  // ── Settings: appearance + reminders (app lock is deliberately excluded —
  // it's a device-level security setting, not something to carry over) ──
  // Lives as fields on the `users/{uid}` doc, same as profile/tags.
  static Future<void> pushSettings() async {
    if (_uid == null) return;
    final reminderTime = DbService.getReminderTime();
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      'themeMode': DbService.getThemeMode().name,
      'appPalette': DbService.getAppPalette().name,
      'reminderEnabled': DbService.getReminderEnabled(),
      'reminderHour': reminderTime.hour,
      'reminderMinute': reminderTime.minute,
    }, SetOptions(merge: true));
  }

  /// Restores appearance/reminder settings from the cloud for whichever of
  /// them this device has never explicitly set (fresh install, new device)
  /// — otherwise pushes whatever's already local, same merge direction as
  /// [_mergeProfile] and [_mergeCustomTags].
  static Future<void> _mergeSettings() async {
    if (_uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    final cloud = doc.data();

    if (!DbService.isThemeModeSet() && cloud?['themeMode'] is String) {
      try {
        await DbService.setThemeMode(
          ThemeMode.values.byName(cloud!['themeMode'] as String),
        );
      } catch (_) {}
    }
    if (!DbService.isAppPaletteSet() && cloud?['appPalette'] is String) {
      try {
        await DbService.setAppPalette(
          AppPalette.values.byName(cloud!['appPalette'] as String),
        );
      } catch (_) {}
    }
    if (!DbService.isReminderEnabledSet() &&
        cloud?['reminderEnabled'] is bool) {
      await DbService.setReminderEnabled(cloud!['reminderEnabled'] as bool);
    }
    if (!DbService.isReminderTimeSet() &&
        cloud?['reminderHour'] is num &&
        cloud?['reminderMinute'] is num) {
      await DbService.setReminderTime(
        TimeOfDay(
          hour: (cloud!['reminderHour'] as num).toInt(),
          minute: (cloud['reminderMinute'] as num).toInt(),
        ),
      );
    }

    await pushSettings();
  }

  // ── Custom journal tags ─────────────────────────────────
  // Lives as a field on the `users/{uid}` doc, same as the profile fields —
  // it's a single small list, not a keyed collection.
  static Future<void> pushCustomTags(List<String> tags) async {
    if (_uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      'customJournalTags': tags,
    }, SetOptions(merge: true));
  }

  /// Restores custom tags from the cloud when this device doesn't have any
  /// yet (fresh install, new device); otherwise pushes whatever is local.
  static Future<void> _mergeCustomTags() async {
    if (_uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    final cloudTags = doc.data()?['customJournalTags'];

    var localTags = DbService.getCustomJournalTags();
    if (localTags.isEmpty && cloudTags is List) {
      localTags = cloudTags.cast<String>();
      await DbService.setCustomJournalTags(localTags);
    }
    await pushCustomTags(localTags);
  }

  // ── Profile (display name + picture) ───────────────────
  // Lives as fields on the `users/{uid}` doc itself, not a subcollection —
  // there's only ever one. The picture is stored as a small base64
  // thumbnail (not the full-resolution local file) to stay well under
  // Firestore's 1MiB document limit.
  static const _profileThumbSize = 256;

  static Future<Uint8List> _compressForSync(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = img.copyResizeCropSquare(decoded, size: _profileThumbSize);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }

  static Future<void> pushProfile() async {
    if (_uid == null) return;
    final name = DbService.getDisplayNameRaw();
    final picture = DbService.getProfilePicture();

    final data = <String, dynamic>{
      'displayName': name,
      'profilePictureBase64': null,
      'profilePictureAsset': null,
    };
    if (picture != null && picture.startsWith('file:')) {
      final bytes = await File(picture.substring('file:'.length)).readAsBytes();
      final thumb = await _compressForSync(bytes);
      data['profilePictureBase64'] = base64Encode(thumb);
    } else if (picture != null && picture.startsWith('asset:')) {
      data['profilePictureAsset'] = picture.substring('asset:'.length);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .set(data, SetOptions(merge: true));
  }

  /// Restores the local display name/picture from the cloud when this
  /// device doesn't have one set yet (e.g. a fresh install, or signing in
  /// on a new device) — otherwise pushes whatever is already local, so the
  /// two stay in sync either direction.
  static Future<void> _mergeProfile() async {
    if (_uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    final cloud = doc.data();

    final localName = DbService.getDisplayNameRaw();
    if ((localName == null || localName.isEmpty) &&
        cloud?['displayName'] is String) {
      await DbService.setDisplayName(cloud!['displayName'] as String);
    }

    final localPicture = DbService.getProfilePicture();
    if (localPicture == null) {
      final base64Picture = cloud?['profilePictureBase64'];
      final assetPicture = cloud?['profilePictureAsset'];
      if (base64Picture is String) {
        final bytes = base64Decode(base64Picture);
        final docsDir = await getApplicationDocumentsDirectory();
        final path = '${docsDir.path}/profile_picture.jpg';
        await File(path).writeAsBytes(bytes);
        await DbService.setProfilePicture('file:$path');
      } else if (assetPicture is String) {
        await DbService.setProfilePicture('asset:$assetPicture');
      }
    }

    await pushProfile();
  }

  static Future<void> _mergeHabits() async {
    final localList = DbService.getAllHabits();
    final cloudSnap = await _col('habits').get();
    final cloudList = cloudSnap.docs
        .map((d) => _habitFromMap(d.data()))
        .toList();

    final merged = <String, Habit>{
      for (final h in cloudList) h.id: h,
      for (final h in localList) h.id: h, // local ชนะถ้า id ซ้ำ
    };

    for (final h in merged.values) {
      await DbService.habitBox.put(h.id, h);
    }
    final batch = FirebaseFirestore.instance.batch();
    for (final h in merged.values) {
      batch.set(_col('habits').doc(h.id), _habitToMap(h));
    }
    await batch.commit();
  }

  static Future<void> _mergeHabitLogs() async {
    final localList = DbService.habitLogBox.values.toList();
    final cloudSnap = await _col('habitLogs').get();
    final cloudList = cloudSnap.docs
        .map((d) => _habitLogFromMap(d.data()))
        .toList();

    final merged = <String, HabitLog>{
      for (final l in cloudList) l.id: l,
      for (final l in localList) l.id: l,
    };

    for (final l in merged.values) {
      await DbService.habitLogBox.put(l.id, l);
    }
    final batch = FirebaseFirestore.instance.batch();
    for (final l in merged.values) {
      batch.set(_col('habitLogs').doc(l.id), _habitLogToMap(l));
    }
    await batch.commit();
  }

  static Future<void> _mergeMoods() async {
    final localList = DbService.moodBox.values.toList();
    final cloudSnap = await _col('moods').get();
    final cloudList = cloudSnap.docs
        .map((d) => _moodFromMap(d.data()))
        .toList();

    final merged = <String, MoodEntry>{};
    for (final e in cloudList) {
      merged[e.id] = e;
    }
    for (final e in localList) {
      final existing = merged[e.id];
      if (existing == null || e.updatedAt.isAfter(existing.updatedAt)) {
        merged[e.id] = e;
      }
    }

    for (final e in merged.values) {
      await DbService.moodBox.put(e.id, e);
    }
    final batch = FirebaseFirestore.instance.batch();
    for (final e in merged.values) {
      batch.set(_col('moods').doc(e.id), _moodToMap(e));
    }
    await batch.commit();
  }

  static Future<void> _mergeJournals() async {
    final localList = DbService.journalBox.values.toList();
    final cloudSnap = await _col('journalEntries').get();
    final cloudList = cloudSnap.docs
        .map((d) => _journalFromMap(d.data()))
        .toList();

    final merged = <String, JournalEntry>{};
    for (final e in cloudList) {
      merged[e.id] = e;
    }
    for (final e in localList) {
      final existing = merged[e.id];
      if (existing == null || e.updatedAt.isAfter(existing.updatedAt)) {
        merged[e.id] = e;
      }
    }

    for (final e in merged.values) {
      await DbService.journalBox.put(e.id, e);
    }
    final batch = FirebaseFirestore.instance.batch();
    for (final e in merged.values) {
      batch.set(_col('journalEntries').doc(e.id), _journalToMap(e));
    }
    await batch.commit();
  }

  // ── ลบข้อมูลทั้งหมดใน Firestore (ก่อนลบบัญชี) ──────────
  static Future<void> deleteAllCloudData() async {
    if (_uid == null) return;
    const collections = ['habits', 'habitLogs', 'moods', 'journalEntries'];
    for (final name in collections) {
      final snap = await _col(name).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await FirebaseFirestore.instance.collection('users').doc(_uid).delete();
  }
}
