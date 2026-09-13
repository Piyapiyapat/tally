import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';

class JournalProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<JournalEntry> _entries = [];

  List<JournalEntry> get entries => _entries;

  void loadJournals() {
    _entries = DbService.getAllJournals();
    notifyListeners();
  }

  Future<void> addJournal({
    String? title,
    required String content,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final entry = JournalEntry(
      id: _uuid.v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );
    await DbService.saveJournal(entry);
    loadJournals();
    unawaited(SyncService.pushJournal(entry));
  }

  Future<void> updateJournal(
    JournalEntry entry, {
    String? title,
    required String content,
    List<String> tags = const [],
  }) async {
    entry.title = title;
    entry.content = content;
    entry.tags = tags;
    entry.updatedAt = DateTime.now();
    await DbService.saveJournal(entry);
    loadJournals();
    unawaited(SyncService.pushJournal(entry));
  }

  Future<void> deleteJournal(JournalEntry entry) async {
    await DbService.deleteJournal(entry.id);
    loadJournals();
    unawaited(SyncService.deleteJournalRemote(entry.id));
  }

  /// Re-inserts an entry that was just deleted — backs the Journal screen's
  /// "Undo" snackbar. Re-uses the same id/fields so it lands back where it
  /// was rather than being treated as a new entry.
  Future<void> restoreJournal(JournalEntry entry) async {
    await DbService.saveJournal(entry);
    loadJournals();
    unawaited(SyncService.pushJournal(entry));
  }
}
