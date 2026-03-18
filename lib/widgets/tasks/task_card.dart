import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/subtask.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/tag_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import 'shared/custom_checkbox.dart';
import '../../painters/confetti_painter.dart';
import '../context_menu/context_menu_controller.dart';
import '../../data/sticker_packs.dart';
import '../shared/sticker_widget.dart';

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

      // Show confetti from roughly the checkbox area
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final pos = box.localToGlobal(const Offset(30, 20));
        ConfettiOverlay.show(context, pos);
      }

      // Reset completion flash after 400ms
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() => _completionFlash = false);
        }
      });

      // Reset justCompleted after 600ms
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _justCompleted = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final hasSticker = t.stickerId != null && t.stickerId!.isNotEmpty;

    return Padding(
      // Extra bottom padding when sticker present so it doesn't overlap the next card
      padding: EdgeInsets.only(
        bottom: hasSticker ? 16.0 : 0.0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The card itself
          _buildCard(context),

          // Sticker badge — positioned relative to card Stack, bottom-right, half outside the card
          if (hasSticker)
            Positioned(
              bottom: -14, // half outside card bottom
              right: 12,   // inset from right edge
              child: _StickerBadge(stickerId: t.stickerId!),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final t = widget.task;
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = colors.isDark;
    final isCompleted = t.isCompleted;
    final isOverdue = t.isOverdue && !isCompleted;
    final hasSubtasks = t.subtasks.isNotEmpty;

    return MouseRegion(
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
        onTap: () {
          CustomContextMenuController.hide();
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            context.read<NavigationProvider>().selectTask(t.id);
          }
        },
        child: AnimatedOpacity(
          duration: Duration(milliseconds: _justCompleted ? 0 : 300),
          opacity: isCompleted && !_justCompleted ? 0.55 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _completionFlash
                  ? AppColors.priorityLow.withValues(alpha: 0.06)
                  : (isDark ? const Color(0xFF1E1C1A) : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? accent.withValues(alpha: 0.6)
                    : _hovered
                        ? (isDark
                            ? Colors.white.withValues(alpha: isCompleted ? 0.12 : 0.18)
                            : Colors.black.withValues(alpha: isCompleted ? 0.14 : 0.20))
                        : (isDark
                            ? Colors.white.withValues(alpha: isCompleted ? 0.06 : 0.10)
                            : Colors.black.withValues(alpha: isCompleted ? 0.08 : 0.12)),
                width: widget.isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isDark || isCompleted
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left priority bar
                  _PriorityBar(priority: t.priority),

                  // Card content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top section
                        _buildTopSection(context, t, colors, accent, isCompleted, isOverdue),

                        // 2. Dashed divider
                        if (hasSubtasks) const _DashedDivider(),

                        // 3. Subtasks section
                        if (hasSubtasks) _buildSubtasksSection(context, t, colors, accent, isCompleted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, Task t, AppColorsExtension colors, Color accent, bool isCompleted, bool isOverdue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: CustomCheckbox(
                  value: isCompleted,
                  onChanged: (_) => _handleComplete(),
                  activeColor: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),

              // Task name
              Expanded(
                child: Text(
                  t.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySemibold.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.3,
                    color: isCompleted ? colors.textTertiary : colors.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: colors.textTertiary,
                  ),
                ),
              ),

              // Expand arrow
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.read<NavigationProvider>().selectTask(t.id),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: colors.textQuaternary,
                ),
              ),
            ],
          ),

          // Metadata row
          if (t.dueDate != null || t.tags.isNotEmpty || t.isFlagged)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 5),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (t.dueDate != null)
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      label: AppDateUtils.formatShortDate(t.dueDate!),
                      color: t.isOverdue && !isCompleted ? AppColors.red : colors.textTertiary,
                      isAlert: t.isOverdue && !isCompleted,
                    ),
                  if (t.isFlagged)
                    const _MetaChip(
                      icon: Icons.bookmark_rounded,
                      label: 'Flagged',
                      color: AppColors.orange,
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
      ),
    );
  }

  Widget _buildSubtasksSection(BuildContext context, Task t, AppColorsExtension colors, Color accent, bool isParentCompleted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...t.subtasks.take(2).map((sub) => _InlineSubtask(
                subtask: sub,
                taskId: t.id,
                isParentCompleted: isParentCompleted,
              )),
          if (t.subtasks.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 24),
              child: Text(
                '+${t.subtasks.length - 2} more',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: accent.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final Priority priority;
  const _PriorityBar({required this.priority});

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.none:   return Colors.transparent;
      case Priority.low:    return AppColors.priorityLow;
      case Priority.medium: return AppColors.priorityMedium;
      case Priority.high:   return AppColors.priorityHigh;
      case Priority.urgent: return AppColors.priorityUrgent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      width: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
        boxShadow: priority == Priority.urgent
            ? [
                BoxShadow(
                  color: AppColors.priorityUrgent.withValues(alpha: 0.5),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.10),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double x = 0;
    const dashWidth = 5.0;
    const dashSpace = 4.0;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dashWidth, 0),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _InlineSubtask extends StatelessWidget {
  final Subtask subtask;
  final String taskId;
  final bool isParentCompleted;

  const _InlineSubtask({
    required this.subtask,
    required this.taskId,
    required this.isParentCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: isParentCompleted
                ? null
                : () => context.read<TaskProvider>().toggleSubtask(taskId, subtask.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: subtask.isCompleted ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: subtask.isCompleted ? accent : colors.textTertiary.withValues(alpha: 0.4),
                  width: 1.25,
                ),
              ),
              child: subtask.isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 9,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                color: subtask.isCompleted ? colors.textTertiary : colors.textSecondary,
                decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerBadge extends StatelessWidget {
  final String stickerId;
  const _StickerBadge({required this.stickerId});

  @override
  Widget build(BuildContext context) {
    final sticker = StickerRegistry.findById(stickerId);
    if (sticker == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2725) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.10),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: StickerWidget(
          sticker: sticker,
          size: 28,
          animate: true,
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
        border: isAlert ? Border.all(color: color.withValues(alpha: 0.3), width: 0.5) : null,
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
