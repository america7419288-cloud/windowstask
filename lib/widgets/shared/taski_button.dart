import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';

// Gradient primary button
class TaskiButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isFullWidth;
  final bool isSmall;

  const TaskiButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isFullWidth = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: isFullWidth ? double.infinity : null,
        padding: isSmall
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          gradient: onTap != null ? AppColors.gradPrimary : null,
          color: onTap == null ? AppColors.t4Light : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: onTap != null ? AppColors.shadowPrimary() : [],
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTypography.labelLG.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
