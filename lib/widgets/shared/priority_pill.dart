import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

// Tiny priority indicator pill
class PriorityPill extends StatelessWidget {
  final Priority priority;

  const PriorityPill({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    if (priority == Priority.none) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.priorityBg(priority),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        AppColors.priorityLabel(priority).toUpperCase(),
        style: AppTypography.micro.copyWith(
          color: AppColors.priorityColor(priority),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
