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
        Row(
          children: [
            for (final week in weeks)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Column(
                  children: week.map((e) {
                    final intensity = maxVal > 0 ? e.value / maxVal : 0.0;
                    final date = e.key;
                    final parts = date.split('-');
                    final day = int.tryParse(parts.last) ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Tooltip(
                        message: '${e.value} tasks on $date',
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: intensity == 0
                                ? (colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))
                                : accent.withOpacity(0.15 + (intensity * 0.85)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Less', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
            Row(children: [0.12, 0.35, 0.58, 0.8, 1.0].map((o) => Container(
              width: 10, height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(o),
                borderRadius: BorderRadius.circular(2),
              ),
            )).toList()),
            Text('More', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          ],
        ),
      ],
    );
  }
}
