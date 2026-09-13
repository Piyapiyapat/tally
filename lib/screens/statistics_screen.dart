import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mood_entry.dart';
import '../services/db_service.dart';
import '../services/stats_service.dart';
import '../theme/app_colors.dart';
import '../utils/mood_style.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_badge.dart';
import '../widgets/mood_stability_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsRange _range = StatsRange.week;

  Widget _rangeButton(AppColors colors, StatsRange range, String label) {
    final isSelected = _range == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _range = range),
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

  // Show every label on week/year (7 or 12 points); thin them out on month
  // (30 points) so they don't overlap.
  bool _shouldShowLabel(int index, int total) {
    if (total <= 12) return true;
    return index % 5 == 0 || index == total - 1;
  }

  Widget _chartHeader(
    AppColors colors, {
    IconData? icon,
    FaIconData? faIcon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        icon != null ? IconBadge(icon: icon) : IconBadge.fa(faIcon: faIcon!),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.deep,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _habitMoodCorrelationCard(AppColors colors) {
    final correlations = StatsService.habitMoodCorrelations(_range);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            colors,
            icon: Icons.insights_outlined,
            title: 'Habit impact on mood',
            subtitle: 'Average mood on days you did vs. skipped a habit',
          ),
          const SizedBox(height: 16),
          if (correlations.isEmpty)
            _emptyState(
              colors,
              DbService.habitBox.values.isEmpty
                  ? 'Add a habit to see this'
                  : 'Log moods on enough done and skipped days to see this',
            )
          else
            for (final c in correlations)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.habitName,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.deep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Done ${c.avgWhenDone.toStringAsFixed(1)}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Skipped ${c.avgWhenNotDone.toStringAsFixed(1)}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textDim,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${c.avgWhenDone - c.avgWhenNotDone >= 0 ? '+' : ''}'
                          '${(c.avgWhenDone - c.avgWhenNotDone).toStringAsFixed(1)}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: c.avgWhenDone > c.avgWhenNotDone
                                ? colors.accent
                                : colors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _journalMoodCorrelationCard(AppColors colors) {
    final c = StatsService.journalMoodCorrelation(_range);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            colors,
            icon: Icons.menu_book_outlined,
            title: 'Journaling and mood',
            subtitle: "Average mood on days you journaled vs. didn't",
          ),
          const SizedBox(height: 16),
          if (c == null)
            _emptyState(
              colors,
              DbService.journalBox.values.isEmpty
                  ? 'Write a journal entry to see this'
                  : 'Log moods on enough journaled and non-journaled days '
                        'to see this',
            )
          else
            Row(
              children: [
                Text(
                  'Journaled ${c.avgWhenJournaled.toStringAsFixed(1)}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Skipped ${c.avgWhenNot.toStringAsFixed(1)}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textDim,
                  ),
                ),
                const Spacer(),
                Text(
                  '${c.avgWhenJournaled - c.avgWhenNot >= 0 ? '+' : ''}'
                  '${(c.avgWhenJournaled - c.avgWhenNot).toStringAsFixed(1)}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.avgWhenJournaled > c.avgWhenNot
                        ? colors.accent
                        : colors.textDim,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _shortDate(DateTime dt) {
    const months = [
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
    final thisYear = DateTime.now().year == dt.year;
    return thisYear
        ? '${months[dt.month - 1]} ${dt.day}'
        : '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _dayHighlight(
    AppColors colors, {
    required String label,
    required MoodEntry entry,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceFlat,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(moodIconFor(entry.mood), size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _shortDate(entry.createdAt),
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.deep,
            ),
          ),
          if (entry.note != null && entry.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bestWorstDayCard(AppColors colors) {
    final bw = StatsService.bestWorstDay(_range);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            colors,
            icon: Icons.star_border_rounded,
            title: 'Best & worst day',
            subtitle: 'Your highest- and lowest-mood day this period',
          ),
          const SizedBox(height: 16),
          if (bw == null)
            _emptyState(colors, 'No mood logged yet for this period')
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _dayHighlight(
                    colors,
                    label: 'Best day',
                    entry: bw.best,
                    accentColor: colors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dayHighlight(
                    colors,
                    label: 'Worst day',
                    entry: bw.worst,
                    accentColor: colors.accent,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _emptyState(AppColors colors, String message) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textDim,
          ),
        ),
      ),
    );
  }

  Widget _moodCountBreakdown(AppColors colors) {
    final counts = StatsService.moodCounts(_range);
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            colors,
            icon: Icons.pie_chart_outline,
            title: 'Mood count',
            subtitle: 'How often each mood was logged',
          ),
          const SizedBox(height: 16),
          if (total == 0)
            _emptyState(colors, 'No mood logged yet for this period')
          else
            for (final mood in [5, 4, 3, 2, 1])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    FaIcon(moodIconFor(mood), size: 20, color: colors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        moodLabelFor(mood),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.deep,
                        ),
                      ),
                    ),
                    Text(
                      '${counts[mood]}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _weeklyMoodCapsules(AppColors colors) {
    final points = StatsService.moodTrend(StatsRange.week);
    final hasData = points.any((p) => p.value != null);

    // Highlights every day that hit the week's top mood, not just the
    // first one found — with only 5 discrete levels, several days tying
    // for "best" is the common case, not the exception.
    double? bestValue;
    if (hasData) {
      for (final p in points) {
        if (p.value != null && (bestValue == null || p.value! > bestValue)) {
          bestValue = p.value;
        }
      }
    }

    const minHeight = 40.0;
    const maxHeight = 120.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            colors,
            faIcon: moodIconFor(5),
            title: 'Mood trend',
            subtitle: 'This week',
          ),
          const SizedBox(height: 20),
          if (!hasData)
            _emptyState(colors, 'No mood logged yet for this period')
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < points.length; i++)
                  _moodCapsule(
                    colors,
                    label: points[i].label,
                    value: points[i].value,
                    height: points[i].value == null
                        ? minHeight
                        : minHeight +
                              (points[i].value! - 1) /
                                  4 *
                                  (maxHeight - minHeight),
                    isBest: points[i].value != null &&
                        points[i].value == bestValue,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _moodCapsule(
    AppColors colors, {
    required String label,
    required double? value,
    required double height,
    required bool isBest,
  }) {
    final hasValue = value != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          child: isBest
              ? Text(
                  'Best',
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                  ),
                )
              : null,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: height,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: hasValue
                ? (isBest ? colors.accent : colors.mint)
                : colors.surfaceFlat,
            borderRadius: BorderRadius.circular(15),
          ),
          child: hasValue
              ? FaIcon(
                  moodIconFor(value.round()),
                  size: 16,
                  color: isBest ? colors.onAccent : colors.onMint,
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: isBest ? FontWeight.w700 : FontWeight.w600,
            color: isBest ? colors.deep : colors.textDim,
          ),
        ),
      ],
    );
  }

  Widget _moodChart(AppColors colors) {
    final points = StatsService.moodTrend(_range);
    final hasData = points.any((p) => p.value != null);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            colors,
            faIcon: moodIconFor(5),
            title: 'Mood trend',
            subtitle: 'Average mood logged (1-5)',
          ),
          const SizedBox(height: 16),
          if (!hasData)
            _emptyState(colors, 'No mood logged yet for this period')
          else
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 1,
                  maxY: 5,
                  gridData: FlGridData(
                    horizontalInterval: 1,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= points.length ||
                              !_shouldShowLabel(index, points.length)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              points[index].label,
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: colors.accent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colors.deep,
                      getTooltipItems: (spots) => spots
                          .map(
                            (s) => LineTooltipItem(
                              s.y.toStringAsFixed(1),
                              GoogleFonts.nunito(
                                color: colors.background,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          if (points[i].value != null)
                            FlSpot(i.toDouble(), points[i].value!),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: colors.accent,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: colors.accent,
                              strokeWidth: 2,
                              strokeColor: colors.surface,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.mintSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _barChart(
    AppColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<ChartPoint> points,
    required String Function(double) valueLabel,
    required double maxY,
    required bool hasData,
    required String emptyMessage,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(colors, icon: icon, title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          if (!hasData)
            _emptyState(colors, emptyMessage)
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          valueLabel(value),
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= points.length ||
                              !_shouldShowLabel(index, points.length)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              points[index].label,
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: colors.accent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colors.deep,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            valueLabel(rod.toY),
                            GoogleFonts.nunito(
                              color: colors.background,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: points[i].value ?? 0,
                            color: colors.accent,
                            width: points.length > 20 ? 4 : 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
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
    final colors = context.colors;
    final habitCount = DbService.habitBox.values.length;
    final journalCount = DbService.journalBox.values.length;

    final habitPoints = StatsService.habitCompletion(_range);
    final journalPoints = StatsService.journalActivity(_range);
    final weekdayMood = StatsService.moodByWeekday(_range);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Insights',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _rangeButton(colors, StatsRange.week, 'Week'),
                  const SizedBox(width: 10),
                  _rangeButton(colors, StatsRange.month, 'Month'),
                  const SizedBox(width: 10),
                  _rangeButton(colors, StatsRange.year, 'Year'),
                ],
              ),
              const SizedBox(height: 20),
              MoodStabilityCard(range: _range),
              const SizedBox(height: 16),
              _range == StatsRange.week
                  ? _weeklyMoodCapsules(colors)
                  : _moodChart(colors),
              const SizedBox(height: 16),
              _bestWorstDayCard(colors),
              const SizedBox(height: 16),
              _moodCountBreakdown(colors),
              const SizedBox(height: 16),
              _barChart(
                colors,
                icon: Icons.calendar_view_week_outlined,
                title: 'Mood by day of week',
                subtitle: weekdayMood.bestWeekday != null
                    ? 'Best: ${weekdayMood.bestWeekday} · '
                          'Worst: ${weekdayMood.worstWeekday}'
                    : 'Average mood logged per weekday',
                points: weekdayMood.points,
                valueLabel: (v) => v.toStringAsFixed(1),
                maxY: 5,
                hasData: weekdayMood.points.any((p) => p.value != null),
                emptyMessage: 'No mood logged yet for this period',
              ),
              const SizedBox(height: 16),
              _barChart(
                colors,
                icon: Icons.repeat_outlined,
                title: 'Habit completion',
                subtitle: 'Share of habits completed each day',
                points: habitPoints,
                valueLabel: (v) => '${v.toInt()}%',
                maxY: 100,
                hasData: habitCount > 0,
                emptyMessage: 'Add a habit to see completion trends',
              ),
              const SizedBox(height: 16),
              _habitMoodCorrelationCard(colors),
              const SizedBox(height: 16),
              _journalMoodCorrelationCard(colors),
              const SizedBox(height: 16),
              _barChart(
                colors,
                icon: Icons.menu_book_outlined,
                title: 'Journal activity',
                subtitle: 'Entries written',
                points: journalPoints,
                valueLabel: (v) => v.toInt().toString(),
                maxY:
                    (journalPoints
                                .map((p) => p.value ?? 0)
                                .fold<double>(0, (a, b) => a > b ? a : b) +
                            1)
                        .ceilToDouble(),
                hasData: journalCount > 0,
                emptyMessage: 'Write a journal entry to see your activity',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
