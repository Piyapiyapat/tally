import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../utils/mood_style.dart';
import '../widgets/icon_badge.dart';

const kJournalTags = [
  'Work',
  'Family',
  'Health',
  'Sleep',
  'Social',
  'Finance',
  'Gaming',
  'Stress',
  'Other',
];

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatDateTime(DateTime dt) =>
    '${_monthNames[dt.month - 1].substring(0, 3)} ${dt.day}, ${dt.year} · '
    '${_formatTime(dt)}';

/// Shown on an entry's card in place of a title when the user didn't give
/// it one — "Journal 19 July", not the raw timestamp, so an untitled
/// entry still reads like a diary rather than a database row.
String _defaultTitle(DateTime dt) =>
    'Journal ${dt.day} ${_monthNames[dt.month - 1]}';

bool _wasEdited(JournalEntry e) =>
    e.updatedAt.difference(e.createdAt).inMinutes > 1;

String _formatMonth(DateTime month) =>
    '${_monthNames[month.month - 1]} ${month.year}';

String _formatDay(DateTime day) =>
    '${_monthNames[day.month - 1].substring(0, 3)} ${day.day}';

enum _JournalSort { newest, oldest, edited }

enum _JournalView { list, calendar }

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _tagFilters = {};
  _JournalSort _sort = _JournalSort.newest;
  _JournalView _view = _JournalView.list;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final allEntries = journal.entries;
    final colors = context.colors;

    var entries = allEntries.where((e) {
      final q = _query.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          (e.title?.toLowerCase().contains(q) ?? false) ||
          e.content.toLowerCase().contains(q);
      final matchesTag =
          _tagFilters.isEmpty || e.tags.any(_tagFilters.contains);
      final matchesDay =
          _view == _JournalView.list ||
          _selectedDay == null ||
          _isSameDay(e.createdAt, _selectedDay!);
      return matchesQuery && matchesTag && matchesDay;
    }).toList();

    entries.sort((a, b) {
      switch (_sort) {
        case _JournalSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case _JournalSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case _JournalSort.edited:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    final usedTags = <String>{for (final e in allEntries) ...e.tags}.toList()
      ..sort();

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const JournalEditScreen()),
        ),
        backgroundColor: colors.accent,
        child: Icon(Icons.add, color: colors.onAccent),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                'Journal',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colors.deep,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _view == _JournalView.calendar
                          ? (_selectedDay == null
                                ? 'Tap a day to see its entries'
                                : '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'} on ${_formatDay(_selectedDay!)}')
                          : (_query.isEmpty && _tagFilters.isEmpty
                                ? '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}'
                                : '${entries.length} of ${allEntries.length} '
                                      '${allEntries.length == 1 ? 'entry' : 'entries'}'),
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.accent,
                      ),
                    ),
                  ),
                  if (_view == _JournalView.list)
                    PopupMenuButton<_JournalSort>(
                      initialValue: _sort,
                      onSelected: (v) => setState(() => _sort = v),
                      icon: Icon(
                        Icons.sort_rounded,
                        size: 20,
                        color: colors.accent,
                      ),
                      color: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      itemBuilder: (ctx) => [
                        _sortMenuItem(
                          colors,
                          _JournalSort.newest,
                          'Newest first',
                        ),
                        _sortMenuItem(
                          colors,
                          _JournalSort.oldest,
                          'Oldest first',
                        ),
                        _sortMenuItem(
                          colors,
                          _JournalSort.edited,
                          'Recently edited',
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.surfaceFlat,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ViewToggleButton(
                        label: 'List',
                        selected: _view == _JournalView.list,
                        onTap: () => setState(() => _view = _JournalView.list),
                      ),
                    ),
                    Expanded(
                      child: _ViewToggleButton(
                        label: 'Calendar',
                        selected: _view == _JournalView.calendar,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _view = _JournalView.calendar);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_view == _JournalView.list) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: colors.deep,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search entries',
                    hintStyle: GoogleFonts.nunito(
                      color: colors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colors.accent,
                      size: 20,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.close,
                              color: colors.accent,
                              size: 18,
                            ),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _query = '';
                            }),
                          ),
                    filled: true,
                    fillColor: colors.surfaceFlat,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
              if (usedTags.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (final tag in usedTags) ...[
                        FilterChip(
                          label: Text(tag),
                          selected: _tagFilters.contains(tag),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _tagFilters.add(tag);
                            } else {
                              _tagFilters.remove(tag);
                            }
                          }),
                          selectedColor: colors.mint,
                          checkmarkColor: colors.onMint,
                          backgroundColor: colors.surfaceFlat,
                          labelStyle: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _tagFilters.contains(tag)
                                ? colors.onMint
                                : colors.accent,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _view == _JournalView.calendar
                  ? _buildCalendarView(colors, allEntries, entries)
                  : (entries.isEmpty
                        ? Center(
                            child: Text(
                              allEntries.isEmpty
                                  ? 'No entries yet\nTap + to write'
                                  : 'No entries match',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                color: colors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final rows = _groupedRows(entries);
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: rows.length,
                                itemBuilder: (context, index) {
                                  final row = rows[index];
                                  if (row is DateTime) {
                                    return Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        4,
                                        index == 0 ? 0 : 20,
                                        4,
                                        8,
                                      ),
                                      child: Text(
                                        _formatMonthHeader(row),
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                          color: colors.deep,
                                        ),
                                      ),
                                    );
                                  }
                                  final entry = row as JournalEntry;
                                  return _JournalCard(
                                    entry: entry,
                                    journal: journal,
                                    onTagTap: (tag) => setState(() {
                                      _tagFilters
                                        ..clear()
                                        ..add(tag);
                                      _view = _JournalView.list;
                                    }),
                                  );
                                },
                              );
                            },
                          )),
            ),
          ],
        ),
      ),
    );
  }

  /// Interleaves month-header markers into [sorted] entries, Notes-app
  /// style. Only makes sense when entries are in date order — "Recently
  /// edited" isn't, so that sort stays a flat list.
  List<Object> _groupedRows(List<JournalEntry> sorted) {
    if (_sort == _JournalSort.edited) return sorted;
    final rows = <Object>[];
    DateTime? lastMonth;
    for (final e in sorted) {
      final month = DateTime(e.createdAt.year, e.createdAt.month);
      if (month != lastMonth) {
        rows.add(month);
        lastMonth = month;
      }
      rows.add(e);
    }
    return rows;
  }

  String _formatMonthHeader(DateTime month) => month.year == DateTime.now().year
      ? _monthNames[month.month - 1]
      : '${_monthNames[month.month - 1]} ${month.year}';

  PopupMenuItem<_JournalSort> _sortMenuItem(
    AppColors colors,
    _JournalSort value,
    String label,
  ) {
    final selected = _sort == value;
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? colors.deep : colors.accent,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCalendarView(
    AppColors colors,
    List<JournalEntry> allEntries,
    List<JournalEntry> dayEntries,
  ) {
    final entryDays = <DateTime>{
      for (final e in allEntries)
        DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day),
    };
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final daysInMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    ).day;
    final leadingBlanks =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday % 7;
    const dowLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: colors.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month - 1,
                        );
                      }),
                      child: Icon(
                        Icons.chevron_left,
                        color: colors.accent,
                        size: 22,
                      ),
                    ),
                    Text(
                      _formatMonth(_calendarMonth),
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.deep,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month + 1,
                        );
                      }),
                      child: Icon(
                        Icons.chevron_right,
                        color: colors.accent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final d in dowLabels)
                      Center(
                        child: Text(
                          d,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.accent.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    for (var i = 0; i < leadingBlanks; i++) const SizedBox(),
                    for (var day = 1; day <= daysInMonth; day++)
                      _buildCalendarCell(
                        colors,
                        day,
                        entryDays.contains(
                          DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month,
                            day,
                          ),
                        ),
                        DateTime(
                              _calendarMonth.year,
                              _calendarMonth.month,
                              day,
                            ) ==
                            todayKey,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedDay == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text(
              'Tap a day above to see its entries',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else if (dayEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text(
              'No entries on ${_formatDay(_selectedDay!)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final e in dayEntries)
                  _JournalCard(
                    entry: e,
                    journal: context.read<JournalProvider>(),
                    onTagTap: (tag) => setState(() {
                      _tagFilters
                        ..clear()
                        ..add(tag);
                      _view = _JournalView.list;
                    }),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarCell(
    AppColors colors,
    int day,
    bool hasEntry,
    bool isToday,
  ) {
    final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
    final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);
    return GestureDetector(
      onTap: () => setState(() => _selectedDay = isSelected ? null : date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accent
              : (hasEntry ? colors.mintSoft : null),
          border: isToday && !isSelected
              ? Border.all(color: colors.accent, width: 1.4)
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '$day',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? colors.onAccent : colors.deep,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? colors.onAccent : colors.accent,
          ),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final JournalProvider journal;
  final void Function(String tag)? onTagTap;

  const _JournalCard({
    required this.entry,
    required this.journal,
    this.onTagTap,
  });

  Future<void> _openEditor(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => JournalEditScreen(entry: entry)),
    );
  }

  void _showOptions(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colors.accent),
              title: Text(
                'Edit entry',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: colors.deep,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openEditor(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text(
                'Delete entry',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: colors.danger,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _deleteWithUndo(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteWithUndo(BuildContext context) {
    final colors = context.colors;
    final messenger = ScaffoldMessenger.of(context);
    journal.deleteJournal(entry);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: colors.deep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          content: Text(
            'Entry deleted',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              color: colors.onAccent,
            ),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: colors.mint,
            onPressed: () => journal.restoreJournal(entry),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => _openEditor(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: colors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBadge(icon: Icons.menu_book_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title ?? _defaultTitle(entry.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.deep,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        entry.title != null
                            ? _formatDateTime(entry.createdAt)
                            : _formatTime(entry.createdAt),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: colors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final mood = DbService.getMoodForDate(entry.createdAt);
                    if (mood == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, top: 1),
                      child: Tooltip(
                        message: 'Mood that day: ${moodLabelFor(mood.mood)}',
                        child: FaIcon(
                          moodIconFor(mood.mood),
                          size: 16,
                          color: moodColorFor(mood.mood),
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () => _showOptions(context),
                  child: Icon(Icons.more_vert, size: 20, color: colors.accent),
                ),
              ],
            ),
            if (_wasEdited(entry)) ...[
              const SizedBox(height: 2),
              Text(
                'Edited ${_formatDateTime(entry.updatedAt)}',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: colors.accent,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in entry.tags)
                    GestureDetector(
                      onTap: onTagTap == null ? null : () => onTagTap!(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceFlat,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              entry.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: colors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Journal Edit Screen ────────────────────────────────────
class JournalEditScreen extends StatefulWidget {
  final JournalEntry? entry;
  const JournalEditScreen({super.key, this.entry});

  @override
  State<JournalEditScreen> createState() => _JournalEditScreenState();
}

class _JournalEditScreenState extends State<JournalEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late Set<String> _selectedTags;
  late List<String> _customTags;
  bool get _isEditing => widget.entry != null;
  List<String> get _allTags => [...kJournalTags, ..._customTags];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
    _selectedTags = {...?widget.entry?.tags};
    _customTags = DbService.getCustomJournalTags();
  }

  Future<void> _addCustomTag() async {
    final colors = context.colors;
    final controller = TextEditingController();
    final input = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'New tag',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.nunito(
            color: colors.deep,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Tag name',
            hintStyle: GoogleFonts.nunito(color: colors.accent),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(
              'Add',
              style: GoogleFonts.nunito(
                color: colors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    final trimmed = input?.trim() ?? '';
    if (trimmed.isEmpty) return;

    String? match;
    for (final t in _allTags) {
      if (t.toLowerCase() == trimmed.toLowerCase()) {
        match = t;
        break;
      }
    }
    if (match == null) {
      if (_customTags.length >= kMaxCustomJournalTags) {
        if (!mounted) return;
        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You've reached the $kMaxCustomJournalTags custom tag limit — "
              'remove one in Manage tags to add another.',
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
      setState(() => _customTags = [..._customTags, trimmed]);
      await DbService.setCustomJournalTags(_customTags);
      unawaited(SyncService.pushCustomTags(_customTags));
      match = trimmed;
    }
    setState(() => _selectedTags.add(match!));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    final title = _titleController.text.trim();
    final journal = context.read<JournalProvider>();

    if (_isEditing) {
      await journal.updateJournal(
        widget.entry!,
        title: title.isEmpty ? null : title,
        content: content,
        tags: _selectedTags.toList(),
      );
    } else {
      await journal.addJournal(
        title: title.isEmpty ? null : title,
        content: content,
        tags: _selectedTags.toList(),
      );
    }

    if (context.mounted) Navigator.pop(context, true);
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
          _isEditing ? 'Edit entry' : 'New entry',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _save(context),
            child: Text(
              'Save',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: colors.accent,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.deep,
              ),
              decoration: InputDecoration(
                hintText: 'Title (optional)',
                hintStyle: GoogleFonts.nunito(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                border: InputBorder.none,
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 2),
              Text(
                _formatDateTime(widget.entry!.createdAt),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: colors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in _allTags)
                  FilterChip(
                    label: Text(tag),
                    selected: _selectedTags.contains(tag),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    }),
                    selectedColor: colors.mint,
                    checkmarkColor: colors.onMint,
                    backgroundColor: colors.surfaceFlat,
                    labelStyle: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedTags.contains(tag)
                          ? colors.onMint
                          : colors.accent,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ActionChip(
                  avatar: Icon(Icons.add, size: 16, color: colors.accent),
                  label: Text(
                    'New tag',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                  backgroundColor: colors.surfaceFlat,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: _addCustomTag,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: colors.border),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: colors.deep,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Write something...',
                  hintStyle: GoogleFonts.nunito(
                    color: colors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
