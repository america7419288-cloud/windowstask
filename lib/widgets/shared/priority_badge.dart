import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = false,
  });

  final Priority priority;
  final bool showLabel;

  static Color colorForPriority(Priority priority) {
    switch (priority) {
      case Priority.none:
        return const Color(0xFF94A3B8);
      case Priority.low:
        return AppColors.green;
      case Priority.medium:
        return AppColors.orange;
      case Priority.high:
        return AppColors.red;
      case Priority.urgent:
        return AppColors.pink;
    }
  }

  static String labelForPriority(Priority p) {
    switch (p) {
      case Priority.none:
        return 'None';
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorForPriority(priority);
    if (!showLabel) {
      return Container(
        width: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.radiusCard),
            bottomLeft: Radius.circular(AppConstants.radiusCard),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusChip),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            labelForPriority(priority),
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
