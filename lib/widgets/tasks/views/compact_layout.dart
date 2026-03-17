import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';
import '../../shared/empty_state_widget.dart';
import '../../../painters/empty_state_painters.dart';

class CompactLayout extends StatelessWidget {
  final List<Task> tasks;
  const CompactLayout({super.key, required this.tasks});

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

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
      itemBuilder: (context, index) {
        return _CompactRow(task: tasks[index]);
      },
    );
  }
}

class _CompactRow extends StatefulWidget {
  final Task task;
  const _CompactRow({required this.task});

  @override
  State<_CompactRow> createState() => _CompactRowState();
}

class _CompactRowState extends State<_CompactRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final t = widget.task;
    final isOverdue = t.isOverdue && !t.isCompleted;
    final nav = context.read<NavigationProvider>();

    final priorityColor = _priorityColor(t.priority);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => nav.selectTask(t.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 36,
          color: _hovered ? accent.withOpacity(0.04) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Checkbox  
              GestureDetector(
                onTap: () => context.read<TaskProvider>().toggleComplete(t.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: t.isCompleted ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: t.isCompleted
                        ? null
                        : Border.all(color: colors.textSecondary, width: 1.5),
                  ),
                  child: t.isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              // Priority dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: t.priority == Priority.none
                      ? Colors.transparent
                      : priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Title
              Expanded(
                child: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: t.isCompleted
                        ? colors.textPrimary.withOpacity(0.4)
                        : (isOverdue ? AppColors.red : colors.textPrimary),
                    decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // Due date
              if (t.dueDate != null) ...[
                const SizedBox(width: 8),
                Text(
                  AppDateUtils.formatDueDate(t.dueDate!, t.dueHour, t.dueMinute),
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: isOverdue ? AppColors.red : colors.textTertiary,
                  ),
                ),
              ],
              // Tag
              if (t.tags.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.tags.first,
                    style: AppTypography.caption.copyWith(fontSize: 11, color: colors.textTertiary),
                  ),
                ),
              ],
              // Flag
              if (t.isFlagged) ...[
                const SizedBox(width: 6),
                Icon(Icons.star_rounded, size: 14, color: accent),
              ],
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
      case Priority.urgent:  return AppColors.pinkRed;
    }
  }
}
