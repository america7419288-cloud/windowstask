import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';
import '../../shared/sticker_widget.dart';
import '../../../data/app_stickers.dart';
import '../../../services/store_service.dart';
import '../../shared/priority_pill.dart';
import '../../../data/sticker_packs.dart';

enum KanbanColumn { todo, inProgress, done }



class KanbanLayout extends StatelessWidget {
  final List<Task> tasks;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const KanbanLayout({
    super.key,
    required this.tasks,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final todo = tasks
        .where((t) => !t.isCompleted && t.status == TaskStatus.todo)
        .toList();
    final inProgress = tasks
        .where((t) => !t.isCompleted && t.status == TaskStatus.inProgress)
        .toList();
    final done = tasks
        .where((t) => t.isCompleted || t.status == TaskStatus.done)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: physics,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumnWidget(
            column: KanbanColumn.todo,
            tasks: todo,
            shrinkWrap: shrinkWrap,
          ),
          const SizedBox(width: 12),
          _KanbanColumnWidget(
            column: KanbanColumn.inProgress,
            tasks: inProgress,
            shrinkWrap: shrinkWrap,
          ),
          const SizedBox(width: 12),
          _KanbanColumnWidget(
            column: KanbanColumn.done,
            tasks: done,
            shrinkWrap: shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// KANBAN COLUMN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _KanbanColumnWidget extends StatefulWidget {
  final KanbanColumn column;
  final List<Task> tasks;
  final bool shrinkWrap;

  const _KanbanColumnWidget({
    required this.column,
    required this.tasks,
    this.shrinkWrap = false,
  });

  @override
  State<_KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends State<_KanbanColumnWidget> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final columnColor = _getStatusColor();

    return DragTarget<String>(
      onWillAccept: (data) => data != null,
      onAccept: (taskId) {
        final tp = context.read<TaskProvider>();
        final newStatus = _getStatusFromColumn();
        tp.updateTaskStatus(taskId, newStatus);
        setState(() => _isDragOver = false);
      },
      onMove: (_) {
        if (!_isDragOver) setState(() => _isDragOver = true);
      },
      onLeave: (_) {
        setState(() => _isDragOver = false);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          decoration: BoxDecoration(
            color: _isDragOver
                ? columnColor.withValues(
                    alpha: colors.isDark ? 0.12 : 0.08)
                : columnColor.withValues(alpha: colors.isDark ? 0.06 : 0.04),
            borderRadius: BorderRadius.circular(14),
            border: _isDragOver
                ? Border.all(
                    color: columnColor.withValues(alpha: 0.3), width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              _buildHeader(columnColor, colors),
              if (widget.shrinkWrap)
                widget.tasks.isEmpty
                    ? const SizedBox(height: 40)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        itemCount: widget.tasks.length,
                        itemBuilder: (context, index) =>
                            _KanbanCard(task: widget.tasks[index]),
                      )
              else
                Expanded(
                  child: widget.tasks.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          itemCount: widget.tasks.length,
                          itemBuilder: (context, index) =>
                              _KanbanCard(task: widget.tasks[index]),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color statusColor, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),

          // Status name
          Text(
            _getTitleForColumn(),
            style: AppTypography.labelMD.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),

          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(
                  alpha: colors.isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.tasks.length}',
              style: AppTypography.micro.copyWith(
                color: statusColor,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitleForColumn() {
    switch (widget.column) {
      case KanbanColumn.todo:
        return 'To Do';
      case KanbanColumn.inProgress:
        return 'In Progress';
      case KanbanColumn.done:
        return 'Done';
    }
  }

  Color _getStatusColor() {
    switch (widget.column) {
      case KanbanColumn.todo:
        return AppColors.indigo;
      case KanbanColumn.inProgress:
        return AppColors.warning;
      case KanbanColumn.done:
        return AppColors.success;
    }
  }

  TaskStatus _getStatusFromColumn() {
    switch (widget.column) {
      case KanbanColumn.todo:
        return TaskStatus.todo;
      case KanbanColumn.inProgress:
        return TaskStatus.inProgress;
      case KanbanColumn.done:
        return TaskStatus.done;
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// KANBAN CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();

    return LongPressDraggable<String>(
      data: t.id,
      onDragStarted: () => setState(() => _dragging = true),
      onDragEnd: (_) => setState(() => _dragging = false),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: 280,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: AppColors.priorityColor(t.priority),
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                t.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSM.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
      child: Opacity(
        opacity: _dragging ? 0.3 : 1.0,
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: AppColors.priorityColor(t.priority),
                width: 3,
              ),
            ),
            boxShadow: AppColors.shadowSM(isDark: colors.isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticker + title row
              Row(
                children: [
                  if (t.stickerId != null && t.stickerId!.isNotEmpty) ...[
                    AppStickerWidget(
                      serverSticker: StoreService.instance.data?.stickerById(t.stickerId!),
                      localSticker: StickerRegistry.findById(t.stickerId!),
                      size: 36,
                      animate: true,
                    ),
                    const SizedBox(width: 8),
                  ],


                  Expanded(
                    child: Text(
                      t.title,
                      style: AppTypography.titleSM.copyWith(
                        color: colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Footer: date + priority
              if (t.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: _dateLabel(t.dueDate!),
                        isOverdue: _isOverdue(t),
                      ),
                      const Spacer(),
                      PriorityPill(priority: t.priority),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    if (AppDateUtils.isToday(date)) return 'Today';
    if (AppDateUtils.isTomorrow(date)) return 'Tomorrow';
    return AppDateUtils.formatDate(date);
  }

  bool _isOverdue(Task t) {
    if (t.dueDate == null || t.isCompleted) return false;
    return t.dueDate!.isBefore(DateTime.now());
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// META CHIP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOverdue;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(
          icon,
          size: 10,
          color: isOverdue ? AppColors.danger : colors.textTertiary,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isOverdue ? AppColors.danger : colors.textTertiary,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
