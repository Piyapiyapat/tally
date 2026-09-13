import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/journal_entry.dart';
import 'db_service.dart';

/// Builds a printable PDF report of the user's mood, habit, and journal
/// history — independent of the Firebase cloud backup, so it works even for
/// someone who never links an account. Embeds a Thai-capable font since
/// journal/mood notes may be written in Thai.
class ExportService {
  static String _moodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Bad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return '';
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// [from] and [to] are both inclusive. Only mood/journal entries and habit
  /// completions within that window are included; the habit list itself
  /// (name/created date) is unfiltered so a habit created before the window
  /// but still logged during it still shows up. Each `include*` flag lets
  /// the caller leave a whole section out of the report.
  ///
  /// Returns raw PDF bytes so callers can preview it (e.g. [PdfPreview])
  /// before deciding to save, print, or share it.
  static Future<Uint8List> buildReportBytes({
    required DateTime from,
    required DateTime to,
    bool includeMoods = true,
    bool includeHabits = true,
    bool includeJournals = true,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansThaiRegular();
    final boldFont = await PdfGoogleFonts.notoSansThaiBold();

    bool inRange(DateTime d) => !d.isBefore(from) && !d.isAfter(to);

    final moods = DbService.moodBox.values.where((m) => inRange(m.createdAt)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final habits = DbService.habitBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final journals = DbService.journalBox.values.where((j) => inRange(j.createdAt)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // How many times each mood level (1-5) was logged in the period.
    final moodCounts = {for (var m = 1; m <= 5; m++) m: 0};
    for (final m in moods) {
      moodCounts[m.mood] = (moodCounts[m.mood] ?? 0) + 1;
    }
    final moodCountText = [
      for (var m = 5; m >= 1; m--) '${_moodLabel(m)}: ${moodCounts[m]}',
    ].join('   ');

    // Same 0-100 "how much did mood swing" scoring as the in-app Insights
    // screen, but computed from one average-per-day across the exact
    // report period instead of the app's fixed week/month/year buckets.
    String moodStabilityText() {
      final byDay = <String, List<int>>{};
      for (final m in moods) {
        byDay.putIfAbsent(_fmtDate(m.createdAt), () => []).add(m.mood);
      }
      final dayKeys = byDay.keys.toList()..sort();
      final values = [
        for (final k in dayKeys)
          byDay[k]!.reduce((a, b) => a + b) / byDay[k]!.length,
      ];
      if (values.length < 2) return 'Mood stability: not enough data yet';

      double totalDiff = 0;
      for (var i = 1; i < values.length; i++) {
        totalDiff += (values[i] - values[i - 1]).abs();
      }
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
      return 'Mood stability: ${score.round()}/100 ($label)';
    }

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    // A classic bullet-journal-style tracker: one grid per calendar month
    // covered by the report, habits as rows, days of that month as columns,
    // 'X' where a habit was completed. A habit only appears in a month's
    // grid once it's actually been created.
    List<pw.Widget> habitTrackerWidgets(pw.Context context) {
      final widgets = <pw.Widget>[];
      var cursor = DateTime(from.year, from.month, 1);

      while (!cursor.isAfter(to)) {
        final monthStart = cursor;
        final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
        final monthEndInclusive = nextMonth.subtract(const Duration(days: 1));
        final segStart = monthStart.isBefore(from) ? from : monthStart;
        final segEnd = monthEndInclusive.isAfter(to) ? to : monthEndInclusive;
        cursor = nextMonth;

        final segHabits =
            habits.where((h) => !h.createdAt.isAfter(segEnd)).toList();
        if (segHabits.isEmpty) continue;

        final days = <DateTime>[];
        for (var d = segStart; !d.isAfter(segEnd); d = d.add(const Duration(days: 1))) {
          days.add(d);
        }

        final doneByHabit = <String, Set<String>>{
          for (final h in segHabits)
            h.id: DbService.habitLogBox.values
                .where((l) =>
                    l.habitId == h.id &&
                    !l.date.isBefore(segStart) &&
                    !l.date.isAfter(segEnd))
                .map((l) => _fmtDate(l.date))
                .toSet(),
        };

        widgets.add(
          pw.Text(
            '${monthNames[monthStart.month - 1]} ${monthStart.year}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        );
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(
          pw.TableHelper.fromTextArray(
            context: context,
            headers: ['Habit', ...days.map((d) => '${d.day}')],
            data: [
              for (final h in segHabits)
                [
                  h.name,
                  ...days.map(
                    (d) => doneByHabit[h.id]!.contains(_fmtDate(d)) ? 'X' : '',
                  ),
                ],
            ],
            cellAlignment: pw.Alignment.center,
            cellAlignments: const {0: pw.Alignment.centerLeft},
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            columnWidths: {
              0: const pw.FixedColumnWidth(70),
              for (var i = 0; i < days.length; i++)
                i + 1: const pw.FixedColumnWidth(13),
            },
          ),
        );
        widgets.add(pw.SizedBox(height: 20));
      }

      if (widgets.isEmpty) {
        widgets.add(pw.Text('No habits yet.'));
      }
      return widgets;
    }

    pw.Widget journalBlock(JournalEntry j) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _fmtDate(j.createdAt),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            if (j.title != null && j.title!.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                j.title!,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ],
            if (j.tags.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in j.tags)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Text(
                        tag,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            pw.SizedBox(height: 6),
            pw.Text(j.content, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      );
    }

    final generatedAt = DateTime.now();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        maxPages: 200,
        header: (context) => context.pageNumber == 1
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Tally — Data Report',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Period: ${_fmtDate(from)} to ${_fmtDate(to)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Generated ${_fmtDate(generatedAt)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],
              )
            : pw.SizedBox(),
        build: (context) => [
          if (includeMoods) ...[
            pw.Text(
              'Mood Logs',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (moods.isEmpty)
              pw.Text('No mood logs yet.')
            else ...[
              pw.Text(moodCountText, style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(moodStabilityText(), style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Date', 'Mood', 'Note'],
                data: [
                  for (final m in moods)
                    [_fmtDate(m.createdAt), _moodLabel(m.mood), m.note ?? ''],
                ],
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: const {
                  0: pw.FixedColumnWidth(70),
                  1: pw.FixedColumnWidth(55),
                  2: pw.FlexColumnWidth(),
                },
              ),
            ],
            pw.SizedBox(height: 24),
          ],

          if (includeHabits) ...[
            if (includeMoods) pw.NewPage(),
            pw.Text(
              'Habits',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (habits.isEmpty)
              pw.Text('No habits yet.')
            else
              ...habitTrackerWidgets(context),
          ],

          if (includeJournals) ...[
            if (includeMoods || includeHabits) pw.NewPage(),
            pw.Text(
              'Journal Entries',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (journals.isEmpty)
              pw.Text('No journal entries yet.')
            else
              for (final j in journals) journalBlock(j),
          ],
        ],
      ),
    );

    return doc.save();
  }
}
