import '../models/mood_entry.dart';
import 'db_service.dart';

enum StatsRange { week, month, year }

/// One point on a chart: a label for the x-axis and a value, or `null` when
/// there's no data for that bucket (used to leave gaps in the mood line).
class ChartPoint {
  final String label;
  final double? value;
  const ChartPoint(this.label, this.value);
}

class _Bucket {
  final String label;
  final DateTime start; // inclusive
  final DateTime end; // exclusive
  const _Bucket(this.label, this.start, this.end);
}

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthLabels = [
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

class StatsService {
  static List<_Bucket> _buckets(StatsRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (range) {
      case StatsRange.week:
        return List.generate(7, (i) {
          final day = today.subtract(Duration(days: 6 - i));
          return _Bucket(
            _weekdayLabels[day.weekday - 1],
            day,
            day.add(const Duration(days: 1)),
          );
        });
      case StatsRange.month:
        return List.generate(30, (i) {
          final day = today.subtract(Duration(days: 29 - i));
          return _Bucket('${day.day}', day, day.add(const Duration(days: 1)));
        });
      case StatsRange.year:
        return List.generate(12, (i) {
          final offset = 11 - i;
          final monthDate = DateTime(today.year, today.month - offset, 1);
          final nextMonth = DateTime(monthDate.year, monthDate.month + 1, 1);
          return _Bucket(
            _monthLabels[monthDate.month - 1],
            monthDate,
            nextMonth,
          );
        });
    }
  }

  /// Average logged mood (1-5) per bucket. `null` where nothing was logged.
  static List<ChartPoint> moodTrend(StatsRange range) {
    final buckets = _buckets(range);
    final entries = DbService.moodBox.values.toList();
    return buckets.map((b) {
      final inBucket = entries.where(
        (e) => !e.createdAt.isBefore(b.start) && e.createdAt.isBefore(b.end),
      );
      if (inBucket.isEmpty) return ChartPoint(b.label, null);
      final avg =
          inBucket.map((e) => e.mood).reduce((a, c) => a + c) / inBucket.length;
      return ChartPoint(b.label, avg);
    }).toList();
  }

  /// Percentage (0-100) of habit-days completed per bucket, using the
  /// current habit count as the denominator for every day. `null` if there
  /// are no habits at all yet.
  static List<ChartPoint> habitCompletion(StatsRange range) {
    final buckets = _buckets(range);
    final totalHabits = DbService.habitBox.values.length;
    if (totalHabits == 0) {
      return buckets.map((b) => ChartPoint(b.label, null)).toList();
    }
    final logs = DbService.habitLogBox.values.toList();
    return buckets.map((b) {
      final dayCount = b.end.difference(b.start).inDays;
      final doneCount = logs
          .where((l) => !l.date.isBefore(b.start) && l.date.isBefore(b.end))
          .length;
      final possible = totalHabits * dayCount;
      final percent = possible == 0 ? 0.0 : doneCount / possible * 100;
      return ChartPoint(b.label, percent.clamp(0, 100));
    }).toList();
  }

  /// Number of journal entries written per bucket.
  static List<ChartPoint> journalActivity(StatsRange range) {
    final buckets = _buckets(range);
    final entries = DbService.journalBox.values.toList();
    return buckets.map((b) {
      final count = entries
          .where(
            (e) =>
                !e.createdAt.isBefore(b.start) && e.createdAt.isBefore(b.end),
          )
          .length;
      return ChartPoint(b.label, count.toDouble());
    }).toList();
  }

  /// Count of logged moods per level (1-5) within the given range.
  static Map<int, int> moodCounts(StatsRange range) {
    final buckets = _buckets(range);
    final start = buckets.first.start;
    final end = buckets.last.end;
    final counts = {for (var m = 1; m <= 5; m++) m: 0};
    for (final e in DbService.moodBox.values) {
      if (!e.createdAt.isBefore(start) && e.createdAt.isBefore(end)) {
        counts[e.mood] = (counts[e.mood] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// How steady mood has been over the range: 100 = identical mood every
  /// bucket, 0 = swinging the full 1-5 range every time. `null` when there
  /// isn't enough logged data (fewer than 2 buckets with an entry) to
  /// compare consecutive buckets at all.
  static MoodStability? moodStability(StatsRange range) {
    final buckets = _buckets(range);
    final entries = DbService.moodBox.values.toList();
    final values = <double>[];
    for (final b in buckets) {
      final inBucket = entries.where(
        (e) => !e.createdAt.isBefore(b.start) && e.createdAt.isBefore(b.end),
      );
      if (inBucket.isNotEmpty) {
        final avg =
            inBucket.map((e) => e.mood).reduce((a, c) => a + c) /
            inBucket.length;
        values.add(avg);
      }
    }
    if (values.length < 2) return null;

    double totalDiff = 0;
    for (var i = 1; i < values.length; i++) {
      totalDiff += (values[i] - values[i - 1]).abs();
    }
    // avgDiff ranges 0 (no swing) .. 4 (bounces between 1 and 5 every time)
    final avgDiff = totalDiff / (values.length - 1);
    final score = (100 - (avgDiff / 4 * 100)).clamp(0.0, 100.0);

    final String label;
    if (score >= 80) {
      label = 'Very stable';
    } else if (score >= 60) {
      label = 'Balanced';
    } else if (score >= 40) {
      label = 'Fluctuating';
    } else {
      label = 'Volatile';
    }

    return (score: score, label: label, trend: values);
  }

  static DateTime _dayRangeStart(StatsRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (range) {
      case StatsRange.week:
        return today.subtract(const Duration(days: 6));
      case StatsRange.month:
        return today.subtract(const Duration(days: 29));
      case StatsRange.year:
        return today.subtract(const Duration(days: 364));
    }
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// How each habit relates to mood: the average mood on days it was done
  /// vs. days it wasn't, over the range (day-level, regardless of the
  /// week/month/year bucket size used elsewhere). Only mood-logged days
  /// count on either side, and a habit only appears once there's at least
  /// [_minCorrelationDays] days on both sides — otherwise a single day
  /// would look like a trend.
  static const _minCorrelationDays = 3;

  static List<HabitMoodCorrelation> habitMoodCorrelations(StatsRange range) {
    final start = _dayRangeStart(range);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final moodByDay = <String, List<int>>{};
    for (final m in DbService.moodBox.values) {
      final d = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (d.isBefore(start) || d.isAfter(today)) continue;
      moodByDay.putIfAbsent(_dayKey(d), () => []).add(m.mood);
    }
    final avgMoodByDay = {
      for (final e in moodByDay.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

    final results = <HabitMoodCorrelation>[];
    for (final h in DbService.habitBox.values) {
      final createdDay = DateTime(
        h.createdAt.year,
        h.createdAt.month,
        h.createdAt.day,
      );
      final habitStart = createdDay.isAfter(start) ? createdDay : start;
      if (habitStart.isAfter(today)) continue;

      final doneDays = DbService.habitLogBox.values
          .where((l) => l.habitId == h.id)
          .map((l) => _dayKey(DateTime(l.date.year, l.date.month, l.date.day)))
          .toSet();

      final whenDone = <double>[];
      final whenNotDone = <double>[];
      for (
        var d = habitStart;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))
      ) {
        final key = _dayKey(d);
        final mood = avgMoodByDay[key];
        if (mood == null) continue;
        if (doneDays.contains(key)) {
          whenDone.add(mood);
        } else {
          whenNotDone.add(mood);
        }
      }

      if (whenDone.length < _minCorrelationDays ||
          whenNotDone.length < _minCorrelationDays) {
        continue;
      }

      results.add((
        habitName: h.name,
        avgWhenDone: whenDone.reduce((a, b) => a + b) / whenDone.length,
        avgWhenNotDone:
            whenNotDone.reduce((a, b) => a + b) / whenNotDone.length,
        doneDays: whenDone.length,
        notDoneDays: whenNotDone.length,
      ));
    }
    return results;
  }

  /// Average mood on days a journal entry was written vs. days it wasn't,
  /// over the range — the same idea as [habitMoodCorrelations] but for
  /// journaling itself rather than any one habit. `null` when there isn't
  /// enough mood-logged data on both sides to compare.
  static JournalMoodCorrelation? journalMoodCorrelation(StatsRange range) {
    final start = _dayRangeStart(range);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final moodByDay = <String, List<int>>{};
    for (final m in DbService.moodBox.values) {
      final d = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (d.isBefore(start) || d.isAfter(today)) continue;
      moodByDay.putIfAbsent(_dayKey(d), () => []).add(m.mood);
    }
    final avgMoodByDay = {
      for (final e in moodByDay.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

    final journaledDays = DbService.journalBox.values
        .map(
          (j) => _dayKey(
            DateTime(j.createdAt.year, j.createdAt.month, j.createdAt.day),
          ),
        )
        .toSet();

    final whenJournaled = <double>[];
    final whenNot = <double>[];
    for (var d = start; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
      final key = _dayKey(d);
      final mood = avgMoodByDay[key];
      if (mood == null) continue;
      if (journaledDays.contains(key)) {
        whenJournaled.add(mood);
      } else {
        whenNot.add(mood);
      }
    }

    if (whenJournaled.length < _minCorrelationDays ||
        whenNot.length < _minCorrelationDays) {
      return null;
    }

    return (
      avgWhenJournaled:
          whenJournaled.reduce((a, b) => a + b) / whenJournaled.length,
      avgWhenNot: whenNot.reduce((a, b) => a + b) / whenNot.length,
      journaledDays: whenJournaled.length,
      notJournaledDays: whenNot.length,
    );
  }

  /// The single best- and worst-mood entries logged within the range (ties
  /// broken by whichever happened most recently). `null` when nothing was
  /// logged in the range at all.
  static BestWorstDay? bestWorstDay(StatsRange range) {
    final buckets = _buckets(range);
    final start = buckets.first.start;
    final end = buckets.last.end;
    final inRange = DbService.moodBox.values
        .where((e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(end))
        .toList();
    if (inRange.isEmpty) return null;

    MoodEntry best = inRange.first;
    MoodEntry worst = inRange.first;
    for (final e in inRange) {
      if (e.mood > best.mood ||
          (e.mood == best.mood && e.createdAt.isAfter(best.createdAt))) {
        best = e;
      }
      if (e.mood < worst.mood ||
          (e.mood == worst.mood && e.createdAt.isAfter(worst.createdAt))) {
        worst = e;
      }
    }
    return (best: best, worst: worst);
  }

  static const _weekdayFullLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Average logged mood per weekday over the range, plus which weekday
  /// comes out best/worst. `bestWeekday`/`worstWeekday` are `null` until at
  /// least two different weekdays have logged data to compare.
  static MoodByWeekday moodByWeekday(StatsRange range) {
    final buckets = _buckets(range);
    final start = buckets.first.start;
    final end = buckets.last.end;
    final byWeekday = <int, List<int>>{};
    for (final e in DbService.moodBox.values) {
      if (e.createdAt.isBefore(start) || !e.createdAt.isBefore(end)) continue;
      byWeekday.putIfAbsent(e.createdAt.weekday, () => []).add(e.mood);
    }

    final points = <ChartPoint>[];
    String? bestWeekday;
    String? worstWeekday;
    double bestAvg = -1;
    double worstAvg = 6;
    for (var w = 1; w <= 7; w++) {
      final logged = byWeekday[w];
      if (logged == null || logged.isEmpty) {
        points.add(ChartPoint(_weekdayLabels[w - 1], null));
        continue;
      }
      final avg = logged.reduce((a, b) => a + b) / logged.length;
      points.add(ChartPoint(_weekdayLabels[w - 1], avg));
      if (avg > bestAvg) {
        bestAvg = avg;
        bestWeekday = _weekdayFullLabels[w - 1];
      }
      if (avg < worstAvg) {
        worstAvg = avg;
        worstWeekday = _weekdayFullLabels[w - 1];
      }
    }

    final weekdaysWithData = byWeekday.keys.length;
    return (
      points: points,
      bestWeekday: weekdaysWithData >= 2 ? bestWeekday : null,
      worstWeekday: weekdaysWithData >= 2 ? worstWeekday : null,
    );
  }
}

/// `avgWhenDone`/`avgWhenNotDone`: average logged mood (1-5) on days the
/// habit was/wasn't completed. `doneDays`/`notDoneDays`: how many
/// mood-logged days backed each average.
typedef HabitMoodCorrelation = ({
  String habitName,
  double avgWhenDone,
  double avgWhenNotDone,
  int doneDays,
  int notDoneDays,
});

/// `score`: 0-100 stability rating. `label`: short human-readable summary.
/// `trend`: the per-bucket average moods the score was computed from, in
/// chronological order — used to draw a small sparkline.
typedef MoodStability = ({double score, String label, List<double> trend});

/// `avgWhenJournaled`/`avgWhenNot`: average logged mood on days a journal
/// entry was/wasn't written. `journaledDays`/`notJournaledDays`: how many
/// mood-logged days backed each average.
typedef JournalMoodCorrelation = ({
  double avgWhenJournaled,
  double avgWhenNot,
  int journaledDays,
  int notJournaledDays,
});

/// The single highest- and lowest-mood entries logged in a range.
typedef BestWorstDay = ({MoodEntry best, MoodEntry worst});

/// `points`: one [ChartPoint] per weekday (Mon-Sun), average mood or `null`
/// if nothing was logged that weekday. `bestWeekday`/`worstWeekday`: full
/// weekday names, or `null` until there's enough data to compare.
typedef MoodByWeekday = ({
  List<ChartPoint> points,
  String? bestWeekday,
  String? worstWeekday,
});
