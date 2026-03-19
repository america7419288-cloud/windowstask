import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';

class HeatmapChart extends StatelessWidget {
  const HeatmapChart({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tasks = context.watch<TaskProvider>();
    final accent = Theme.of(context).colorScheme.primary;
    final data = tasks.completionByDay(70); // 10 weeks

    final maxVal = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    final weeks = <List<MapEntry<String, int>>>[];
    final entries = data.entries.toList();
    for (int i = 0; i < entries.length; i += 7) {
      weeks.add(entries.sublist(i, (i + 7).clamp(0, entries.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final week in weeks)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    children: week.map((e) {
                      final val = e.value;
                      final date = e.key;
                      
                      Color color;
                      if (val == 0) color = const Color(0xFFF3F4F6);
                      else if (val <= 2) color = const Color(0xFFF5E6FF);
                      else if (val <= 5) color = const Color(0xFFE9CCFF);
                      else if (val <= 10) color = const Color(0xFFD9A3FF);
                      else color = const Color(0xFFC475FF);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Tooltip(
                          message: '$val tasks on $date',
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less', style: AppTypography.metadata.copyWith(color: colors.textSecondary.withValues(alpha: 0.55))),
            const SizedBox(width: 8),
            Row(
              children: [
                const Color(0xFFF3F4F6),
                const Color(0xFFF5E6FF),
                const Color(0xFFE9CCFF),
                const Color(0xFFD9A3FF),
                const Color(0xFFC475FF),
              ].map((c) => Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                ),
              )).toList(),
            ),
            const SizedBox(width: 8),
            Text('More', style: AppTypography.metadata.copyWith(color: colors.textSecondary.withValues(alpha: 0.55))),
          ],
        ),
      ],
    );
  }
}
