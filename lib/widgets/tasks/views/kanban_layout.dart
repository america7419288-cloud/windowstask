import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../../providers/celebration_provider.dart'; // Added this import
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';
import '../shared/card_helpers.dart';
import '../../shared/sticker_widget.dart';
import '../../shared/deco_sticker.dart';
import '../../../data/app_stickers.dart';
import '../../../data/sticker_packs.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/sticker.dart';
import '../../../services/store_service.dart';

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
    final todo = tasks.where((t) => !t.isCompleted && t.status == TaskStatus.todo).toList();
    final inProgress = tasks.where((t) => !t.isCompleted && t.status == TaskStatus.inProgress).toList();
    final done = tasks.where((t) => t.isCompleted || t.status == TaskStatus.done).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: physics,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumnWidget(column: KanbanColumn.todo, tasks: todo, allTasks: tasks, shrinkWrap: shrinkWrap),
          const SizedBox(width: 12),
          _KanbanColumnWidget(column: KanbanColumn.inProgress, tasks: inProgress, allTasks: tasks, shrinkWrap: shrinkWrap),
          const SizedBox(width: 12),
          _KanbanColumnWidget(column: KanbanColumn.done, tasks: done, allTasks: tasks, shrinkWrap: shrinkWrap),
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
  final bool shrinkWrap;

  const _KanbanColumnWidget({
    required this.column,
    required this.tasks,
    required this.allTasks,
    this.shrinkWrap = false,
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

  Color get _columnColor {
    switch (widget.column) {
      case KanbanColumn.todo:       return const Color(0xFF6366F1);
      case KanbanColumn.inProgress: return const Color(0xFFF59E0B);
      case KanbanColumn.done:       return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final columnColor = _columnColor;

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: columnColor.withValues(alpha: colors.isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildHeader(colors),
          if (widget.shrinkWrap)
            widget.tasks.isEmpty && !_isAdding
                ? _buildEmptyState(colors)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    itemCount: widget.tasks.length,
                    itemBuilder: (context, index) => _KanbanCard(task: widget.tasks[index]),
                  )
          else
            Expanded(
              child: widget.tasks.isEmpty && !_isAdding
                  ? _buildEmptyState(colors)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      itemCount: widget.tasks.length,
                      itemBuilder: (context, index) => _KanbanCard(task: widget.tasks[index]),
                    ),
            ),
          _buildAddTaskArea(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension colors) {
    final color = _columnColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(_title.toUpperCase(),
            style: AppTypography.micro.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: color,
            )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: colors.isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${widget.tasks.length}',
              style: AppTypography.micro.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              )),
          ),
          const Spacer(),
          Icon(Icons.more_horiz, size: 16, color: colors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoSticker(
            sticker: AppStickers.allTasksEmpty,
            size: 56,
            animate: true,
          ),
          const SizedBox(height: 10),
          Text('No tasks',
            style: AppTypography.caption.copyWith(
              color: colors.textTertiary,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }

  Widget _buildAddTaskArea(AppColorsExtension colors) {
    if (_isAdding) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: CardDesign.background(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _columnColor, width: 1.5),
          ),
          child: TextField(
            controller: _addController,
            autofocus: true,
            style: AppTypography.body.copyWith(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Add task...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onSubmitted: (value) => _submitNewTask(context, value),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () => setState(() => _isAdding = true),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 16, color: colors.textSecondary),
                const SizedBox(width: 6),
                Text('Add task',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  )),
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

  Color _columnColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:       return const Color(0xFF6366F1);
      case TaskStatus.inProgress: return const Color(0xFFF59E0B);
      case TaskStatus.done:       return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();
    final isSelected = nav.selectedTaskId == t.id || nav.isTaskSelected(t.id);

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
            child: _buildCardContent(context, colors, isSelected),
          ),
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _dragging ? 0.3 : 1.0,
        child: GestureDetector(
          onTap: () {
            if (nav.isSelectionMode) {
              nav.toggleTaskSelection(t.id);
            } else {
              nav.selectTask(t.id);
            }
          },
          onLongPress: () => nav.enterSelectionMode(t.id),
          child: _buildCardContent(context, colors, isSelected),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, AppColorsExtension colors, bool isSelected) {
    final t = widget.task;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CardDesign.background(context),
        borderRadius: BorderRadius.circular(CardDesign.radius),
        border: Border.all(
          color: isSelected ? accent : colors.border,
          width: isSelected ? 1.5 : 0.75,
        ),
        boxShadow: CardDesign.shadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CardDesign.radius - 0.75), // account for border width
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // STATUS BORDER
              Container(
                width: 3,
                color: _columnColor(t.status),
              ),
              // CONTENT
              Expanded(
                child: Column(
                  children: [
            // TOP ROW — sticker + title
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sticker — prominent, left-aligned
                  if (t.stickerId != null && t.stickerId!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 10, top: 2),
                      child: Consumer<StoreService>(
                        builder: (context, store, _) {
                          final serverSticker = store.data?.stickerById(t.stickerId!);
                          final localSticker = StickerRegistry.findById(t.stickerId!);
                          return StickerWidget(
                            serverSticker: serverSticker,
                            localSticker: localSticker ?? AppStickers.detailDefault,
                            size: 48,
                            animate: true,
                          );
                        },
                      ),
                    ),

                  // Title + priority
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySemibold.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: t.isCompleted ? colors.textTertiary : colors.textPrimary,
                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                          )),
                        const SizedBox(height: 5),
                        // Priority badge
                        if (t.priority != Priority.none)
                          PriorityBadgeInline(priority: t.priority),
                      ],
                    ),
                  ),

                  // Flag
                  if (t.isFlagged)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.bookmark_rounded, size: 13, color: AppColors.orange),
                    ),
                ],
              ),
            ),

            // SUBTASKS SECTION
            if (t.subtasks.isNotEmpty) ...[
              const DashedDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Column(children: [
                  ...t.subtasks.take(2).map((sub) => InlineSubtaskRow(sub: sub, taskId: t.id)),
                  if (t.subtasks.length > 2)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, left: 18),
                        child: Text(
                          '+${t.subtasks.length - 2} more',
                          style: AppTypography.micro.copyWith(
                            fontSize: 10,
                            color: accent.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          )),
                      ),
                    ),
                ]),
              ),
            ],

            // NOTE PREVIEW
            if (t.description.isNotEmpty) ...[
              const DashedDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                child: Row(children: [
                  Icon(Icons.notes_rounded, size: 11, color: colors.textTertiary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      t.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: colors.textTertiary,
                        height: 1.4,
                      )),
                  ),
                ]),
              ),
            ],

            // FOOTER
            Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.divider, width: 0.5)),
              ),
              child: Row(children: [
                // Tags
                ...t.tags.take(2).map((tagId) {
                  final tag = context.read<TagProvider>().getById(tagId);
                  if (tag == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CardTagPill(tagName: tag.name),
                  );
                }),
                if (t.tags.length > 2)
                   CardTagPill(tagName: '+${t.tags.length - 2}'),
                const Spacer(),
                // Due date
                if (t.dueDate != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.schedule_rounded,
                        size: 10,
                        color: t.isOverdue && !t.isCompleted ? AppColors.red : colors.textQuaternary),
                    const SizedBox(width: 3),
                    Text(
                      AppDateUtils.formatShortDate(t.dueDate!),
                      style: AppTypography.micro.copyWith(
                        fontSize: 10,
                        color: t.isOverdue && !t.isCompleted ? AppColors.red : colors.textQuaternary,
                      )),
                  ]),
              ]),
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
}
