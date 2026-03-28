import 'dart:ui';
import 'dart:async';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/task.dart';
import '../shared/custom_switch.dart';
import '../../models/app_settings.dart';
import '../shared/recurrence_picker.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/celebration_provider.dart';
import '../../providers/focus_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../shared/priority_badge.dart';
import '../shared/tag_chip.dart';
import '../shared/date_picker_popover.dart';
import 'shared/custom_checkbox.dart';
import '../shared/pressable_scale.dart';
import '../../data/sticker_packs.dart';
import '../../models/sticker.dart';
import '../../data/app_stickers.dart';
import '../shared/sticker_widget.dart';
import '../../services/store_service.dart';
import '../shared/deco_sticker.dart';
import '../shared/sticker_picker.dart';
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

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _task.dueHour ?? 9,
        minute: _task.dueMinute ?? 0,
      ),
    );
    if (picked != null) {
      context.read<TaskProvider>().updateDueTime(_task.id, picked.hour, picked.minute);
    }
  }

  Future<void> _pickRecurrence(BuildContext context) async {
    final result = await RecurrencePicker.show(
      context,
      initial: _task.recurrence,
    );
    if (mounted) {
      context.read<TaskProvider>().setRecurrence(_task.id, result);
    }
  }

  Future<void> _pickSticker(BuildContext context) async {
    final result = await StickerPicker.show(
      context,
      currentStickerId: _task.stickerId,
    );
    if (result == null) return;
    if (!context.mounted) return;
    final newId = result.isEmpty ? null : result;
    context.read<TaskProvider>().setSticker(_task.id, newId);
  }

  @override
  Widget build(BuildContext context) {


    final colors = context.appColors;
    final nav = context.read<NavigationProvider>();
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: AppConstants.detailPanelWidth,
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: colors.isDark ? 0.85 : 0.72),
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
                  onChangeSticker: () => _pickSticker(context),
                ),




              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ──
                      TextField(
                        controller: _titleController,
                        style: AppTypography.headline.copyWith(color: colors.textPrimary),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Task title',
                          hintStyle: AppTypography.headline.copyWith(color: colors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => _save(),
                      ),
                      const SizedBox(height: 16),

                      // ── Metadata Group ──
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            // Complete toggle
                            _PropertyRow(
                              label: _task.isCompleted ? 'Completed' : 'Mark complete',
                              trailing: CustomSwitch(
                                value: _task.isCompleted,
                                onChanged: (v) {
                                  context.read<TaskProvider>().toggleComplete(
                                    _task.id,
                                    celebration: context.read<CelebrationProvider>(),
                                  );
                                },
                              ),
                            ),
                            _thinDivider(colors),
                            // Priority
                            _PriorityRow(task: _task, onChanged: (p) {
                              final updated = _task.copyWith(priority: p);
                              context.read<TaskProvider>().updateTask(updated);
                            }),
                            _thinDivider(colors),
                            // Due date
                            _DueDateRow(task: _task, onChanged: (date) {
                              final updated = _task.copyWith(dueDate: date);
                              context.read<TaskProvider>().updateTask(updated);
                            }, onClear: () {
                              final updated = _task.copyWith(clearDueDate: true, clearDueTime: true);
                              context.read<TaskProvider>().updateTask(updated);
                            }),
                            _thinDivider(colors),
                            // Due time
                            if (_task.dueDate != null) ...[
                              _PropertyRow(
                                label: 'Time',
                                trailing: GestureDetector(
                                  onTap: () => _pickTime(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _task.dueHour != null
                                          ? accent.withValues(alpha: 0.08)
                                          : colors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      _task.dueHour != null
                                          ? '${_task.dueHour.toString().padLeft(2, '0')}:${(_task.dueMinute ?? 0).toString().padLeft(2, '0')}'
                                          : 'Set time',
                                      style: AppTypography.caption.copyWith(
                                        color: _task.dueHour != null ? accent : colors.textTertiary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _thinDivider(colors),
                            ],
                            // Reminder
                            if (_task.dueDate != null && _task.dueHour != null) ...[
                              _PropertyRow(
                                label: 'Reminder',
                                trailing: _ReminderPicker(task: _task),
                              ),
                              _thinDivider(colors),
                            ],
                            // Repeat
                            if (_task.dueDate != null) ...[
                              _PropertyRow(
                                label: 'Repeat',
                                trailing: GestureDetector(
                                  onTap: () => _pickRecurrence(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _task.isRecurring
                                          ? accent.withValues(alpha: 0.08)
                                          : colors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_task.isRecurring) ...[
                                          Icon(Icons.repeat_rounded, size: 12, color: accent),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          _task.recurrence?.displayLabel ?? 'Never',
                                          style: AppTypography.caption.copyWith(
                                            color: _task.isRecurring ? accent : colors.textTertiary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              _thinDivider(colors),
                            ],
                            // Flag
                            _PropertyRow(
                              label: 'Flagged',
                              trailing: CustomSwitch(
                                value: _task.isFlagged,
                                onChanged: (v) {
                                  final updated = _task.copyWith(isFlagged: v);
                                  context.read<TaskProvider>().updateTask(updated);
                                },
                              ),
                            ),
                            _thinDivider(colors),
                            // Sticker
                            _StickerRow(task: _task),
                            _thinDivider(colors),
                            // List
                            _ListRow(task: _task),
                            _thinDivider(colors),
                            // Tags
                            _TagsRow(task: _task, isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Notes ──
                      Text('Notes', style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      )),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _descController,
                          maxLines: null,
                          minLines: 6,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add notes...',
                            hintStyle: AppTypography.body.copyWith(color: colors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (_) => _save(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Subtasks ──
                      _SubtasksSection(task: _task, controller: _subtaskController),
                      const SizedBox(height: 24),

                      // ── Timestamps ──
                      _Timestamps(task: _task),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }


  Widget _thinDivider(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 0.5, thickness: 0.5, color: colors.divider),
    );
  }
}

// ─── Panel Header ────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.task,
    required this.onClose,
    required this.onDelete,
    required this.onChangeSticker,
  });

  final Task task;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onChangeSticker;

  @override
  Widget build(BuildContext context) {


    final colors = context.appColors;
    final stickerId = task.stickerId;

    return Container(
      height: 120,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          // Close button
          Positioned(
            top: 8,
            left: 8,
            child: _IconBtn(
              icon: Icons.close,
              onTap: onClose,
              color: Colors.white,
            ),
          ),
          // Delete button
          Positioned(
            top: 8,
            right: 8,
            child: _IconBtn(
              icon: Icons.delete_outline,
              onTap: onDelete,
              color: Colors.white,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: onChangeSticker,
              child: Consumer<StoreService>(
                builder: (context, store, _) {
                  final serverSticker = stickerId != null ? store.data?.stickerById(stickerId) : null;
                  final localSticker = stickerId != null ? StickerRegistry.findById(stickerId) : null;
                  
                  return StickerWidget(
                    serverSticker: serverSticker,
                    localSticker: localSticker ?? AppStickers.detailDefault,
                    size: 80,
                    animate: true,
                  );
                },
              ),
            ),
          ),
        ],


      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.tooltip, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget w = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? colors.textSecondary,
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: w) : w;
  }
}

// ─── Property Row (key-value inside grouped container) ───────────────

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label.toUpperCase(),
                style: AppTypography.sectionHeader.copyWith(
                  fontSize: 10,
                  color: colors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
            Expanded(child: trailing),
          ],
        ),
      ),
    );
  }
}

// ─── Priority Row ────────────────────────────────────────────────────

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.task, required this.onChanged});
  final Task task;
  final ValueChanged<Priority> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PropertyRow(
      label: 'Priority',
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: Priority.values.where((p) => p != Priority.none).map((p) {
            final isSelected = task.priority == p;
            final color = _priorityColor(p);
            return GestureDetector(
              onTap: () => onChanged(p),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      p.name.toUpperCase(),
                      style: AppTypography.metadata.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : context.appColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high: return AppColors.danger;
      case Priority.medium: return AppColors.warning;
      case Priority.low: return AppColors.success;
      default: return AppColors.textMuted;
    }
  }
}

// ─── Due Date Row ────────────────────────────────────────────────────

class _DueDateRow extends StatelessWidget {
  const _DueDateRow({required this.task, required this.onChanged, required this.onClear});
  final Task task;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    return _PropertyRow(
      label: 'Due Date',
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (task.dueDate != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(PhosphorIcons.x(), size: 14, color: colors.textSecondary.withValues(alpha: 0.4)),
                ),
              ),
            GestureDetector(
              onTap: () async {
                final date = await DatePickerPopover.show(context, initialDate: task.dueDate);
                if (date != null) onChanged(date);
              },
              child: Text(
                task.dueDate != null ? AppDateUtils.formatDueDate(task.dueDate!, task.dueHour, task.dueMinute) : 'Set date',
                style: AppTypography.metadata.copyWith(
                  color: task.dueDate != null ? (task.isOverdue ? AppColors.danger : accent) : colors.textSecondary.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List Row ────────────────────────────────────────────────────────

class _ListRow extends StatelessWidget {
  const _ListRow({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lists = context.read<ListProvider>();
    final taskProv = context.read<TaskProvider>();
    final currentList = task.listId != null ? lists.getById(task.listId!) : null;

    return _PropertyRow(
      label: 'List',
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: task.listId,
                isDense: true,
                icon: Icon(PhosphorIcons.caretDown(), size: 14, color: colors.textSecondary.withValues(alpha: 0.4)),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text('NONE', style: AppTypography.metadata.copyWith(fontSize: 10, fontWeight: FontWeight.w700))),
                  ...lists.activeLists.map((l) => DropdownMenuItem(
                    value: l.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.emoji, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(l.name.toUpperCase(), style: AppTypography.metadata.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
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
      ),
    );
  }
}

// ─── Tags Row ────────────────────────────────────────────────────────

class _TagsRow extends StatefulWidget {
  const _TagsRow({required this.task, this.isLast = false});
  final Task task;
  final bool isLast;

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

    return _PropertyRow(
      label: 'Tags',
      trailing: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          ...widget.task.tags.map((tagId) {
            final tag = tagProv.getById(tagId);
            if (tag == null) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () {
                final tags = widget.task.tags.where((t) => t != tagId).toList();
                taskProv.updateTask(widget.task.copyWith(tags: tags));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${tag.name}',
                  style: AppTypography.metadata.copyWith(fontSize: 10, color: colors.textSecondary),
                ),
              ),
            );
          }),
          if (_adding)
            SizedBox(
              width: 80,
              child: TextField(
                controller: _tagController,
                autofocus: true,
                style: AppTypography.metadata.copyWith(fontSize: 11),
                decoration: const InputDecoration(
                  hintText: 'Tag...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (val) async {
                  final name = val.trim();
                  if (name.isNotEmpty) {
                    final tag = await tagProv.createTag(name: name);
                    final tags = [...widget.task.tags, tag.id];
                    taskProv.updateTask(widget.task.copyWith(tags: tags));
                  }
                  setState(() => _adding = false);
                  _tagController.clear();
                },
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _adding = true),
              child: Icon(PhosphorIcons.plus(), size: 14, color: colors.textSecondary.withValues(alpha: 0.4)),
            ),
        ],
      ),
    );
  }
}

// ─── Subtasks Section ────────────────────────────────────────────────

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
            Text('Subtasks', style: AppTypography.caption.copyWith(
              color: colors.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            )),
            const SizedBox(width: 8),
            Text(
              '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
              style: AppTypography.caption.copyWith(color: colors.textQuaternary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border, width: 0.5),
          ),
          child: Column(
            children: [
              ...task.subtasks.map((subtask) => SubtaskItem(
                subtask: subtask,
                taskId: task.id,
                onDelete: () => tasks.deleteSubtask(task.id, subtask.id),
              )),
              // Add subtask pill input
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: controller,
                    style: AppTypography.body.copyWith(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '+ Add subtask...',
                      hintStyle: AppTypography.body.copyWith(color: colors.textTertiary, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        tasks.addSubtask(task.id, val.trim());
                        controller.clear();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Timestamps ──────────────────────────────────────────────────────

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
          style: AppTypography.caption.copyWith(color: colors.textQuaternary),
        ),
        const SizedBox(height: 2),
        Text(
          'Updated ${AppDateUtils.formatRelative(task.updatedAt)}',
          style: AppTypography.caption.copyWith(color: colors.textQuaternary),
        ),
      ],
    );
  }
}

class _StickerRow extends StatelessWidget {
  final Task task;
  const _StickerRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final stickerId = task.stickerId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.emoji_emotions_outlined,
              size: 16, color: colors.textSecondary),
          const SizedBox(width: 10),
          Text('Sticker',
            style: AppTypography.body.copyWith(
                color: colors.textPrimary)),
          const Spacer(),

          if (stickerId != null) ...[
            // Large animated sticker preview
            GestureDetector(
              onTap: () => _openPicker(context),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Consumer<StoreService>(
                    builder: (context, store, _) {
                      final serverSticker = store.data?.stickerById(stickerId);
                      final localSticker = StickerRegistry.findById(stickerId);
                      return StickerWidget(
                        serverSticker: serverSticker,
                        localSticker: localSticker ?? AppStickers.detailDefault,
                        size: 44,
                        animate: true,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Remove button
            GestureDetector(
              onTap: () => context.read<TaskProvider>()
                  .setSticker(task.id, null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.close_rounded,
                    size: 14, color: AppColors.red),
              ),
            ),
          ] else
            // No sticker — show add button
            GestureDetector(
              onTap: () => _openPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded,
                        size: 14, color: accent),
                    const SizedBox(width: 4),
                    Text('Add sticker',
                      style: AppTypography.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await StickerPicker.show(
      context,
      currentStickerId: task.stickerId,
    );
    if (result == null) return; // dismissed — no change
    if (!context.mounted) return;

    // Empty string means remove
    final newId = result.isEmpty ? null : result;
    context.read<TaskProvider>().setSticker(task.id, newId);
  }
}
// ─── Reminder Picker ──────────────────────────────────────────────────

class _ReminderPicker extends StatelessWidget {
  const _ReminderPicker({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    final options = {
      0: 'At time of event',
      5: '5 minutes before',
      10: '10 minutes before',
      15: '15 minutes before',
      30: '30 minutes before',
      60: '1 hour before',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (task.hasReminder)
          GestureDetector(
            onTap: () => context.read<TaskProvider>().setReminder(task.id, false, 0),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.notifications_off_outlined, size: 14, color: colors.textTertiary),
            ),
          ),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: task.hasReminder ? task.reminderMinutesBefore : null,
            hint: Text('None', style: AppTypography.metadata.copyWith(color: colors.textTertiary)),
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, size: 16, color: colors.textTertiary),
            items: options.entries.map((e) {
              return DropdownMenuItem<int>(
                value: e.key,
                child: Text(e.value, style: AppTypography.metadata.copyWith(fontSize: 11)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                context.read<TaskProvider>().setReminder(task.id, true, val);
              }
            },
          ),
        ),
      ],
    );
  }
}
