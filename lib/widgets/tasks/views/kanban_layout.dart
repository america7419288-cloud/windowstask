import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';

enum KanbanColumn { todo, inProgress, done }

class KanbanLayout extends StatelessWidget {
  final List<Task> tasks;
  const KanbanLayout({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final todo = tasks.where((t) => !t.isCompleted && t.status == TaskStatus.todo).toList();
    final inProgress = tasks.where((t) => !t.isCompleted && t.status == TaskStatus.inProgress).toList();
    final done = tasks.where((t) => t.isCompleted || t.status == TaskStatus.done).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumnWidget(
            column: KanbanColumn.todo,
            tasks: todo,
            allTasks: tasks,
          ),
          const SizedBox(width: 12),
          _KanbanColumnWidget(
            column: KanbanColumn.inProgress,
            tasks: inProgress,
            allTasks: tasks,
          ),
          const SizedBox(width: 12),
          _KanbanColumnWidget(
            column: KanbanColumn.done,
            tasks: done,
            allTasks: tasks,
          ),
        ],
      ),
    );
  }
}

class _KanbanColumnWidget extends StatefulWidget {
  final KanbanColumn column;
  final List<Task> tasks;
  final List<Task> allTasks;

  const _KanbanColumnWidget({
    required this.column,
    required this.tasks,
    required this.allTasks,
  });

  @override
  State<_KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends State<_KanbanColumnWidget> {
  bool _isDragOver = false;
  bool _isAdding = false;
  final TextEditingController _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _submitNewTask(BuildContext context, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      setState(() => _isAdding = false);
      return;
    }
    final tp = context.read<TaskProvider>();
    TaskStatus initialStatus;
    switch (widget.column) {
      case KanbanColumn.todo:       initialStatus = TaskStatus.todo; break;
      case KanbanColumn.inProgress: initialStatus = TaskStatus.inProgress; break;
      case KanbanColumn.done:       initialStatus = TaskStatus.done; break;
    }
    tp.createTask(title: trimmed).then((task) {
      if (initialStatus != TaskStatus.todo) {
        tp.updateTaskStatus(task.id, initialStatus);
      }
    });
    setState(() {
      _isAdding = false;
      _addController.clear();
    });
  }

  String get _title {
    switch (widget.column) {
      case KanbanColumn.todo:       return 'TO DO';
      case KanbanColumn.inProgress: return 'IN PROGRESS';
      case KanbanColumn.done:       return 'DONE';
    }
  }

  Color get _statusColor {
    switch (widget.column) {
      case KanbanColumn.todo:       return AppColors.orange;
      case KanbanColumn.inProgress: return AppColors.blue;
      case KanbanColumn.done:       return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        final taskId = details.data;
        final tp = context.read<TaskProvider>();
        switch (widget.column) {
          case KanbanColumn.todo:
            tp.updateTaskStatus(taskId, TaskStatus.todo);
            break;
          case KanbanColumn.inProgress:
            tp.updateTaskStatus(taskId, TaskStatus.inProgress);
            break;
          case KanbanColumn.done:
            tp.toggleComplete(taskId);
            break;
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 280,
          decoration: BoxDecoration(
            color: _isDragOver
                ? accent.withOpacity(0.06)
                : (colors.isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragOver ? accent.withOpacity(0.4) : colors.border,
              width: _isDragOver ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              // Column header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _title,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.tasks.length}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Cards list
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    children: widget.tasks
                        .map((t) => _KanbanCard(task: t))
                        .toList(),
                  ),
                ),
              ),
              // Add task footer
              if (_isAdding)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addController,
                            autofocus: true,
                            style: TextStyle(fontSize: 13, color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Task title...',
                              hintStyle: TextStyle(color: colors.textSecondary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onSubmitted: (value) => _submitNewTask(context, value),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isAdding = false),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.close, size: 14, color: colors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isAdding = true;
                      _addController.clear();
                    }),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border, width: 0.5),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 14, color: colors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              'Add task',
                              style: AppTypography.caption.copyWith(
                                color: colors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatefulWidget {
  final Task task;
  const _KanbanCard({required this.task});

  @override
  State<_KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<_KanbanCard> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final t = widget.task;
    final isDark = colors.isDark;
    final isOverdue = t.isOverdue && !t.isCompleted;
    final nav = context.read<NavigationProvider>();

    final priorityColor = _priorityColor(t.priority);
    final completedCount = t.subtasks.where((s) => s.isCompleted).length;
    final totalSubtasks = t.subtasks.length;

    final bgGradient = isDark ? AppColors.cardGradientDark() : AppColors.cardGradientLight();

    return LongPressDraggable<String>(
      data: t.id,
      onDragStarted: () => setState(() => _dragging = true),
      onDragEnd: (_) => setState(() => _dragging = false),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: 256,
            child: _buildCardContent(context, t, colors, accent, isDark, isOverdue, priorityColor,
                completedCount, totalSubtasks, bgGradient),
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => nav.selectTask(t.id),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _dragging ? 0.3 : 1.0,
          child: _buildCardContent(context, t, colors, accent, isDark, isOverdue, priorityColor,
              completedCount, totalSubtasks, bgGradient),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    Task t,
    AppColorsExtension colors,
    Color accent,
    bool isDark,
    bool isOverdue,
    Color priorityColor,
    int completedCount,
    int totalSubtasks,
    Gradient bgGradient,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.5),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Container(width: 3, color: priorityColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isOverdue ? AppColors.red : colors.textPrimary,
                      ),
                    ),
                    if (t.dueDate != null || t.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
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
                          const Spacer(),
                          ...t.tags.take(2).map((tag) => Container(
                            margin: const EdgeInsets.only(left: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.textTertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '#$tag',
                              style: AppTypography.caption.copyWith(
                                  fontSize: 10, color: colors.textTertiary),
                            ),
                          )),
                        ],
                      ),
                    ],
                    if (totalSubtasks > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completedCount / totalSubtasks,
                          minHeight: 3,
                          backgroundColor: colors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ],
                ),
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
      case Priority.urgent:  return AppColors.pinkRed;
    }
  }
}
