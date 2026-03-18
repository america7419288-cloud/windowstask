import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';
import '../shared/task_interaction_wrapper.dart';
import '../../context_menu/context_menu_controller.dart';
import '../../../providers/list_provider.dart';
import '../../shared/empty_state_widget.dart';
import '../../../painters/empty_state_painters.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MagazineLayout extends StatelessWidget {
  final List<Task> tasks;
  const MagazineLayout({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyStateWidget(
        config: EmptyStateConfig(
          painterBuilder: (v) => SearchEmptyPainter(v),
          headline: 'No tasks',
          subline: 'Tasks will appear here once added.',
        ),
      );
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

    final completedCount = t.subtasks.where((s) => s.isCompleted).length;
    final totalSubtasks = t.subtasks.length;

    final listName = t.listId != null ? context.read<ListProvider>().getById(t.listId!)?.name : null;

    return TaskInteractionWrapper(
      task: t,
      actionsPosition: HoverActionsPosition.topRight,
      child: GestureDetector(
        onTap: () => nav.selectTask(t.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppColors.elevatedDecoration(
            isDark: isDark,
            borderRadius: 20,
          ).copyWith(
            color: t.isCompleted 
                ? (isDark ? colors.surfaceElevated.withValues(alpha: 0.5) : colors.surfaceElevated.withValues(alpha: 0.7))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top priority strip
              if (t.priority != Priority.none)
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [priorityColor, priorityColor.withValues(alpha: 0.4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                )
              else if (t.isCompleted)
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta header
                    Row(
                      children: [
                        if (t.priority != Priority.none) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priorityLabel.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                                letterSpacing: 0.6,
                              ),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: t.isCompleted
                            ? colors.textPrimary.withValues(alpha: 0.5)
                            : colors.textPrimary,
                        decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    // Description
                    if (t.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        t.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    // List Name
                    if (listName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '📋 $listName',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          color: colors.textTertiary,
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
                        // Complete toggle pill
                        GestureDetector(
                          onTap: () => context.read<TaskProvider>().toggleComplete(t.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: t.isCompleted
                                  ? AppColors.green.withValues(alpha: 0.1)
                                  : colors.isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: t.isCompleted
                                    ? AppColors.green.withValues(alpha: 0.3)
                                    : colors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: Icon(
                                    t.isCompleted
                                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                                        : PhosphorIcons.circle(),
                                    key: ValueKey<bool>(t.isCompleted),
                                    size: 13,
                                    color: t.isCompleted ? AppColors.green : colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  t.isCompleted ? 'Completed' : 'Mark complete',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 12,
                                    color: t.isCompleted ? AppColors.green : colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Tags
                        ...t.tags.take(3).map((tagId) {
                          final tagName = context.read<TagProvider>().getById(tagId)?.name ?? 'Tag';
                          return Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.indigo.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#$tagName',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.indigo,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
      case Priority.urgent:  return AppColors.pink;
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
