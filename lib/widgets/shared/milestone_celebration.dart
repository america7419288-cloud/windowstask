import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/deco_sticker.dart';
import '../../data/app_stickers.dart';

class _MilestoneData {
  final String title;
  final String subtitle;
  final Color color;

  const _MilestoneData(this.title, this.subtitle, this.color);
}

class MilestoneCelebration {
  static final _milestones = {
    3: const _MilestoneData(
      '3-Day Streak! 🔥',
      "You're on a roll!",
      AppColors.priorityMedium,
    ),
    7: const _MilestoneData(
      'One Week Strong! ⚡',
      'A full week of momentum. +1 Shield earned!',
      AppColors.primary,
    ),
    14: const _MilestoneData(
      'Two Weeks! 🏆',
      "You're building a real habit.",
      AppColors.tertiary,
    ),
    30: const _MilestoneData(
      '30 Days! 💎',
      'A full month of focus. Incredible. +2 Shields earned!',
      AppColors.xpGold,
    ),
    60: const _MilestoneData(
      '60 Days! 🌟',
      "You're unstoppable.",
      AppColors.priorityUrgent,
    ),
    100: const _MilestoneData(
      '100 Days! 🎖️',
      'Legendary. Truly legendary.',
      AppColors.xpGold,
    ),
  };

  static bool isMilestone(int streak) => _milestones.containsKey(streak);

  static Future<void> show(BuildContext context, int streak) {
    if (streak <= 0) return Future.value();

    final data = _milestones[streak] ?? const _MilestoneData(
      'Streak Continued! 🔥',
      "You're building an incredible habit. Keep it up!",
      AppColors.xpGold,
    );

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      pageBuilder: (_, anim, __) => _MilestonePage(streak: streak, data: data),
      transitionBuilder: (context, anim, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        )),
        child: FadeTransition(opacity: anim, child: child),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class _MilestonePage extends StatelessWidget {
  final int streak;
  final _MilestoneData data;

  const _MilestonePage({required this.streak, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.ambientShadow(
              opacity: 0.25,
              blur: 50,
              offset: const Offset(0, 20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big animated sticker
              const DecoSticker(
                sticker: AppStickers.celebration,
                size: 100,
                animate: true,
              ),
              const SizedBox(height: 24),

              // Milestone number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$streak DAYS',
                  style: AppTypography.labelLarge.copyWith(
                    color: data.color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                data.title,
                style: AppTypography.headlineSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                data.subtitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // XP reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientSuccess,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.ambientShadow(
                    opacity: 0.2,
                    blur: 12,
                    offset: const Offset(0, 4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '+${streak * 10} XP earned!',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Continue button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.ambientShadow(
                      opacity: 0.2,
                      blur: 12,
                      offset: const Offset(0, 4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Keep going! →',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
