import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../models/mood_entry.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../utils/mood_style.dart';
import 'habit_screen.dart' show habitIconFor;

enum _CalendarTab { mood, habits }

class MoodCalendarScreen extends StatefulWidget {
  final bool startOnHabits;
  const MoodCalendarScreen({super.key, this.startOnHabits = false});

  @override
  State<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends State<MoodCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  late _CalendarTab _tab = widget.startOnHabits
      ? _CalendarTab.habits
      : _CalendarTab.mood;

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

  List<Habit> get _habits => DbService.getAllHabits();

  Set<String> _doneHabitIdsForDay(DateTime day) {
    return DbService.habitLogBox.values
        .where(
          (l) =>
              l.date.year == day.year &&
              l.date.month == day.month &&
              l.date.day == day.day,
        )
        .map((l) => l.habitId)
        .toSet();
  }

  void _prevMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
  });

  Widget _tabButton(AppColors colors, _CalendarTab tab, String label) {
    final isSelected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? null : Border.all(color: colors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? colors.onAccent : colors.accent,
            ),
          ),
        ),
      ),
    );
  }

  // rows = habits, columns = days of the focused month — lets every habit
  // stay visible with its own row instead of cramming dots into a day cell.
  Widget _habitsMatrix(AppColors colors, int year, int month, int daysInMonth) {
    final habits = _habits;
    if (habits.isEmpty) return const SizedBox();

    const rowHeight = 40.0;
    const cellWidth = 30.0;
    const labelWidth = 108.0;
    final today = DateTime.now();
    final isCurrentMonth = today.year == year && today.month == month;

    // precompute once per build instead of rescanning the log box per cell
    final doneByDay = <int, Set<String>>{};
    for (int d = 1; d <= daysInMonth; d++) {
      doneByDay[d] = _doneHabitIdsForDay(DateTime(year, month, d));
    }

    Widget dayHeaderCell(int day) {
      final isToday = isCurrentMonth && today.day == day;
      return SizedBox(
        width: cellWidth,
        height: rowHeight,
        child: Center(
          child: Text(
            '$day',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? colors.deep : colors.textDim,
            ),
          ),
        ),
      );
    }

    Widget habitDayCell(Habit habit, int day) {
      final done = doneByDay[day]!.contains(habit.id);
      final isToday = isCurrentMonth && today.day == day;
      return GestureDetector(
        onTap: () => _showDayDetail(context, DateTime(year, month, day)),
        child: SizedBox(
          width: cellWidth,
          height: rowHeight,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? colors.mint : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: done
                      ? colors.mint
                      : isToday
                      ? colors.accent
                      : colors.border,
                  width: isToday && !done ? 1.4 : 1,
                ),
              ),
              child: done
                  ? Icon(Icons.check, size: 14, color: colors.onMint)
                  : null,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // fixed habit-name column (doesn't scroll horizontally)
          SizedBox(
            width: labelWidth,
            child: Column(
              children: [
                const SizedBox(height: rowHeight),
                for (final h in habits)
                  SizedBox(
                    height: rowHeight,
                    child: Row(
                      children: [
                        Icon(
                          habitIconFor(h.iconName),
                          size: 16,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            h.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.deep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // day columns, scrollable horizontally through the month
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (int d = 1; d <= daysInMonth; d++) dayHeaderCell(d),
                    ],
                  ),
                  for (final h in habits)
                    Row(
                      children: [
                        for (int d = 1; d <= daysInMonth; d++)
                          habitDayCell(h, d),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;

    const monthNames = [
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
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // first day of month and total days
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // offset: Monday=0, Tuesday=1 ... Sunday=6
    final startOffset = (firstDay.weekday - 1) % 7;

    // build grid cells
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

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
          'Calendar',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // mood / habits tab switch
              Row(
                children: [
                  _tabButton(colors, _CalendarTab.mood, 'Mood'),
                  const SizedBox(width: 10),
                  _tabButton(colors, _CalendarTab.habits, 'Habits'),
                ],
              ),
              const SizedBox(height: 12),

              // month navigator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: colors.accent),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    '${monthNames[month - 1]} $year',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.deep,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: colors.accent),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_tab == _CalendarTab.mood) ...[
                // day-of-week headers
                Row(
                  children: dayNames
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.accent,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: rows * 7,
                    itemBuilder: (context, index) {
                      final dayNum = index - startOffset + 1;
                      if (dayNum < 1 || dayNum > daysInMonth) {
                        return const SizedBox();
                      }

                      final date = DateTime(year, month, dayNum);
                      final entry = _entryForDay(date);
                      final isToday =
                          date.year == DateTime.now().year &&
                          date.month == DateTime.now().month &&
                          date.day == DateTime.now().day;

                      return GestureDetector(
                        onTap: () => _showDayDetail(context, date),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isToday
                                ? colors.border
                                : entry != null
                                ? colors.mintSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isToday
                                ? Border.all(color: colors.mint, width: 1.5)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNum',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: colors.deep,
                                ),
                              ),
                              if (entry != null) ...[
                                const SizedBox(height: 2),
                                FaIcon(
                                  moodIconFor(entry.mood),
                                  size: 18,
                                  color: colors.accent,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_habits.isEmpty) ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'Add a habit to see your progress here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textDim,
                      ),
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: _habitsMatrix(colors, year, month, daysInMonth),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetail(BuildContext context, DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final colors = context.colors;
    final entry = _entryForDay(date);
    final habits = _habits;
    final doneIds = _doneHabitIdsForDay(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${monthNames[date.month - 1]} ${date.day}, ${date.year}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                if (entry != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.mintSoft,
                        ),
                        child: FaIcon(
                          moodIconFor(entry.mood),
                          size: 28,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        moodLabelFor(entry.mood),
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.deep,
                        ),
                      ),
                    ],
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      entry.note!,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: colors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                ] else
                  Text(
                    'No mood logged',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textDim,
                    ),
                  ),
                if (habits.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Habits',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.deep,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final h in habits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            habitIconFor(h.iconName),
                            size: 18,
                            color: doneIds.contains(h.id)
                                ? colors.accent
                                : colors.textDim,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              h.name,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: doneIds.contains(h.id)
                                    ? colors.deep
                                    : colors.textDim,
                              ),
                            ),
                          ),
                          Icon(
                            doneIds.contains(h.id)
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: doneIds.contains(h.id)
                                ? colors.mint
                                : colors.border,
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
