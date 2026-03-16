import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/tag_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../shared/priority_badge.dart';
import '../shared/tag_chip.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
  });

  final Task task;
  final bool isSelected;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final tasks = context.read<TaskProvider>();
    final nav = context.read<NavigationProvider>();
    final tagProvider = context.read<TagProvider>();
    final task = widget.task;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => nav.selectTask(task.id),
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (colors.isDark ? Colors.white.withOpacity(0.06) : accent.withOpacity(0.04))
                : colors.isDark
                    ? const Color(0xFF2C2C2E).withOpacity(0.85)
                    : Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(
              color: widget.isSelected
                  ? accent.withOpacity(0.3)
                  : colors.border,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: _hovered && !widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority left border
                if (task.priority != Priority.none)
                  AnimatedContainer(
                    duration: AppConstants.animMedium,
                    width: 3,
                    decoration: BoxDecoration(
                      color: PriorityBadge.colorForPriority(task.priority),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppConstants.radiusCard),
                        bottomLeft: Radius.circular(AppConstants.radiusCard),
                      ),
                    ),
                  ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        _CheckboxWidget(task: task),
                        const SizedBox(width: 10),
                        // Title + meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: AppTypography.body.copyWith(
                                  color: task.isCompleted
                                      ? colors.textSecondary
                                      : colors.textPrimary,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: colors.textSecondary,
                                ),
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  task.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Due date
                                  if (task.dueDate != null)
                                    _MetaChip(
                                      icon: Icons.calendar_today_rounded,
                                      label: AppDateUtils.formatShortDate(task.dueDate!),
                                      color: task.isOverdue ? AppColors.red : colors.textSecondary,
                                    ),
                                  if (task.dueDate != null) const SizedBox(width: 6),
                                  // Flag
                                  if (task.isFlagged)
                                    const _MetaChip(
                                      icon: Icons.flag_rounded,
                                      label: '',
                                      color: AppColors.orange,
                                    ),
                                  if (task.isFlagged) const SizedBox(width: 6),
                                  // Tags (first 2)
                                  ...task.tags.take(2).map((tagId) {
                                    final tag = tagProvider.getById(tagId);
                                    if (tag == null) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: TagChip(
                                        label: tag.name,
                                        colorHex: tag.colorHex,
                                        isSmall: true,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              // Subtask progress
                              if (task.subtasks.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: task.subtaskProgress,
                                          minHeight: 3,
                                          backgroundColor: colors.isDark
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.black.withOpacity(0.08),
                                          valueColor: AlwaysStoppedAnimation(accent),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                                      style: AppTypography.caption.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Hover actions
                        if (_hovered)
                          Row(
                            children: [
                              _HoverAction(
                                icon: Icons.flag_outlined,
                                isActive: task.isFlagged,
                                activeColor: AppColors.orange,
                                onTap: () => tasks.updateTask(task.copyWith(isFlagged: !task.isFlagged)),
                              ),
                              _HoverAction(
                                icon: Icons.delete_outline_rounded,
                                onTap: () => tasks.moveToTrash(task.id),
                              ),
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
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, duration: 200.ms);
  }
}

class _CheckboxWidget extends StatefulWidget {
  const _CheckboxWidget({required this.task});
  final Task task;

  @override
  State<_CheckboxWidget> createState() => _CheckboxWidgetState();
}

class _CheckboxWidgetState extends State<_CheckboxWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animMedium,
    );
    _scale = Tween<double>(begin: 1, end: 1.3).chain(
      CurveTween(curve: Curves.elasticOut),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final tasks = context.read<TaskProvider>();

    return GestureDetector(
      onTap: () {
        _controller.forward(from: 0);
        tasks.toggleComplete(widget.task.id);
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: widget.task.isCompleted ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: widget.task.isCompleted
                  ? accent
                  : colors.textSecondary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: widget.task.isCompleted
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}

class _HoverAction extends StatelessWidget {
  const _HoverAction({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? activeColor : colors.textSecondary,
        ),
      ),
    );
  }
}
