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
import '../../shared/empty_state_widget.dart';
import '../../../painters/empty_state_painters.dart';
import '../shared/task_interaction_wrapper.dart';
import '../shared/custom_checkbox.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 16,
        endIndent: 16,
        color: Colors.black.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) => _CompactRow(task: tasks[index]),
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
    final priorityColor = _priorityColor(t.priority);
    final isSelected = context.watch<NavigationProvider>().selectedTaskId == t.id;

    return TaskInteractionWrapper(
      task: t,
      showHoverActions: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          color: isSelected
              ? accent.withValues(alpha: 0.08)
              : _hovered
                  ? accent.withValues(alpha: 0.03)
                  : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left priority accent bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 3,
                    decoration: BoxDecoration(
                      color: t.isCompleted
                          ? AppColors.green
                          : (t.priority != Priority.none
                              ? priorityColor
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Opacity(
                        opacity: t.isCompleted ? 0.5 : 1.0,
                        child: Row(
                          children: [
                            // Checkbox
                            CustomCheckbox(
                              value: t.isCompleted,
                              onChanged: (val) =>
                                  context.read<TaskProvider>().toggleComplete(t.id),
                              activeColor: accent,
                              size: 16,
                            ),
                            const SizedBox(width: 10),

                            // Title + metadata
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Title
                                  Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySemibold.copyWith(
                                      fontSize: 13.5,
                                      color: isOverdue
                                          ? AppColors.red
                                          : colors.textPrimary,
                                      decoration: t.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: colors.textTertiary,
                                    ),
                                  ),
                                  // Metadata row
                                  if (_hasMetadata(t)) ...[
                                    const SizedBox(height: 3),
                                    _MetadataRow(task: t),
                                  ],
                                ],
                              ),
                            ),

                            // Right-side indicators
                            if (t.isFlagged)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  PhosphorIcons.flag(PhosphorIconsStyle.fill),
                                  size: 13,
                                  color: AppColors.orange,
                                ),
                              ),
                            if (isOverdue && t.dueDate != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                          ],
                        ),
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

  bool _hasMetadata(Task t) =>
      t.dueDate != null || t.subtasks.isNotEmpty || t.tags.isNotEmpty;

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.none:
        return Colors.transparent;
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
}

class _MetadataRow extends StatelessWidget {
  final Task task;
  const _MetadataRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isOverdue = task.isOverdue && !task.isCompleted;

    final items = <Widget>[];

    // Due date
    if (task.dueDate != null) {
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.calendarBlank(),
            size: 10,
            color: isOverdue ? AppColors.red : colors.textTertiary,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              AppDateUtils.formatDueDate(task.dueDate!, task.dueHour, task.dueMinute),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: isOverdue ? AppColors.red : colors.textTertiary,
                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ));
    }

    // Subtask count
    if (task.subtasks.isNotEmpty) {
      final completed = task.subtasks.where((s) => s.isCompleted).length;
      if (items.isNotEmpty) items.add(_dot(colors));
      items.add(Text(
        '$completed/${task.subtasks.length}',
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          color: colors.textTertiary,
        ),
      ));
    }

    // Tags
    if (task.tags.isNotEmpty) {
      if (items.isNotEmpty) items.add(_dot(colors));
      final tagName =
          context.read<TagProvider>().getById(task.tags.first)?.name ?? 'Tag';
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '#$tagName',
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.indigo,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }

  Widget _dot(AppColorsExtension colors) {
    return Text(
      '·',
      style: AppTypography.caption.copyWith(
        fontSize: 10,
        color: colors.textQuaternary,
      ),
    );
  }
}
