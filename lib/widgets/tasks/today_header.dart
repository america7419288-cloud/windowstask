import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sticker.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../theme/app_theme.dart';
import '../../data/app_stickers.dart';
import '../shared/deco_sticker.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';

class TodayHeader extends StatelessWidget {
  final int taskCount;
  final int completedCount;

  const TodayHeader({
    super.key,
    required this.taskCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    final tasks = context.watch<TaskProvider>();
    
    final isDone = taskCount > 0 && completedCount == taskCount;
    final sticker = isDone ? AppStickers.todayAllDone : _getTimeSticker();
    final remaining = taskCount - completedCount;
    final progress = taskCount > 0 ? completedCount / taskCount : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _greeting(),
                  style: AppTypography.title1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              DecoSticker(
                sticker: sticker,
                size: 64,
                animate: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _dateString(),
            style: AppTypography.callout.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: colors.textTertiary,
            ),
          ),
          // Progress bar
          if (taskCount > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      children: [
                        Container(
                          color: colors.isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isDone
                                  ? const LinearGradient(
                                      colors: [AppColors.success, Color(0xFF34D399)])
                                  : AppColors.gradientPrimary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Stats row
            Row(
              children: [
                _MiniStat('✅', '$completedCount done',
                    isDone ? AppColors.success : colors.textTertiary),
                _dot(colors),
                _MiniStat('📋', '$remaining left', colors.textTertiary),
                if (tasks.currentStreak > 0) ...[
                  _dot(colors),
                  _MiniStat('🔥', '${tasks.currentStreak}d streak',
                      AppColors.danger.withValues(alpha: 0.8)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'MITs Only',
                    isSelected: nav.filterMITs,
                    onTap: nav.toggleFilterMITs,
                    accentColor: const Color(0xFFFFD60A),
                    icon: Icons.star_rounded,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'High Priority',
                    isSelected: nav.filterHighPriority,
                    onTap: nav.toggleFilterHighPriority,
                    accentColor: AppColors.priorityHigh,
                    icon: Icons.priority_high_rounded,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Overdue',
                    isSelected: nav.filterOverdue,
                    onTap: nav.toggleFilterOverdue,
                    accentColor: AppColors.red,
                    icon: Icons.history_rounded,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _QuoteCard(),
          if (DateTime.now().hour < 12 && nav.mitTaskIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlanningButton(),
            ),
        ],
      ),
    );
  }

  static Widget _dot(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('•', style: TextStyle(color: colors.textQuaternary, fontSize: 10)),
    );
  }


  Sticker _getTimeSticker() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return AppStickers.todayMorning;
    if (hour >= 12 && hour < 17) return AppStickers.todayAfternoon;
    if (hour >= 17 && hour < 21) return AppStickers.todayEvening;
    return AppStickers.todayNight;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }
  String _dateString() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;
  const _MiniStat(this.emoji, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 3),
        Text(
          text,
          style: AppTypography.micro.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final quotes = [
      "Focus is a matter of deciding what things you're not going to do.",
      "The secret of getting ahead is getting started.",
      "Your mind is for having ideas, not holding them.",
      "Simple can be harder than complex: You have to work hard to get your thinking clean.",
      "Yesterday is not ours to recover, but tomorrow is ours to win or lose.",
      "Absorb what is useful, discard what is not, add what is uniquely your own.",
      "The way to get started is to quit talking and begin doing."
    ];
    
    final now = DateTime.now();
    final quoteIndex = (now.year + now.month + now.day) % quotes.length;
    final quote = quotes[quoteIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          const DecoSticker(
            sticker: AppStickers.quoteSticker,
            size: 40,
            animate: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quote,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().enterPlanningMode(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sunny_snowing, size: 14, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Plan my day',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor.withValues(alpha: 0.4) : colors.border,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? accentColor : colors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
