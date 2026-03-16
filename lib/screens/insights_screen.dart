import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../widgets/charts/completion_chart.dart';
import '../widgets/charts/heatmap_chart.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights', style: AppTypography.title1.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 24),
          // Stats row
          _StatsRow(),
          const SizedBox(height: 24),
          // Completion chart
          _Section(
            title: 'Completed (Last 14 Days)',
            child: const CompletionChart(),
          ),
          const SizedBox(height: 20),
          // Heatmap
          _Section(
            title: 'Activity Heatmap (Last 70 Days)',
            child: const HeatmapChart(),
          ),
          const SizedBox(height: 20),
          // Category breakdown
          _CategoryBreakdown(),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Today',
          value: '${tasks.completedInRange(
            DateTime(now.year, now.month, now.day),
            DateTime(now.year, now.month, now.day, 23, 59, 59),
          )}',
          icon: Icons.today_rounded,
          color: AppColors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'This Week',
          value: '${tasks.completedInRange(weekStart, now)}',
          icon: Icons.date_range_rounded,
          color: AppColors.purple,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'This Month',
          value: '${tasks.completedInRange(monthStart, now)}',
          icon: Icons.calendar_month_rounded,
          color: AppColors.green,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Streak',
          value: '${tasks.currentStreak}d',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.orange,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.title1.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodySemibold.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tasks = context.watch<TaskProvider>();
    final lists = context.watch<ListProvider>();
    final accent = Theme.of(context).colorScheme.primary;

    // Count by list
    final listCounts = <String, int>{};
    for (final task in tasks.allTasks.where((t) => !t.isDeleted)) {
      final key = task.listId ?? 'none';
      listCounts[key] = (listCounts[key] ?? 0) + 1;
    }

    if (listCounts.isEmpty) return const SizedBox.shrink();

    final sections = listCounts.entries.map((e) {
      final list = e.key != 'none' ? lists.getById(e.key) : null;
      final color = list != null
          ? Color(int.parse('FF${list.colorHex}', radix: 16))
          : colors.textSecondary;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: 50,
        title: '',
        showTitle: false,
      );
    }).toList();

    return _Section(
      title: 'Tasks by List',
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: listCounts.entries.map((e) {
                final list = e.key != 'none' ? lists.getById(e.key) : null;
                final color = list != null
                    ? Color(int.parse('FF${list.colorHex}', radix: 16))
                    : colors.textSecondary;
                final name = list?.name ?? 'Uncategorized';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(name, style: AppTypography.body.copyWith(color: colors.textPrimary))),
                      Text('${e.value}', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
