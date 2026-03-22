import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/attachment.dart';
import '../providers/task_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/list_provider.dart';
import '../providers/celebration_provider.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/date_utils.dart';
import '../models/sticker.dart';
import '../data/sticker_packs.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/deco_sticker.dart';
import '../widgets/tasks/save_template_dialog.dart';
import '../widgets/shared/sticker_picker.dart';
import '../widgets/shared/recurrence_picker.dart';
import '../models/recurrence.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../providers/focus_provider.dart';
import 'dart:convert';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _subtaskCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _subtaskCtrl = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant TaskDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _titleCtrl.text = widget.task.title;
      _descCtrl.text = widget.task.description;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subtaskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final task = context.watch<TaskProvider>().getById(widget.task.id) ?? widget.task;
    final taskProvider = context.read<TaskProvider>();
    final listProvider = context.read<ListProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, task, listProvider),
          const SizedBox(height: 24),
          // Two columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left 65%
                Expanded(
                  flex: 65,
                  child: _buildLeftColumn(context, task, taskProvider, colors),
                ),
                const SizedBox(width: 24),
                // Right 35%
                Expanded(
                  flex: 35,
                  child: _buildRightColumn(context, task, taskProvider, listProvider, colors),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Task task, ListProvider listProvider) {
    final colors = context.appColors;
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final popped = await Navigator.maybePop(context);
            if (!popped && context.mounted) {
              context.read<NavigationProvider>().closeDetail();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18, color: colors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _breadcrumb(task, listProvider),
          style: AppTypography.labelMedium.copyWith(
            color: colors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        _ToolbarIcon(
          icon: Icons.content_copy_outlined,
          tooltip: 'Duplicate',
          onTap: () {
            context.read<TaskProvider>().duplicateTask(task.id);
            context.read<NavigationProvider>().closeDetail();
          },
        ),
        _ToolbarIcon(
          icon: Icons.delete_outline,
          tooltip: 'Delete',
          color: AppColors.error,
          onTap: () {
            context.read<TaskProvider>().moveToTrash(task.id);
            context.read<NavigationProvider>().closeDetail();
          },
        ),
      ],
    );
  }

  String _breadcrumb(Task task, ListProvider lists) {
    if (task.listId != null) {
      final list = lists.getById(task.listId!);
      if (list != null) return list.name.toUpperCase();
    }
    return 'INBOX';
  }

  // ── LEFT COLUMN ──────────────────────────────────────────────────────
  Widget _buildLeftColumn(
    BuildContext context, Task task, TaskProvider taskProvider, AppColorsExtension colors,
  ) {
    final doneCount = task.subtasks.where((s) => s.isCompleted).length;
    final totalCount = task.subtasks.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // 0. Sticker Hero
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 80, height: 80,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.getPriorityColor(task.priority).withValues(alpha: 0.15),
                  AppColors.getPriorityColor(task.priority).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final newId = await StickerPicker.show(
                    context,
                    currentStickerId: task.stickerId,
                  );
                  if (newId != null) {
                    await taskProvider.updateTask(task.copyWith(
                      stickerId: newId,
                      updatedAt: DateTime.now(),
                    ));
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: DecoSticker(
                    sticker: task.stickerId != null && task.stickerId!.isNotEmpty
                      ? (StickerRegistry.findById(task.stickerId!) ?? AppStickers.detailDefault)
                      : AppStickers.detailDefault,
                    size: 56,
                    animate: true,
                  ),
                ),
              ),
            ),
          ),
        ),
        // 1. Title
        TextField(
          controller: _titleCtrl,
          style: AppTypography.displayMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: null,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Task title...',
            hintStyle: AppTypography.displayMedium.copyWith(
              color: colors.textTertiary,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) => taskProvider.updateTitle(task.id, v),
        ),
        const SizedBox(height: 24),

        // 2. Description section
            Text(
              'DESCRIPTION',
              style: AppTypography.labelSmall.copyWith(
                color: colors.textTertiary,
                letterSpacing: 2,
              ),
            ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: TextField(
            controller: _descCtrl,
            maxLines: null,
            minLines: 5,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Add description...',
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: colors.textTertiary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) => taskProvider.updateDescription(task.id, v),
          ),
        ),
        const SizedBox(height: 28),

        // 3. Subtasks
        Row(
          children: [
            Text(
              'SUBTASKS',
              style: AppTypography.labelSmall.copyWith(
                color: colors.textTertiary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 10),
            if (totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$doneCount/$totalCount Done',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...task.subtasks.map((sub) => _SubtaskRow(
          subtask: sub,
          taskId: task.id,
        )),
        // Add subtask input
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _subtaskCtrl,
                  style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a subtask...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: colors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      taskProvider.addSubtask(task.id, v.trim());
                      _subtaskCtrl.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 4. Attachments
        Row(
          children: [
            Text(
              'ATTACHMENTS',
              style: AppTypography.labelSmall.copyWith(
                color: colors.textTertiary,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _addAttachment(context, task, taskProvider),
              child: Text(
                'ADD',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (task.attachments.isNotEmpty) ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: task.attachments.map((path) {
              final name = path.split('/').last.split('\\').last;
              final ext = name.contains('.') ? name.split('.').last : '';
              final type = TaskAttachment.typeFromExtension(ext);
              return _AttachmentTile(
                fileName: name,
                isImage: type == AttachmentType.image,
              );
            }).toList(),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No attachments yet',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ),
      ],
    );
  }

  Future<void> _addAttachment(BuildContext context, Task task, TaskProvider tp) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    final paths = result.paths.whereType<String>().toList();
    if (paths.isEmpty) return;
    final updated = task.copyWith(
      attachments: [...task.attachments, ...paths],
      updatedAt: DateTime.now(),
    );
    await tp.updateTask(updated);
  }

  // ── RIGHT COLUMN ─────────────────────────────────────────────────────
  Widget _buildRightColumn(
    BuildContext context, Task task, TaskProvider taskProvider,
    ListProvider listProvider, AppColorsExtension colors,
  ) {
    final listName = task.listId != null
        ? listProvider.getById(task.listId!)?.name
        : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status
              Text(
                'CURRENT STATUS',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.textTertiary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              _StatusChips(task: task),
              const SizedBox(height: 16),

              // Complete button
              GestureDetector(
                onTap: () => taskProvider.toggleComplete(
                  task.id,
                  celebration: context.read<CelebrationProvider>(),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: task.isCompleted ? null : AppColors.gradientPrimary,
                    color: task.isCompleted
                        ? (colors.isDark ? AppColors.surfaceContainerHighDk : AppColors.surfaceContainerHigh)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: task.isCompleted ? Border.all(color: colors.border.withValues(alpha: 0.5)) : null,
                  ),
                  child: Center(
                    child: Text(
                      task.isCompleted ? '✓ Completed' : 'Complete Task',
                      style: AppTypography.titleSmall.copyWith(
                        color: task.isCompleted ? colors.textSecondary : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'TASK ATTRIBUTES',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.textTertiary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),

              _AttributeRow(
                icon: Icons.calendar_today_outlined,
                label: 'Due Date',
                value: task.dueDate != null
                    ? AppDateUtils.formatDate(task.dueDate!)
                    : 'Not set',
                onTap: () => _pickDate(context, task, taskProvider),
              ),
              if (task.dueDate != null)
                _AttributeRow(
                  icon: Icons.access_time_outlined,
                  label: 'Due Time',
                  value: (task.dueHour != null && task.dueMinute != null)
                      ? AppDateUtils.formatTime(task.dueHour!, task.dueMinute!)
                      : 'Not set',
                  onTap: () => _pickTime(context, task, taskProvider),
                ),
              _AttributeRow(
                icon: Icons.notifications_outlined,
                label: 'Reminder',
                value: !task.hasReminder
                    ? 'None'
                    : (task.reminderMinutesBefore == 0
                        ? 'At time'
                        : '${task.reminderMinutesBefore} min before'),
                onTap: () => _pickReminder(context, task, taskProvider),
              ),
              _AttributeRow(
                icon: Icons.flag_outlined,
                label: 'Priority',
                value: _priorityLabel(task.priority),
                valueColor: AppColors.priorityColor(task.priority),
                onTapDown: (details) => _pickPriority(context, task, taskProvider, details),
              ),
              _AttributeRow(
                icon: Icons.folder_outlined,
                label: 'Project',
                value: listName ?? 'None',
                onTapDown: (details) => _pickList(context, task, taskProvider, listProvider, details),
              ),
              _AttributeRow(
                icon: Icons.repeat_rounded,
                label: 'Recurring',
                value: task.isRecurring ? task.recurrence?.displayLabel ?? 'Yes' : 'No',
                onTap: () async {
                  final rule = await RecurrencePicker.show(context, initial: task.recurrence);
                  if (rule != null) {
                    await taskProvider.updateTask(task.copyWith(
                      recurrenceJson: jsonEncode(rule.toJson()),
                      updatedAt: DateTime.now(),
                    ));
                  } else {
                    await taskProvider.updateTask(task.copyWith(
                      recurrenceJson: null,
                      updatedAt: DateTime.now(),
                    ));
                  }
                },
              ),
              _AttributeRow(
                icon: PhosphorIcons.flag(),
                label: 'Flagged',
                value: task.isFlagged ? 'Yes' : 'No',
                onTap: () => taskProvider.toggleFlag(task.id),
              ),

              const SizedBox(height: 20),

              // Mindful progress note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_up, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MINDFUL PROGRESS',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stay focused and complete one task at a time.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.tertiary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickReminder(BuildContext context, Task task, TaskProvider provider) async {
    final colors = context.appColors;
    final int? result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Set Reminder', style: AppTypography.titleMedium),
        backgroundColor: colors.surface,
        children: [
          _reminderOption(context, 'None', -1, !task.hasReminder),
          _reminderOption(context, 'At time of event', 0, task.hasReminder && task.reminderMinutesBefore == 0),
          _reminderOption(context, '5 minutes before', 5, task.hasReminder && task.reminderMinutesBefore == 5),
          _reminderOption(context, '15 minutes before', 15, task.hasReminder && task.reminderMinutesBefore == 15),
          _reminderOption(context, '30 minutes before', 30, task.hasReminder && task.reminderMinutesBefore == 30),
          _reminderOption(context, '1 hour before', 60, task.hasReminder && task.reminderMinutesBefore == 60),
        ],
      ),
    );

    if (result != null) {
      final updated = task.copyWith(
        hasReminder: result != -1,
        reminderMinutesBefore: result == -1 ? 0 : result,
        updatedAt: DateTime.now(),
      );
      await provider.updateTask(updated);

      if (updated.hasReminder && updated.dueDate != null) {
        // Schedule notification (if within reasonable window, NotificationService handles it)
        final minutes = updated.reminderMinutesBefore;
        final due = updated.dueDate!;
        final scheduled = DateTime(due.year, due.month, due.day, updated.dueHour ?? 9, updated.dueMinute ?? 0)
            .subtract(Duration(minutes: minutes));
        
        NotificationService.instance.scheduleTaskReminder(
          taskId: task.id,
          title: 'Reminder: ${task.title}',
          body: 'Your task is due soon!',
          scheduledTime: scheduled,
        );
      }
    }
  }

  Widget _reminderOption(BuildContext context, String label, int value, bool selected) {
    final colors = context.appColors;
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary)),
          if (selected) Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.none:   return 'None';
      case Priority.low:    return 'Low';
      case Priority.medium: return 'Medium';
      case Priority.high:   return 'High';
      case Priority.urgent: return 'Urgent';
    }
  }

  Future<void> _pickDate(BuildContext context, Task task, TaskProvider tp) async {
    final date = await showDatePicker(
      context: context,
      initialDate: task.dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      await tp.updateDueDate(task.id, date);
    }
  }

  Future<void> _pickTime(BuildContext context, Task task, TaskProvider tp) async {
    final colors = context.appColors;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: task.dueHour ?? TimeOfDay.now().hour,
        minute: task.dueMinute ?? TimeOfDay.now().minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: colors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      await tp.updateDueTime(task.id, pickedTime.hour, pickedTime.minute);
    } else if (task.dueHour != null) {
      // Allow clearing time by tapping cancel if already set? 
      // Actually, standard behavior is just stay.
      // We can add a "Clear" button in the future.
    }
  }

  void _pickPriority(BuildContext context, Task task, TaskProvider tp, TapDownDetails details) {
    final colors = context.appColors;
    final overlayState = Overlay.of(context);
    final overlay = overlayState.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<Priority>(
      context: context,
      position: position,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: Priority.values.map((p) => PopupMenuItem(
        value: p,
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AppColors.priorityColor(p),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(_priorityLabel(p), style: AppTypography.bodyMedium),
          ],
        ),
      )).toList(),
    ).then((value) {
      if (value != null) {
        tp.updatePriority(task.id, value);
      }
    });
  }

  void _pickList(BuildContext context, Task task, TaskProvider tp, ListProvider lp, TapDownDetails details) {
    final colors = context.appColors;
    final overlayState = Overlay.of(context);
    final overlay = overlayState.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String?>(
      context: context,
      position: position,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(value: '', child: Text('None', style: AppTypography.bodyMedium)),
        ...lp.lists.map((l) => PopupMenuItem(
          value: l.id,
          child: Text(l.name, style: AppTypography.bodyMedium),
        )),
      ],
    ).then((value) {
      if (value != null) {
        tp.moveToList(task.id, value.isEmpty ? null : value);
      }
    });
  }
}

// ── Toolbar Icon ─────────────────────────────────────────────────────────────
class _ToolbarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  State<_ToolbarIcon> createState() => _ToolbarIconState();
}

class _ToolbarIconState extends State<_ToolbarIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 32, height: 32,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceContainerHigh : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon, size: 16,
              color: widget.color ?? colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status Chips ─────────────────────────────────────────────────────────────
class _StatusChips extends StatelessWidget {
  final Task task;
  const _StatusChips({required this.task});

  @override
  Widget build(BuildContext context) {
    final tp = context.read<TaskProvider>();
    return Row(
      children: TaskStatus.values.map((s) {
        final isActive = task.status == s;
        return Expanded(
          child: GestureDetector(
            onTap: () => tp.updateTaskStatus(task.id, s),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isActive ? null : Border.all(
                  color: AppColors.outlineVariant,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _statusLabel(s),
                  style: AppTypography.labelMedium.copyWith(
                    color: isActive ? AppColors.primary : context.appColors.textTertiary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:       return 'To Do';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.done:       return 'Done';
    }
  }
}

// ── Attribute Row ────────────────────────────────────────────────────────────
class _AttributeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final Function(TapDownDetails)? onTapDown;

  const _AttributeRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      onTapDown: onTapDown,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colors.textTertiary),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: valueColor ?? colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subtask Row ──────────────────────────────────────────────────────────────
class _SubtaskRow extends StatefulWidget {
  final Subtask subtask;
  final String taskId;
  const _SubtaskRow({required this.subtask, required this.taskId});

  @override
  State<_SubtaskRow> createState() => _SubtaskRowState();
}

class _SubtaskRowState extends State<_SubtaskRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.read<TaskProvider>().toggleSubtask(
                widget.taskId, widget.subtask.id,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  color: widget.subtask.isCompleted ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.subtask.isCompleted
                        ? accent
                        : colors.textTertiary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: widget.subtask.isCompleted
                    ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.subtask.title,
                style: AppTypography.bodyMedium.copyWith(
                  color: widget.subtask.isCompleted
                      ? colors.textTertiary
                      : colors.textPrimary,
                  decoration: widget.subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: colors.textTertiary,
                ),
              ),
            ),
            if (_hovered)
              GestureDetector(
                onTap: () => context.read<TaskProvider>().deleteSubtask(
                  widget.taskId, widget.subtask.id,
                ),
                child: Icon(Icons.close_rounded, size: 14, color: colors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Attachment Tile ──────────────────────────────────────────────────────────
class _AttachmentTile extends StatelessWidget {
  final String fileName;
  final bool isImage;

  const _AttachmentTile({required this.fileName, required this.isImage});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isImage
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.description_outlined,
              size: 16,
              color: isImage ? AppColors.primary : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
