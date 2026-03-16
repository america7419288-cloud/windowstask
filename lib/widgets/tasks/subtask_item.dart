import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/subtask.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

class SubtaskItem extends StatefulWidget {
  const SubtaskItem({
    super.key,
    required this.subtask,
    required this.taskId,
    this.onDelete,
  });

  final Subtask subtask;
  final String taskId;
  final VoidCallback? onDelete;

  @override
  State<SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends State<SubtaskItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final tasks = context.read<TaskProvider>();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => tasks.toggleSubtask(widget.taskId, widget.subtask.id),
              child: AnimatedContainer(
                duration: AppConstants.animFast,
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.subtask.isCompleted ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.subtask.isCompleted
                        ? accent
                        : colors.textSecondary.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: widget.subtask.isCompleted
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.subtask.title,
                style: AppTypography.body.copyWith(
                  color: widget.subtask.isCompleted
                      ? colors.textSecondary
                      : colors.textPrimary,
                  decoration: widget.subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            if (_hovered && widget.onDelete != null)
              GestureDetector(
                onTap: widget.onDelete,
                child: Icon(Icons.close, size: 14, color: colors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
