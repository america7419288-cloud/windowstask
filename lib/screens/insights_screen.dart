import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';
import '../widgets/charts/completion_chart.dart';
import '../widgets/charts/heatmap_chart.dart';
import '../widgets/shared/deco_sticker.dart';
import '../data/app_stickers.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row (gradient cards)
              const _StatsRow(),
              const SizedBox(height: 20),
              // Completion chart
              const _Section(
                title: 'Completed (Last 14 Days)',
                emoji: '📊',
                child: CompletionChart(),
              ),
              const SizedBox(height: 20),
              // Heatmap
              const _Section(
                title: 'Activity Heatmap (Last 70 Days)',
                emoji: '🔥',
                child: HeatmapChart(),
              ),
              const SizedBox(height: 20),
              // Focus Stats
              const _Section(
                title: 'Focus Stats (Last 7 Days)',
                emoji: '⏱️',
                child: _FocusStatsCard(),
              ),
              const SizedBox(height: 20),
              // Category breakdown
              const _CategoryBreakdown(),
            ],
          ),
        ),
      ),
    );


  }
}

// ═══════════════════════════════════════════════════════
// _StatsRow — Gradient stat cards
// ═══════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final todayDone = tasks.completedInRange(todayStart, todayEnd);
    final todayTotal = tasks.allTasks.where((t) {
      if (t.isDeleted) return false;
      if (t.dueDate == null) return false;
      return !t.dueDate!.isBefore(todayStart) && t.dueDate!.isBefore(todayEnd.add(const Duration(seconds: 1)));
    }).length;

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekCount = tasks.completedInRange(weekStart, now);

    final monthStart = DateTime(now.year, now.month, 1);
    final monthCount = tasks.completedInRange(monthStart, now);

    final streak = tasks.currentStreak;

    return Row(
      children: [
        // TODAY
        Expanded(
          child: _GradientStatCard(
            label: 'TODAY',
            value: '$todayDone/$todayTotal',
            gradient: AppColors.gradMomentum,
            shadow: AppColors.shadowPrimary(),
            sticker: AppStickers.todayMorning,
          ),
        ),
        const SizedBox(width: 12),
        // THIS WEEK
        Expanded(
          child: _GradientStatCard(
            label: 'THIS WEEK',
            value: '$weekCount',
            gradient: const LinearGradient(
              colors: [Color(0xFF3252B0), Color(0xFF1E2B8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadow: AppColors.shadowPrimary(),
            sticker: AppStickers.insightsWeek,
          ),
        ),
        const SizedBox(width: 12),
        // THIS MONTH
        Expanded(
          child: _GradientStatCard(
            label: 'THIS MONTH',
            value: '$monthCount',
            gradient: const LinearGradient(
              colors: [Color(0xFF2A45A0), Color(0xFF182078)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadow: AppColors.shadowPrimary(),
            sticker: AppStickers.insightsMonth,
          ),
        ),
        const SizedBox(width: 12),
        // STREAK
        Expanded(
          child: _GradientStatCard(
            label: 'STREAK',
            value: '${streak}d',
            gradient: AppColors.gradGold,
            shadow: AppColors.shadowGold(),
            sticker: AppStickers.insightsStreak,
          ),
        ),
      ],
    );
  }
}

class _GradientStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Gradient gradient;
  final List<BoxShadow> shadow;
  final dynamic sticker; // Sticker

  const _GradientStatCard({
    required this.label,
    required this.value,
    required this.gradient,
    required this.shadow,
    this.sticker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.micro.copyWith(
                  color: Colors.white.withValues(alpha: .65),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (sticker != null)
                DecoSticker(sticker: sticker, size: 26, animate: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.displayLG.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// _Section — Shared section card
// ═══════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.emoji});
  final String title;
  final Widget child;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.shadowSM(isDark: colors.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emoji != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(emoji!, style: const TextStyle(fontSize: 12)),
                ),
              Text(
                title.toUpperCase(),
                style: AppTypography.micro.copyWith(
                  color: colors.textQuaternary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.indigo.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// _CategoryBreakdown
// ═══════════════════════════════════════════════════════

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tasks = context.watch<TaskProvider>();
    final lists = context.watch<ListProvider>();

    // Count by list
    final listCounts = <String, int>{};
    for (final task in tasks.allTasks.where((t) => !t.isDeleted)) {
      final key = task.listId ?? 'none';
      listCounts[key] = (listCounts[key] ?? 0) + 1;
    }

    if (listCounts.isEmpty) return const SizedBox.shrink();
    final total = listCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: listCounts.entries.map((e) {
                  final list =
                      e.key != 'none' ? lists.getById(e.key) : null;
                  final color = list != null
                      ? Color(int.parse('FF${list.colorHex}', radix: 16))
                      : colors.textSecondary;
                  final name = list?.name ?? 'Uncategorized';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.bodyMD.copyWith(
                                color: colors.textPrimary),
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: AppTypography.bodyMD.copyWith(
                              color: colors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// _FocusStatsCard
// ═══════════════════════════════════════════════════════

class _FocusStatsCard extends StatelessWidget {
  const _FocusStatsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final stats = StorageService.instance.getFocusStats();

    // Process last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateStr = date.toIso8601String().split('T')[0];
      return MapEntry(date, stats[dateStr] ?? 0);
    });

    final totalMinutes = last7Days.fold(0, (sum, e) => sum + e.value);
    final maxMinutes =
        last7Days.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final yInterval = (maxMinutes / 4).clamp(1.0, 60.0).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MiniStat(
                label: 'Total Focused',
                value: '${totalMinutes}m',
                color: AppColors.danger),
            const SizedBox(width: 24),
            _MiniStat(
                label: 'Daily Avg',
                value: '${(totalMinutes / 7).round()}m',
                color: AppColors.warning),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxMinutes * 1.2).clamp(10.0, double.infinity),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= 7) {
                        return const SizedBox.shrink();
                      }
                      final date = last7Days[index].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('E').format(date)[0],
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}m',
                        style: AppTypography.caption.copyWith(
                          fontSize: 9,
                          color: colors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colors.border.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: last7Days[i].value.toDouble(),
                      color: AppColors.indigo,
                      width: 14,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: (maxMinutes * 1.2)
                            .clamp(10.0, double.infinity),
                        color: colors.isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.micro.copyWith(
            color: colors.textQuaternary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.displayLG.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
