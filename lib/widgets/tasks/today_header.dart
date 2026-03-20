import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sticker.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../theme/app_theme.dart';
import '../../data/app_stickers.dart';
import '../shared/deco_sticker.dart';
import '../../providers/navigation_provider.dart';

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
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final nav = context.watch<NavigationProvider>();
    
    final isDone = taskCount > 0 && completedCount == taskCount;
    final sticker = isDone ? AppStickers.todayAllDone : _getTimeSticker();

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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 16),
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
