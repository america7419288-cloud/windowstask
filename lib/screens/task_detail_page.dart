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
import '../widgets/shared/custom_switch.dart';
import '../widgets/tasks/save_template_dialog.dart';


import '../widgets/shared/sticker_widget.dart';
import '../painters/confetti_painter.dart';
import '../widgets/shared/sticker_picker.dart';
import '../widgets/shared/recurrence_picker.dart';
import '../widgets/shared/section_label.dart';
import '../models/recurrence.dart';
import '../services/notification_service.dart';
import '../services/store_service.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(


      children: [
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // HERO SECTION (140px)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.priorityColor(task.priority).withValues(alpha: 0.08),
                AppColors.priorityColor(task.priority).withValues(alpha: 0.04),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Breadcrumb (top left)
              Positioned(
                top: 16,
                left: 20,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final popped = await Navigator.maybePop(context);
                        if (!popped && context.mounted) {
                          context.read<NavigationProvider>().closeDetail();
                        }
                      },
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _breadcrumb(task, listProvider),
                      style: AppTypography.micro.copyWith(
                        color: colors.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Toolbar (top right)
              Positioned(
                top: 12,
                right: 16,
                child: Row(
                  children: [
                    _ToolbarBtn(
                      icon: Icons.content_copy_outlined,
                      tooltip: 'Duplicate',
                      onTap: () {
                        taskProvider.duplicateTask(task.id);
                        context.read<NavigationProvider>().closeDetail();
                      },
                    ),
                    const SizedBox(width: 4),
                    _ToolbarBtn(
                      icon: Icons.bookmark_add_outlined,
                      tooltip: 'Save as template',
                      onTap: () async {
                        final saved = await SaveTemplateDialog.show(context, task);
                        if (saved && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Saved as template'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    _ToolbarBtn(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete',
                      color: AppColors.danger,
                      onTap: () {
                        taskProvider.moveToTrash(task.id);
                        context.read<NavigationProvider>().closeDetail();
                      },
                    ),
                  ],
                ),
              ),

              // Sticker (bottom left of hero)
              Positioned(
                bottom: 16,
                left: 20,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.priorityColor(task.priority).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.shadowSM(isDark: colors.isDark),
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
                        child: task.stickerId != null && task.stickerId!.isNotEmpty
                            ? AppStickerWidget(
                                serverSticker: StoreService.instance.data?.stickerById(task.stickerId!),
                                size: 52,
                                animate: true,
                              )
                            : Text(
                                _priorityEmoji(task.priority),
                                style: const TextStyle(fontSize: 36),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // TWO COLUMN BODY (60/40)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column (60%)
              Expanded(
                flex: 60,
                child: _buildLeftColumn(context, task, taskProvider, colors),
              ),

              // Right column (40%, fixed width)
              SizedBox(
                width: 300,
                child: _buildRightColumn(context, task, taskProvider, listProvider, colors),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  String _breadcrumb(Task task, ListProvider lists) {
    if (task.listId != null) {
      final list = lists.getById(task.listId!);
      if (list != null) return list.name.toUpperCase();
    }
    return 'INBOX';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LEFT COLUMN (60%)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildLeftColumn(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
    AppColorsExtension colors,
  ) {
    final doneCount = task.subtasks.where((s) => s.isCompleted).length;
    final totalCount = task.subtasks.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        // Title
        TextField(
          controller: _titleCtrl,
          style: AppTypography.displayLG.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Task title...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) => taskProvider.updateTitle(task.id, v),
        ),
        const SizedBox(height: 20),

        // Description
        SectionLabel(text: 'Description'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _descCtrl,
            maxLines: null,
            minLines: 4,
            style: AppTypography.bodyMD.copyWith(
              color: colors.textPrimary,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Add description...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintStyle: AppTypography.bodyMD.copyWith(color: colors.textTertiary),
            ),
            onChanged: (v) => taskProvider.updateDescription(task.id, v),
          ),
        ),
        const SizedBox(height: 20),

        // Subtasks
        Row(
          children: [
            SectionLabel(text: 'Subtasks'),
            const SizedBox(width: 8),
            if (totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$doneCount/$totalCount Done',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.success,
                    letterSpacing: 0.3,
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
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _subtaskCtrl,
                  style: AppTypography.bodyMD.copyWith(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a subtask...',
                    hintStyle: AppTypography.bodyMD.copyWith(color: colors.textTertiary),
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
        const SizedBox(height: 20),

        // Attachments
        Row(
          children: [
            SectionLabel(text: 'Attachments'),
            const Spacer(),
            GestureDetector(
              onTap: () => _addAttachment(context, task, taskProvider),
              child: Text(
                'ADD',
                style: AppTypography.micro.copyWith(
                  color: AppColors.indigo,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (task.attachments.isNotEmpty)
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
          )
        else
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RIGHT COLUMN (40%)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildRightColumn(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
    ListProvider listProvider,
    AppColorsExtension colors,
  ) {
    final listName = task.listId != null ? listProvider.getById(task.listId!)?.name : null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      children: [
        // Current Status
        SectionLabel(text: 'Current Status'),
        const SizedBox(height: 8),
        _buildStatusControl(task),
        const SizedBox(height: 10),

        // Complete Button
        _CompleteButton(task: task, taskProvider: taskProvider),

        const SizedBox(height: 20),

        // Task Attributes Container
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _AttributeRow(
                icon: Icons.calendar_today_outlined,
                label: 'Due Date',
                value: task.dueDate != null ? AppDateUtils.formatDate(task.dueDate!) : 'Not set',
                onTap: () => _pickDate(context, task, taskProvider),
              ),
              _Divider(),
              _AttributeRow(
                icon: Icons.access_time_rounded,
                label: 'Due Time',
                value: (task.dueHour != null && task.dueMinute != null)
                    ? AppDateUtils.formatTime(task.dueHour!, task.dueMinute!)
                    : 'Not set',
                onTap: () => _pickTime(context, task, taskProvider),
              ),
              _Divider(),
              _AttributeRow(
                icon: Icons.notifications_outlined,
                label: 'Reminder',
                value: !task.hasReminder
                    ? 'None'
                    : (task.reminderMinutesBefore == 0 ? 'At time' : '${task.reminderMinutesBefore} min before'),
                onTap: () => _pickReminder(context, task, taskProvider),
              ),
              _Divider(),
              _AttributeRow(
                icon: Icons.flag_outlined,
                label: 'Priority',
                value: _priorityLabel(task.priority),
                valueColor: AppColors.priorityColor(task.priority),
                onTapDown: (details) => _pickPriority(context, task, taskProvider, details),
              ),
              _Divider(),
              _AttributeRow(
                icon: Icons.folder_outlined,
                label: 'Project',
                value: listName ?? 'None',
                onTapDown: (details) => _pickList(context, task, taskProvider, listProvider, details),
              ),
              _Divider(),
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
              _Divider(),
              // Flagged Switch
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_outlined, size: 16, color: colors.textTertiary),
                    const SizedBox(width: 12),
                    Text(
                      'Flagged',
                      style: AppTypography.bodyMD.copyWith(color: colors.textSecondary),
                    ),
                    const Spacer(),
                    CustomSwitch(
                      value: task.isFlagged,
                      activeColor: AppColors.gold,
                      onChanged: (_) => taskProvider.toggleFlag(task.id),
                    ),




                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Mindful Progress
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MINDFUL PROGRESS',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.success,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stay focused and complete one task at a time.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success.withValues(alpha: 0.8),
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PICKER METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
            colorScheme: Theme.of(context).colorScheme.copyWith(surface: colors.surface),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      await tp.updateDueTime(task.id, pickedTime.hour, pickedTime.minute);
    }
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
          Text(label, style: AppTypography.bodyMD.copyWith(color: colors.textPrimary)),
          if (selected) Icon(Icons.check_rounded, size: 18, color: AppColors.indigo),
        ],
      ),
    );
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.none:
        return 'None';
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
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
      items: Priority.values
          .map((p) => PopupMenuItem(
                value: p,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.priorityColor(p),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_priorityLabel(p), style: AppTypography.bodyMD),
                  ],
                ),
              ))
          .toList(),
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
        PopupMenuItem(value: '', child: Text('None', style: AppTypography.bodyMD)),
        ...lp.lists.map((l) => PopupMenuItem(
              value: l.id,
              child: Text(l.name, style: AppTypography.bodyMD),
            )),
      ],
    ).then((value) {
      if (value != null) {
        tp.moveToList(task.id, value.isEmpty ? null : value);
      }
    });
  }

  Widget _buildStatusControl(Task task) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _StatusTab(
            label: 'To Do',
            isActive: !task.isCompleted && task.status != TaskStatus.inProgress,
            onTap: () => context.read<TaskProvider>().updateTaskStatus(task.id, TaskStatus.todo),
          ),
          _StatusTab(
            label: 'In Progress',
            isActive: task.status == TaskStatus.inProgress,
            onTap: () => context.read<TaskProvider>().updateTaskStatus(task.id, TaskStatus.inProgress),
          ),
          _StatusTab(
            label: 'Done',
            isActive: task.isCompleted,
            onTap: () => context.read<TaskProvider>().toggleComplete(task.id),
          ),
        ],
      ),
    );
  }

  String _priorityEmoji(Priority p) {
    switch (p) {
      case Priority.urgent:
        return '🔥';
      case Priority.high:
        return '⚡';
      case Priority.medium:
        return '📌';
      case Priority.low:
        return '🌿';
      default:
        return '📋';
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATUS TAB
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StatusTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? context.appColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive ? AppColors.shadowSM(isDark: context.appColors.isDark) : [],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelMD.copyWith(
                color: isActive ? AppColors.indigo : context.appColors.textTertiary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TOOLBAR BUTTON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ToolbarBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ToolbarBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  State<_ToolbarBtn> createState() => _ToolbarBtnState();
}

class _ToolbarBtnState extends State<_ToolbarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget w = GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? colors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, size: 16, color: widget.color ?? colors.textSecondary),
        ),
      ),
    );
    return Tooltip(message: widget.tooltip, child: w);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPLETE BUTTON (Pill-style)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _CompleteButton extends StatelessWidget {
  final Task task;
  final TaskProvider taskProvider;

  const _CompleteButton({required this.task, required this.taskProvider});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, tasks, _) {
        final currentTask = tasks.getById(task.id) ?? task;
        return GestureDetector(
          onTap: () => taskProvider.toggleComplete(
            task.id,
            celebration: context.read<CelebrationProvider>(),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: currentTask.isCompleted ? AppColors.success.withValues(alpha: 0.10) : AppColors.indigoDim,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currentTask.isCompleted ? '✓ Done' : 'Complete',
              style: AppTypography.labelMD.copyWith(
                color: currentTask.isCompleted ? AppColors.success : AppColors.indigo,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ATTRIBUTE ROW
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 15, color: colors.textTertiary),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.bodyMD.copyWith(color: colors.textSecondary),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.bodyMD.copyWith(
                color: valueColor ?? colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 14, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DIVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Divider(
      height: 1,
      color: colors.textTertiary.withValues(alpha: 0.1),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SUBTASK ROW
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
          color: _hovered ? colors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.read<TaskProvider>().toggleSubtask(widget.taskId, widget.subtask.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.subtask.isCompleted ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.subtask.isCompleted ? accent : colors.textTertiary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: widget.subtask.isCompleted ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.subtask.title,
                style: AppTypography.bodyMD.copyWith(
                  color: widget.subtask.isCompleted ? colors.textTertiary : colors.textPrimary,
                  decoration: widget.subtask.isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: colors.textTertiary,
                ),
              ),
            ),
            if (_hovered)
              GestureDetector(
                onTap: () => context.read<TaskProvider>().deleteSubtask(widget.taskId, widget.subtask.id),
                child: Icon(Icons.close_rounded, size: 14, color: colors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ATTACHMENT TILE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isImage ? AppColors.indigo.withValues(alpha: 0.1) : AppColors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.description_outlined,
              size: 16,
              color: AppColors.indigo,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMD.copyWith(
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
