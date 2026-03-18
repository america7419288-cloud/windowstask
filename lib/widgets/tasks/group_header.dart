import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../shared/pressable_scale.dart';

class GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool isCollapsed;
  final VoidCallback onTap;

  const GroupHeader({
    super.key,
    required this.label,
    required this.count,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PressableScale(
        scaleDown: 0.98,
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Animated chevron
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: isCollapsed ? 0 : 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * (math.pi / 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 12,
                      color: colors.textTertiary,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              // Label
              Text(
                label.toUpperCase(),
                style: AppTypography.micro.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colors.textQuaternary,
                ),
              ),
              const SizedBox(width: 8),
              // Thin divider line
              Expanded(
                child: Container(
                  height: 0.5,
                  color: colors.divider,
                ),
              ),
              const SizedBox(width: 8),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.micro.copyWith(
                    fontSize: 10,
                    color: colors.isDark
                        ? colors.textSecondary
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
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

