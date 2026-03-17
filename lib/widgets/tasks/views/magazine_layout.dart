import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';

class MagazineLayout extends StatelessWidget {
  final List<Task> tasks;
  const MagazineLayout({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _MagazineCard(task: tasks[index]),
    );
  }
}

class _MagazineCard extends StatefulWidget {
  final Task task;
  const _MagazineCard({required this.task});

  @override
  State<_MagazineCard> createState() => _MagazineCardState();
}

class _MagazineCardState extends State<_MagazineCard> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final t = widget.task;
    final isDark = colors.isDark;
    final isOverdue = t.isOverdue && !t.isCompleted;
    final nav = context.read<NavigationProvider>();

    final priorityColor = _priorityColor(t.priority);
    final priorityLabel = _priorityLabel(t.priority);

    final bgGradient = t.isCompleted
        ? null
        : (isDark ? AppColors.cardGradientDark() : AppColors.cardGradientLight());
    final bgColor = t.isCompleted
        ? (isDark ? const Color(0xFF1E1E20) : const Color(0xFFF9F9FB))
        : null;

    final completedCount = t.subtasks.where((s) => s.isCompleted).length;
    final totalSubtasks = t.subtasks.length;

    return GestureDetector(
      onTap: () => nav.selectTask(t.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: bgGradient == null ? bgColor : null,
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19.5),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Left priority bar (6px thick)
              Container(
                width: 6,
                color: t.isCompleted ? AppColors.green : priorityColor,
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta header
                      Row(
                        children: [
                          if (t.priority != Priority.none) ...[
                            Text(
                              priorityLabel.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(' · ', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                          ],
                          if (t.dueDate != null)
                            Text(
                              AppDateUtils.formatDueDate(t.dueDate!, t.dueHour, t.dueMinute),
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: isOverdue ? AppColors.red : colors.textTertiary,
                              ),
                            ),
                          const Spacer(),
                          if (t.isFlagged)
                            GestureDetector(
                              onTap: () => context.read<TaskProvider>().toggleFlag(t.id),
                              child: Icon(Icons.flag_rounded, size: 16, color: AppColors.orange),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headline.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: t.isCompleted
                              ? colors.textPrimary.withOpacity(0.5)
                              : colors.textPrimary,
                          decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      // Description
                      if (t.description != null && t.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          t.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      // Subtask progress bar
                      if (totalSubtasks > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: LinearProgressIndicator(
                                  value: totalSubtasks == 0 ? 0 : completedCount / totalSubtasks,
                                  minHeight: 4,
                                  backgroundColor: colors.divider,
                                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$completedCount/$totalSubtasks subtasks',
                              style: AppTypography.caption.copyWith(
                                fontSize: 12,
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Footer
                      const SizedBox(height: 16),
                      Divider(height: 1, color: colors.divider),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Complete toggle
                          GestureDetector(
                            onTap: () => context.read<TaskProvider>().toggleComplete(t.id),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: t.isCompleted ? AppColors.green : Colors.transparent,
                                    border: t.isCompleted
                                        ? null
                                        : Border.all(color: colors.textSecondary, width: 1.5),
                                  ),
                                  child: t.isCompleted
                                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t.isCompleted ? 'Completed' : 'Mark complete',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 13,
                                    color: t.isCompleted ? AppColors.green : colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Tags
                          ...t.tags.take(3).map((tag) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.textTertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$tag',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.indigo,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.none:    return Colors.transparent;
      case Priority.low:     return AppColors.green;
      case Priority.medium:  return AppColors.orange;
      case Priority.high:    return AppColors.red;
      case Priority.urgent:  return AppColors.pinkRed;
    }
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.none:    return '';
      case Priority.low:     return 'Low';
      case Priority.medium:  return 'Medium';
      case Priority.high:    return 'High';
      case Priority.urgent:  return 'Urgent';
    }
  }
}
