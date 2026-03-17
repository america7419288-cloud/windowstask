import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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
    final accent = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PressableScale(
        scaleDown: 0.98,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
          child: Row(
            children: [
              // Animated chevron (0 = right, 1 = down)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: isCollapsed ? 0 : 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * (math.pi / 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.textTertiary,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              // Uppercase Label
              Text(
                label.toUpperCase(),
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: colors.textTertiary,
                ),
              ),
              const Spacer(),
              // Count Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
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
