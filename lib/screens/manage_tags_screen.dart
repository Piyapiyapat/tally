import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import 'journal_screen.dart' show kJournalTags;

/// Lets the user add/remove their own journal tags on top of the built-in
/// set. Removing a custom tag only takes it out of future pickers — entries
/// that already have it keep it.
class ManageTagsScreen extends StatefulWidget {
  const ManageTagsScreen({super.key});

  @override
  State<ManageTagsScreen> createState() => _ManageTagsScreenState();
}

class _ManageTagsScreenState extends State<ManageTagsScreen> {
  final _controller = TextEditingController();
  late List<String> _customTags;

  @override
  void initState() {
    super.initState();
    _customTags = DbService.getCustomJournalTags();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addTag() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final exists = [...kJournalTags, ..._customTags]
        .any((t) => t.toLowerCase() == name.toLowerCase());
    if (exists) {
      _controller.clear();
      return;
    }
    if (_customTags.length >= kMaxCustomJournalTags) {
      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You've reached the $kMaxCustomJournalTags custom tag limit — "
            'remove one to add another.',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              color: colors.onAccent,
            ),
          ),
          backgroundColor: colors.deep,
        ),
      );
      return;
    }
    _controller.clear();
    setState(() => _customTags = [..._customTags, name]);
    await DbService.setCustomJournalTags(_customTags);
    unawaited(SyncService.pushCustomTags(_customTags));
  }

  Future<void> _removeTag(String tag) async {
    setState(() => _customTags = _customTags.where((t) => t != tag).toList());
    await DbService.setCustomJournalTags(_customTags);
    unawaited(SyncService.pushCustomTags(_customTags));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.deep, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage tags',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Add a tag',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.deep,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.nunito(
                      color: colors.deep,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'New tag name',
                      hintStyle: GoogleFonts.nunito(
                        color: colors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: colors.surfaceFlat,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTag,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Your custom tags',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.deep,
              ),
            ),
            const SizedBox(height: 12),
            if (_customTags.isEmpty)
              Text(
                'No custom tags yet — add one above.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.accent,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _customTags)
                    Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor: colors.surfaceFlat,
                      labelStyle: GoogleFonts.nunito(
                        fontWeight: FontWeight.w600,
                        color: colors.deep,
                      ),
                      deleteIconColor: colors.danger,
                      side: BorderSide.none,
                    ),
                ],
              ),
            const SizedBox(height: 24),
            Text(
              'Built-in tags',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.deep,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "These are always available and can't be removed.",
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in kJournalTags)
                  Chip(
                    label: Text(tag),
                    backgroundColor: colors.surfaceFlat,
                    labelStyle: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                    side: BorderSide.none,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
