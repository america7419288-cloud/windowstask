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
import '../shared/sticker_badge.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
          _KanbanColumnWidget(column: KanbanColumn.todo, tasks: todo, allTasks: tasks),
          const SizedBox(width: 12),
          _KanbanColumnWidget(column: KanbanColumn.inProgress, tasks: inProgress, allTasks: tasks),
          const SizedBox(width: 12),
          _KanbanColumnWidget(column: KanbanColumn.done, tasks: done, allTasks: tasks),
        ],
      ),
    );
  }
}

// ─── Column ──────────────────────────────────────────────────────────

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
      case KanbanColumn.todo:       return 'To Do';
      case KanbanColumn.inProgress: return 'In Progress';
      case KanbanColumn.done:       return 'Done';
    }
  }

  Color get _statusColor {
    switch (widget.column) {
      case KanbanColumn.todo:       return AppColors.blue;
      case KanbanColumn.inProgress: return AppColors.orange;
      case KanbanColumn.done:       return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = colors.isDark;

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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 120,
          ),
          decoration: BoxDecoration(
            color: _isDragOver
                ? accent.withValues(alpha: 0.06)
                : (isDark ? Colors.white.withValues(alpha: 0.025) : Colors.black.withValues(alpha: 0.018)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isDragOver ? accent.withValues(alpha: 0.4) : colors.border,
              width: _isDragOver ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Column Header ──
              _buildHeader(colors),
              // ── Cards ──
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
              // ── Add task ──
              _buildAddTaskArea(colors, accent),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _title,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Count badge
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: colors.isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.tasks.length}',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskArea(AppColorsExtension colors, Color accent) {
    if (_isAdding) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: colors.isDark ? const Color(0xFF1E1E20) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent, width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(PhosphorIcons.plus(), size: 14, color: accent),
              ),
              Expanded(
                child: TextField(
                  controller: _addController,
                  autofocus: true,
                  style: AppTypography.body.copyWith(fontSize: 13, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Task title...',
                    hintStyle: AppTypography.body.copyWith(fontSize: 13, color: colors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    isDense: true,
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
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _isAdding = true;
          _addController.clear();
        }),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.plus(), size: 12, color: colors.textTertiary),
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
    );
  }
}

// ─── Kanban Card ─────────────────────────────────────────────────────

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
    final priorityColor = _priorityColor(t.priority);
    final completedCount = t.subtasks.where((s) => s.isCompleted).length;
    final totalSubtasks = t.subtasks.length;

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
            child: _cardBody(context, t, colors, accent, isDark, isOverdue,
                priorityColor, completedCount, totalSubtasks),
          ),
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _dragging ? 0.3 : 1.0,
        child: _cardBody(context, t, colors, accent, isDark, isOverdue,
            priorityColor, completedCount, totalSubtasks),
      ),
    );
  }

  Widget _cardBody(
    BuildContext context,
    Task t,
    AppColorsExtension colors,
    Color accent,
    bool isDark,
    bool isOverdue,
    Color priorityColor,
    int completedCount,
    int totalSubtasks,
  ) {
    return TaskInteractionWrapper(
      task: t,
      actionsPosition: HoverActionsPosition.topRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: t.isCompleted
              ? (isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF9F9FB))
              : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13.5),
              child: Opacity(
                opacity: t.isCompleted ? 0.45 : 1.0,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Priority bar
                  if (t.priority != Priority.none)
                    Container(width: 3, color: priorityColor),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            t.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySemibold.copyWith(
                              fontSize: 13,
                              color: isOverdue ? AppColors.red : colors.textPrimary,
                              decoration: t.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.textTertiary,
                            ),
                          ),

                          // Description
                          if (t.description != null && t.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              t.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: colors.textTertiary,
                              ),
                            ),
                          ],

                          // Subtask progress
                          if (totalSubtasks > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: completedCount / totalSubtasks,
                                      minHeight: 4,
                                      backgroundColor: colors.divider,
                                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$completedCount/$totalSubtasks',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    color: colors.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Footer: date + tag
                          if (t.dueDate != null || t.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (t.dueDate != null)
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          PhosphorIcons.calendarBlank(),
                                          size: 10,
                                          color: isOverdue
                                              ? AppColors.red
                                              : colors.textTertiary,
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            AppDateUtils.formatDueDate(
                                                t.dueDate!, t.dueHour, t.dueMinute),
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 11,
                                              color: isOverdue
                                                  ? AppColors.red
                                                  : colors.textTertiary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const Spacer(),
                                if (t.tags.isNotEmpty)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.indigo.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '#${context.read<TagProvider>().getById(t.tags.first)?.name ?? 'Tag'}',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 10,
                                          color: AppColors.indigo,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],

                          // Flag indicator
                          if (t.isFlagged) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.flag(PhosphorIconsStyle.fill),
                                  size: 11,
                                  color: AppColors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Flagged',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
        ),

    ]),));
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.none:   return Colors.transparent;
      case Priority.low:    return AppColors.green;
      case Priority.medium: return AppColors.orange;
      case Priority.high:   return AppColors.red;
      case Priority.urgent: return AppColors.pink;
    }
  }
}
