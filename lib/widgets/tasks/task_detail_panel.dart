import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/focus_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../shared/priority_badge.dart';
import '../shared/tag_chip.dart';
import '../shared/date_picker_popover.dart';
import 'subtask_item.dart';

class TaskDetailPanel extends StatefulWidget {
  const TaskDetailPanel({super.key, required this.task});
  final Task task;

  @override
  State<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends State<TaskDetailPanel> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subtaskController;
  late Task _task;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController = TextEditingController(text: _task.title);
    _descController = TextEditingController(text: _task.description);
    _subtaskController = TextEditingController();
  }

  @override
  void didUpdateWidget(TaskDetailPanel old) {
    super.didUpdateWidget(old);
    if (old.task.id != widget.task.id) {
      _task = widget.task;
      _titleController.text = _task.title;
      _descController.text = _task.description;
    } else {
      _task = widget.task;
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _save() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final tasks = context.read<TaskProvider>();
      final updated = _task.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text,
        updatedAt: DateTime.now(),
      );
      tasks.updateTask(updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.read<NavigationProvider>();

    return Container(
      width: AppConstants.detailPanelWidth,
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(colors.isDark ? 0.85 : 0.72),
        border: Border(left: BorderSide(color: colors.divider)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // Panel header
              _PanelHeader(
                task: _task,
                onClose: () => nav.closeDetailPanel(),
                onDelete: () {
                  context.read<TaskProvider>().moveToTrash(_task.id);
                  nav.closeDetailPanel();
                },
                onDuplicate: () {
                  context.read<TaskProvider>().duplicateTask(_task.id);
                  nav.closeDetailPanel();
                },
                onStartFocus: () {
                  context.read<FocusProvider>().startFocus(
                    taskId: _task.id,
                    taskTitle: _task.title,
                    durationMinutes: context.read<SettingsProvider>().focusDuration,
                  );
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextField(
                        controller: _titleController,
                        style: AppTypography.headline.copyWith(color: colors.textPrimary),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Task title',
                          hintStyle: AppTypography.headline.copyWith(color: colors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => _save(),
                      ),
                      const SizedBox(height: 8),
                      // Complete toggle
                      _DetailRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: _task.isCompleted ? 'Completed' : 'Mark as complete',
                        trailing: Switch(
                          value: _task.isCompleted,
                          onChanged: (v) {
                            context.read<TaskProvider>().toggleComplete(_task.id);
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Divider(height: 1, color: colors.divider),
                      // Priority
                      _PriorityRow(task: _task, onChanged: (p) {
                        final updated = _task.copyWith(priority: p);
                        context.read<TaskProvider>().updateTask(updated);
                      }),
                      Divider(height: 1, color: colors.divider),
                      // Due date
                      _DueDateRow(task: _task, onChanged: (date) {
                        final updated = _task.copyWith(dueDate: date);
                        context.read<TaskProvider>().updateTask(updated);
                      }, onClear: () {
                        final updated = _task.copyWith(clearDueDate: true, clearDueTime: true);
                        context.read<TaskProvider>().updateTask(updated);
                      }),
                      Divider(height: 1, color: colors.divider),
                      // Flag
                      _DetailRow(
                        icon: Icons.flag_outlined,
                        label: 'Flagged',
                        trailing: Switch(
                          value: _task.isFlagged,
                          onChanged: (v) {
                            final updated = _task.copyWith(isFlagged: v);
                            context.read<TaskProvider>().updateTask(updated);
                          },
                          activeColor: AppColors.orange,
                        ),
                      ),
                      Divider(height: 1, color: colors.divider),
                      // List
                      _ListRow(task: _task),
                      Divider(height: 1, color: colors.divider),
                      // Tags
                      _TagsRow(task: _task),
                      Divider(height: 1, color: colors.divider),
                      const SizedBox(height: 12),
                      // Description
                      Text('Notes', style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      )),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descController,
                        maxLines: null,
                        minLines: 3,
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Add notes...',
                          hintStyle: AppTypography.body.copyWith(color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                        onChanged: (_) => _save(),
                      ),
                      const SizedBox(height: 16),
                      // Subtasks
                      _SubtasksSection(task: _task, controller: _subtaskController),
                      const SizedBox(height: 24),
                      // Timestamps
                      _Timestamps(task: _task),
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
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.task,
    required this.onClose,
    required this.onDelete,
    required this.onDuplicate,
    required this.onStartFocus,
  });

  final Task task;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onStartFocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          _IconBtn(icon: Icons.close, onTap: onClose, tooltip: 'Close'),
          const Spacer(),
          _IconBtn(icon: Icons.timer_outlined, onTap: onStartFocus, tooltip: 'Start Focus'),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.copy_outlined, onTap: onDuplicate, tooltip: 'Duplicate'),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.delete_outline, onTap: onDelete, tooltip: 'Delete', danger: true),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.tooltip, this.danger = false});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget w = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Icon(
          icon,
          size: 16,
          color: danger ? AppColors.red : colors.textSecondary,
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: w) : w;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: AppTypography.body.copyWith(color: colors.textPrimary)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.task, required this.onChanged});
  final Task task;
  final ValueChanged<Priority> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 16, color: colors.textSecondary),
          const SizedBox(width: 10),
          Text('Priority', style: AppTypography.body.copyWith(color: colors.textPrimary)),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<Priority>(
              value: task.priority,
              isDense: true,
              items: Priority.values.map((p) => DropdownMenuItem(
                value: p,
                child: PriorityBadge(priority: p, showLabel: true),
              )).toList(),
              onChanged: (p) => p != null ? onChanged(p) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueDateRow extends StatelessWidget {
  const _DueDateRow({required this.task, required this.onChanged, required this.onClear});
  final Task task;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: colors.textSecondary),
          const SizedBox(width: 10),
          Text('Due Date', style: AppTypography.body.copyWith(color: colors.textPrimary)),
          const Spacer(),
          if (task.dueDate != null)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close, size: 14, color: colors.textSecondary),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final date = await DatePickerPopover.show(context, initialDate: task.dueDate);
              if (date != null) onChanged(date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: task.dueDate != null
                    ? (task.isOverdue ? AppColors.red.withOpacity(0.1) : Theme.of(context).colorScheme.primary.withOpacity(0.1))
                    : colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.dueDate != null ? AppDateUtils.formatShortDate(task.dueDate!) : 'Set date',
                style: AppTypography.caption.copyWith(
                  color: task.dueDate != null
                      ? (task.isOverdue ? AppColors.red : Theme.of(context).colorScheme.primary)
                      : colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lists = context.read<ListProvider>();
    final taskProv = context.read<TaskProvider>();
    final currentList = task.listId != null ? lists.getById(task.listId!) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.folder_outlined, size: 16, color: colors.textSecondary),
          const SizedBox(width: 10),
          Text('List', style: AppTypography.body.copyWith(color: colors.textPrimary)),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: task.listId,
              isDense: true,
              hint: Text('None', style: AppTypography.body.copyWith(color: colors.textSecondary)),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text('None', style: AppTypography.body)),
                ...lists.activeLists.map((l) => DropdownMenuItem(
                  value: l.id,
                  child: Row(
                    children: [
                      Text(l.emoji),
                      const SizedBox(width: 6),
                      Text(l.name, style: AppTypography.body),
                    ],
                  ),
                )),
              ],
              onChanged: (id) {
                final updated = task.copyWith(listId: id, clearListId: id == null);
                taskProv.updateTask(updated);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TagsRow extends StatefulWidget {
  const _TagsRow({required this.task});
  final Task task;

  @override
  State<_TagsRow> createState() => _TagsRowState();
}

class _TagsRowState extends State<_TagsRow> {
  bool _adding = false;
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tagProv = context.read<TagProvider>();
    final taskProv = context.read<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_outline, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              Text('Tags', style: AppTypography.body.copyWith(color: colors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _adding = !_adding),
                child: Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          if (widget.task.tags.isNotEmpty || _adding) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...widget.task.tags.map((tagId) {
                  final tag = tagProv.getById(tagId);
                  if (tag == null) return const SizedBox.shrink();
                  return TagChip(
                    label: tag.name,
                    colorHex: tag.colorHex,
                    onDelete: () {
                      final tags = widget.task.tags.where((t) => t != tagId).toList();
                      taskProv.updateTask(widget.task.copyWith(tags: tags));
                    },
                  );
                }),
                if (_adding)
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _tagController,
                      autofocus: true,
                      style: AppTypography.caption,
                      decoration: InputDecoration(
                        hintText: 'Tag name...',
                        hintStyle: AppTypography.caption.copyWith(color: colors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusChip),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onSubmitted: (val) async {
                        final name = val.trim();
                        if (name.isNotEmpty) {
                          final tag = await tagProv.createTag(name: name);
                          final tags = [...widget.task.tags, tag.id];
                          taskProv.updateTask(widget.task.copyWith(tags: tags));
                        }
                        setState(() {
                          _adding = false;
                          _tagController.clear();
                        });
                      },
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SubtasksSection extends StatelessWidget {
  const _SubtasksSection({required this.task, required this.controller});
  final Task task;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tasks = context.read<TaskProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Subtasks', style: AppTypography.bodySemibold.copyWith(color: colors.textPrimary)),
            const SizedBox(width: 8),
            Text(
              '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...task.subtasks.map((subtask) => SubtaskItem(
          subtask: subtask,
          taskId: task.id,
          onDelete: () => tasks.deleteSubtask(task.id, subtask.id),
        )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: AppTypography.body.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: '+ Add subtask...',
            hintStyle: AppTypography.body.copyWith(color: colors.textSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            prefixIcon: Icon(Icons.add, size: 16, color: colors.textSecondary),
            prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              tasks.addSubtask(task.id, val.trim());
              controller.clear();
            }
          },
        ),
      ],
    );
  }
}

class _Timestamps extends StatelessWidget {
  const _Timestamps({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Created ${AppDateUtils.formatRelative(task.createdAt)}',
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          'Updated ${AppDateUtils.formatRelative(task.updatedAt)}',
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
