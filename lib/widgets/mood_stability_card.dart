import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/stats_service.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'icon_badge.dart';

/// Headline "how steady has your mood been" card — score + sparkline.
/// Shared between Home (fixed to [StatsRange.week]) and the Statistics
/// screen (follows the selected range).
class MoodStabilityCard extends StatelessWidget {
  final StatsRange range;
  const MoodStabilityCard({super.key, required this.range});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stability = StatsService.moodStability(range);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.timeline_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood stability',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.deep,
                      ),
                    ),
                    Text(
                      stability?.label ?? 'Not enough data yet',
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
          ),
          const SizedBox(height: 16),
          if (stability == null)
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  'Log moods on a few more days to see this',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textDim,
                  ),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  stability.score.round().toString(),
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: colors.deep,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: LineChart(
                      LineChartData(
                        minY: 1,
                        maxY: 5,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < stability.trend.length; i++)
                                FlSpot(i.toDouble(), stability.trend[i]),
                            ],
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: colors.accent,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
