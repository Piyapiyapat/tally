import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/mood_provider.dart';
import '../services/db_service.dart';
import '../services/stats_service.dart';
import '../models/mood_entry.dart';
import 'habit_screen.dart';
import 'mood_calendar_screen.dart';
import '../widgets/bouncy_mood_icon.dart';
import '../widgets/mood_face_widget.dart';
import '../widgets/mood_stability_card.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/greeting.dart';
import '../utils/affirmation_pools.dart';
import '../utils/mood_style.dart';

enum _MoodCardMode { idle, selecting, saved }

class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _moodSeeded = false;
  _MoodCardMode _moodMode = _MoodCardMode.idle;
  int? _selectedMood;
  final _moodNoteController = TextEditingController();
  Set<String> _selectedMoodTags = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_moodSeeded) {
      final today = context.read<MoodProvider>().todayMood;
      if (today != null) {
        _selectedMood = today.mood;
        _moodNoteController.text = today.note ?? '';
        _selectedMoodTags = today.tags.toSet();
        _moodMode = _MoodCardMode.saved;
      }
      _moodSeeded = true;
    }
  }

  @override
  void dispose() {
    _moodNoteController.dispose();
    super.dispose();
  }

  String get _greeting =>
      buildGreeting(DateTime.now(), DbService.getDisplayNameRaw());

  String get _formattedDate {
    final now = DateTime.now();
    const months = [
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
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = days[now.weekday - 1];
    return '$dayName, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitProvider>();
    final mood = context.watch<MoodProvider>();
    final colors = context.colors;

    final totalHabits = habit.habits.length;
    final doneHabits = habit.habits
        .where((h) => habit.isHabitDoneToday(h.id))
        .length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (bold hero panel) ──────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: colors.heroGradient,
                borderRadius: BorderRadius.circular(kCardRadius),
                boxShadow: colors.heroShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: colors.onAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onAccent.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Calendar entry point (covers mood + habits) ──
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MoodCalendarScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: colors.onAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Calendar',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.onAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Mood card ─────────────────────────────────
            _buildMoodCard(context, mood),
            const SizedBox(height: 12),

            // ── This week's mood (Mon-Sun, today included) ──
            // Not const: it reads DbService.moodBox directly rather than
            // watching a provider, so it needs to actually rebuild (not get
            // skipped as an unchanged const subtree) whenever mood changes
            // elsewhere on this screen trigger a rebuild here.
            _MoodHistoryStrip(),
            const SizedBox(height: 12),
            // Not const, same reason as _MoodHistoryStrip above — it needs
            // to actually recompute from Hive on every rebuild, not get
            // frozen as an unchanged const subtree.
            MoodStabilityCard(range: StatsRange.week),
            const SizedBox(height: 12),

            // ── Habit card (always open, no collapse) ────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBadge(icon: Icons.repeat_outlined),
                      const SizedBox(width: 10),
                      Text(
                        'Habits',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.deep,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        totalHabits == 0
                            ? 'No habits yet'
                            : '$doneHabits/$totalHabits done',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 20, color: colors.accent),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => showHabitSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: habit.habits.isEmpty
                        ? Center(
                            child: Text(
                              'No habits yet',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textDim,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: habit.habits.length,
                            itemBuilder: (context, index) {
                              final h = habit.habits[index];
                              final isDone = habit.isHabitDoneToday(h.id);
                              return _MiniHabitTile(
                                habit: h,
                                isDone: isDone,
                                onToggle: () {
                                  context.read<HabitProvider>().toggleHabit(
                                    h.id,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HabitScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: colors.accent,
                        ),
                        label: Text(
                          'Extended view',
                          style: GoogleFonts.nunito(
                            color: colors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard(BuildContext context, MoodProvider mood) {
    // Guard against the (unlikely) case where local state says "saved" but
    // the provider has no entry for today — fall back to idle so the card
    // never gets stuck showing a save summary for a mood that isn't there.
    final effectiveMode =
        (_moodMode == _MoodCardMode.saved && !mood.hasMoodToday)
        ? _MoodCardMode.idle
        : _moodMode;
    final showNote = effectiveMode == _MoodCardMode.selecting;
    final colors = context.colors;

    void selectFace(int value) {
      setState(() {
        _selectedMood = value;
        _moodMode = _MoodCardMode.selecting;
      });
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge.fa(faIcon: moodIconFor(5)),
              const SizedBox(width: 10),
              Text(
                'Mood',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.deep,
                ),
              ),
              const Spacer(),
              Text(
                _selectedMood != null
                    ? moodLabelFor(_selectedMood!)
                    : 'Not logged today',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
              if (effectiveMode == _MoodCardMode.saved)
                IconButton(
                  icon: Icon(Icons.more_vert, size: 20, color: colors.accent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showMoodOptionsSheet(context),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (effectiveMode == _MoodCardMode.saved)
            _buildSavedMoodBody(context, mood)
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final value = i + 1;
                final isSelected = _selectedMood == value;
                return GestureDetector(
                  onTap: () => selectFace(value),
                  child: AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    child: MoodFaceWidget(
                      value: value,
                      isSelected: isSelected,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              margin: EdgeInsets.only(top: showNote ? 10 : 0),
              height: showNote ? 56 : 0,
              child: TextField(
                controller: _moodNoteController,
                maxLines: 1,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: colors.deep,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a note (Optional)',
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 13,
                    color: colors.textDim,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.sticky_note_2_outlined,
                    color: colors.accent,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: colors.surfaceFlat,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            if (showNote) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in kMoodTags)
                    FilterChip(
                      label: Text(tag),
                      selected: _selectedMoodTags.contains(tag),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _selectedMoodTags.add(tag);
                        } else {
                          _selectedMoodTags.remove(tag);
                        }
                      }),
                      selectedColor: colors.mint,
                      checkmarkColor: colors.onMint,
                      backgroundColor: colors.surfaceFlat,
                      labelStyle: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _selectedMoodTags.contains(tag)
                            ? colors.onMint
                            : colors.accent,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMood == null
                      ? null
                      : () {
                          final note = _moodNoteController.text.trim();
                          context.read<MoodProvider>().saveMood(
                            _selectedMood!,
                            note: note.isEmpty ? null : note,
                            tags: _selectedMoodTags.toList(),
                          );
                          setState(() => _moodMode = _MoodCardMode.saved);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    disabledBackgroundColor: colors.border,
                    foregroundColor: colors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    mood.hasMoodToday ? 'Update mood' : 'Save mood',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: colors.onAccent,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showMoodOptionsSheet(BuildContext context) {
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
                'Edit mood',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: colors.deep,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                setState(() => _moodMode = _MoodCardMode.selecting);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text(
                'Delete mood',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: colors.danger,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.read<MoodProvider>().deleteTodayMood();
                setState(() {
                  _selectedMood = null;
                  _moodNoteController.clear();
                  _selectedMoodTags = {};
                  _moodMode = _MoodCardMode.idle;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// A message reacting to this specific mood entry — stable across
  /// rebuilds (picked deterministically from the entry's id) rather than
  /// re-randomized every time the card redraws, so it doesn't flicker to a
  /// different phrase while you're just looking at it.
  String _moodMessageFor(MoodEntry entry) {
    final pool = kMoodAffirmationsByLevel[entry.mood];
    if (pool == null || pool.isEmpty) return '';
    final index = entry.id.hashCode.abs() % pool.length;
    return pool[index];
  }

  Widget _buildSavedMoodBody(BuildContext context, MoodProvider mood) {
    final colors = context.colors;
    final entry = mood.todayMood!;
    final note = entry.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.mintSoft,
              ),
              child: BouncyMoodIcon(
                moodKey: entry.id,
                child: FaIcon(
                  moodIconFor(entry.mood),
                  size: 20,
                  color: colors.accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                moodLabelFor(entry.mood),
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.deep,
                ),
              ),
            ),
          ],
        ),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            note,
            style: GoogleFonts.nunito(fontSize: 13, color: colors.accent),
          ),
        ],
        if (entry.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in entry.tags)
                Container(
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
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _moodMessageFor(entry),
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textDim,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                setState(() => _moodMode = _MoodCardMode.selecting),
            icon: Icon(Icons.edit, size: 16, color: colors.onAccent),
            label: Text(
              'Edit mood',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: colors.onAccent,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// A horizontal, read-only strip of the current calendar week (Monday
/// through Sunday, today included), each showing the day's logged mood
/// face (or a faint empty circle for no entry / a day that hasn't
/// happened yet) plus a weekday label. Today is outlined so it's easy to
/// spot. Reads directly from [DbService.moodBox].
class _MoodHistoryStrip extends StatelessWidget {
  const _MoodHistoryStrip();

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  MoodEntry? _entryForDay(DateTime day) {
    try {
      return DbService.moodBox.values.firstWhere(
        (m) =>
            m.createdAt.year == day.year &&
            m.createdAt.month == day.month &&
            m.createdAt.day == day.day,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday of the current calendar week, so the strip always reads
    // Mon..Sun rather than a rolling 7-day window with date numbers.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header row
        Text(
          "This week's mood",
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: 8),
        // mood strip
        SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < days.length; i++)
                _dayColumn(colors, days[i], isToday: days[i] == today),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayColumn(AppColors colors, DateTime day, {required bool isToday}) {
    final entry = _entryForDay(day);
    return SizedBox(
      width: 40,
      height: 68,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry != null ? colors.mintSoft : Colors.transparent,
              border: Border.all(
                color: isToday
                    ? colors.mint
                    : entry != null
                    ? Colors.transparent
                    : colors.border,
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: entry != null
                ? FaIcon(
                    moodIconFor(entry.mood),
                    size: 20,
                    color: colors.accent,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            _weekdayLabels[day.weekday - 1],
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
              color: isToday ? colors.deep : colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniHabitTile extends StatelessWidget {
  final dynamic habit;
  final bool isDone;
  final VoidCallback onToggle;

  const _MiniHabitTile({
    required this.habit,
    required this.isDone,
    required this.onToggle,
  });

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
                'Edit habit',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: colors.deep,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                showHabitSheet(context, existing: habit);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text(
                'Delete habit',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: colors.danger,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: colors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Delete habit?',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: colors.deep,
                      ),
                    ),
                    content: Text(
                      '"${habit.name}" and all its history will be deleted.',
                      style: GoogleFonts.nunito(color: colors.accent),
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
                        onPressed: () {
                          context.read<HabitProvider>().deleteHabit(habit);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Delete',
                          style: GoogleFonts.nunito(
                            color: colors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 4),
        decoration: BoxDecoration(
          color: isDone ? colors.mint : colors.surfaceFlat,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              habitIconFor(habit.iconName),
              size: 18,
              color: isDone ? colors.onMint : colors.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDone ? colors.onMint : colors.deep,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showOptions(context),
              child: Icon(
                Icons.more_vert,
                size: 18,
                color: isDone ? colors.onMint : colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
