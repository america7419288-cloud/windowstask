import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/tag_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import 'shared/custom_checkbox.dart';
import '../../data/sticker_packs.dart';
import '../../models/sticker.dart';
import '../shared/sticker_widget.dart';
import 'shared/sticker_badge.dart';
import '../shared/pressable_scale.dart';
import '../../painters/confetti_painter.dart';
import '../context_menu/context_menu_controller.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;
  bool _justCompleted = false;
  bool _completionFlash = false;

  void _handleComplete() {
    final wasCompleted = widget.task.isCompleted;
    context.read<TaskProvider>().toggleComplete(widget.task.id);
    if (!wasCompleted) {
      setState(() {
        _justCompleted = true;
        _completionFlash = true;
      });
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final pos = box.localToGlobal(const Offset(30, 20));
        ConfettiOverlay.show(context, pos);
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _completionFlash = false);
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _justCompleted = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = widget.task;
    final isOverdue = t.isOverdue && !t.isCompleted;
    final isDark = colors.isDark;
    final isCompleted = t.isCompleted;

    // Background colors
    final normalBg = isDark ? const Color(0xFF2A2725) : Colors.white;
    final completedBg = isDark
        ? const Color(0xFF242220).withValues(alpha: 0.5)
        : const Color(0xFFF8F7F5);
    final cardBg = _completionFlash
        ? AppColors.priorityLow.withValues(alpha: 0.08)
        : (isCompleted ? completedBg : normalBg);

    // Border
    final borderColor = widget.isSelected
        ? AppColors.primary.withValues(alpha: 0.45)
        : _hovered
            ? (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.10))
            : (isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07));
    final borderWidth = widget.isSelected ? 1.5 : 0.75;

    // Shadows
    final shadows = isCompleted
        ? <BoxShadow>[]
        : isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: _hovered ? 20 : 12,
                  offset: Offset(0, _hovered ? 6 : 3),
                ),
              ]
            : _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.09),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: -1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.055),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                      spreadRadius: -1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ];

    final card = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          CustomContextMenuController.show(
            context: context,
            position: details.globalPosition,
            task: t,
            taskProvider: context.read<TaskProvider>(),
            listProvider: context.read<ListProvider>(),
          );
        },
        child: PressableScale(
          scaleDown: 0.98,
          onTap: () {
            CustomContextMenuController.hide();
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              context.read<NavigationProvider>().selectTask(t.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primary.withValues(alpha: 0.025)
                  : cardBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: shadows,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PriorityBar(priority: t.priority),
                      Expanded(child: _buildContent(context, t, colors, isOverdue, isCompleted)),
                    ],
                  ),
                ),
                if (t.stickerId != null && t.stickerId!.isNotEmpty)
                  Positioned(
                    bottom: -10,
                    right: 8,
                    child: StickerBadge(stickerId: t.stickerId!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: _justCompleted ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: _justCompleted ? 0 : 300),
        opacity: isCompleted && !_justCompleted ? 0.65 : 1.0,
        child: card,
      ),
    );
  }

  Widget _buildContent(BuildContext context, Task t, AppColorsExtension colors, bool isOverdue, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: checkbox + title + icons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomCheckbox(
                value: isCompleted,
                onChanged: (_) {
                  if (!t.isDeleted) _handleComplete();
                },
                activeColor: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isCompleted
                    ? Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: colors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: colors.textTertiary,
                        ),
                      )
                    : Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySemibold.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: isOverdue
                              ? AppColors.priorityHigh
                              : colors.textPrimary,
                        ),
                      ),
              ),
              if (t.isFlagged)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.bookmark_rounded,
                      size: 14, color: AppColors.priorityMedium),
                ),
              if (t.subtasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _MiniSubtaskBadge(task: t),
                ),
              if (t.isDeleted) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => context.read<TaskProvider>().restoreTask(t.id),
                  icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                  label: Text('Restore', style: AppTypography.caption),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
          // Description
          if (t.description.isNotEmpty && !isCompleted) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                t.description.split('\n').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.callout.copyWith(
                  color: colors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          // Bottom row: metadata chips
          if (_hasMetadata(t) && !isCompleted) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  if (t.dueDate != null)
                    _MetaChip(
                      icon: isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.schedule_rounded,
                      label: AppDateUtils.formatDueDate(t.dueDate!, t.dueHour, t.dueMinute),
                      color: isOverdue
                          ? AppColors.priorityHigh
                          : colors.textTertiary,
                      isAlert: isOverdue,
                    ),
                  ...t.tags.take(2).map((tagId) {
                    final tag = context.read<TagProvider>().getById(tagId);
                    if (tag == null) return const SizedBox.shrink();
                    return _TagPill(tagName: tag.name);
                  }),
                  if (t.tags.length > 2)
                    _MetaChip(
                      label: '+${t.tags.length - 2}',
                      color: colors.textQuaternary,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasMetadata(Task t) =>
      t.dueDate != null || t.tags.isNotEmpty;
}

class _PriorityBar extends StatelessWidget {
  final Priority priority;
  const _PriorityBar({required this.priority});

  Color get _color {
    switch (priority) {
      case Priority.none:   return Colors.transparent;
      case Priority.low:    return AppColors.priorityLow;
      case Priority.medium: return AppColors.priorityMedium;
      case Priority.high:   return AppColors.priorityHigh;
      case Priority.urgent: return AppColors.priorityUrgent;
    }
  }

  List<BoxShadow> get _glow {
    switch (priority) {
      case Priority.none:
        return [];
      case Priority.low:
        return [BoxShadow(color: AppColors.priorityLow.withValues(alpha: 0.35), blurRadius: 6)];
      case Priority.medium:
        return [BoxShadow(color: AppColors.priorityMedium.withValues(alpha: 0.35), blurRadius: 6)];
      case Priority.high:
        return [BoxShadow(color: AppColors.priorityHigh.withValues(alpha: 0.40), blurRadius: 8)];
      case Priority.urgent:
        return [BoxShadow(color: AppColors.priorityUrgent.withValues(alpha: 0.55), blurRadius: 10, spreadRadius: 1)];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (priority == Priority.none) return const SizedBox(width: 5);
    return Container(
      width: 5,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(13),
          bottomLeft: Radius.circular(13),
        ),
        boxShadow: _glow,
      ),
    );
  }
}

class _MiniSubtaskBadge extends StatelessWidget {
  final Task task;
  const _MiniSubtaskBadge({required this.task});

  @override
  Widget build(BuildContext context) {
    final done = task.subtasks.where((s) => s.isCompleted).length;
    final total = task.subtasks.length;
    final progress = done / total;
    final color = progress == 1.0
        ? AppColors.priorityLow
        : progress > 0.5
            ? AppColors.priorityMedium
            : context.appColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        '$done/$total',
        style: AppTypography.micro.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isAlert;

  const _MetaChip({
    required this.label,
    required this.color,
    this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAlert ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isAlert
            ? Border.all(color: color.withValues(alpha: 0.3), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String tagName;
  const _TagPill({required this.tagName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$tagName',
        style: AppTypography.micro.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
