import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';

class CompletionChart extends StatelessWidget {
  const CompletionChart({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tasks = context.watch<TaskProvider>();
    final accent = Theme.of(context).colorScheme.primary;
    final data = tasks.completionByDay(14);
    final entries = data.entries.toList();

    if (entries.isEmpty) {
      return const SizedBox(height: 120);
    }

    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: (maxVal + 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(entries.length, (i) => FlSpot(i.toDouble(), entries[i].value.toDouble())),
              isCurved: true,
              color: accent,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: accent.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
