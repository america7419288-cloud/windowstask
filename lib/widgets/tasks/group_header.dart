import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../shared/pressable_scale.dart';
import '../shared/deco_sticker.dart';
import '../../data/app_stickers.dart';

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
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.micro.copyWith(
                  color: colors.textQuaternary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.indigoDim,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.indigo,
                    letterSpacing: 0,
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


