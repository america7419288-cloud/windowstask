import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';
import '../task_card.dart';
import '../../shared/empty_state_widget.dart';
import '../../../painters/empty_state_painters.dart';

class GridViewLayout extends StatelessWidget {
  final List<Task> tasks;
  const GridViewLayout({super.key, required this.tasks});

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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _GridTaskCard(task: tasks[index]),
    );
  }
}

class _GridTaskCard extends StatefulWidget {
  final Task task;
  const _GridTaskCard({required this.task});

  @override
  State<_GridTaskCard> createState() => _GridTaskCardState();
}

class _GridTaskCardState extends State<_GridTaskCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final t = widget.task;
    final isDark = colors.isDark;
    final nav = context.read<NavigationProvider>();
    final isSelected = context.watch<NavigationProvider>().selectedTaskId == t.id;
    final isOverdue = t.isOverdue && !t.isCompleted;

    final priorityColor = _priorityColor(t.priority);

    final bgGradient = t.isCompleted
        ? null
        : (isDark ? AppColors.cardGradientDark() : AppColors.cardGradientLight());
    final bgColor = t.isCompleted
        ? (isDark ? const Color(0xFF1E1E20) : const Color(0xFFF9F9FB))
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => nav.selectTask(t.id),
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bgGradient == null ? bgColor : null,
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accent
                  : (_hovered ? colors.textTertiary.withOpacity(0.25) : colors.border),
              width: isSelected ? 1.5 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : (_hovered ? 0.1 : 0.05)),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left priority border
                Container(width: 4, color: t.isCompleted ? AppColors.green : priorityColor),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          t.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isOverdue ? AppColors.red : colors.textPrimary,
                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        // Description
                        if (t.description != null && t.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            t.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Divider
                        Divider(height: 1, color: colors.divider),
                        const SizedBox(height: 6),
                        // Metadata row
                        Row(
                          children: [
                            if (t.dueDate != null)
                              Text(
                                AppDateUtils.formatDueDate(t.dueDate!, t.dueHour, t.dueMinute),
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: isOverdue ? AppColors.red : colors.textTertiary,
                                ),
                              ),
                            if (t.dueDate != null && t.tags.isNotEmpty)
                              Text(' · ', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                            if (t.tags.isNotEmpty)
                              Text(
                                '#${t.tags.first}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.indigo,
                                ),
                              ),
                            const Spacer(),
                            if (t.isFlagged)
                              Icon(Icons.flag_rounded, size: 12, color: AppColors.orange),
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
