import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import '../shared/custom_checkbox.dart';
import '../shared/pressable_scale.dart';
import '../shared/animated_strikethrough.dart';
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

  void _showUndoSnackbar(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Task deleted', style: AppTypography.body.copyWith(color: Colors.white)),
          ],
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: accent, // Matching macOS blue
          onPressed: () {
            context.read<TaskProvider>().restoreTask(widget.task.id);
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF2C2C2E), // Dark pill
        duration: const Duration(seconds: 4),
        width: 320,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accentColor = Theme.of(context).colorScheme.primary;
    final t = widget.task; // Moved up
    final isOverdue = t.isOverdue && !t.isCompleted;

    // Derived colors
    final priorityColor = _getPriorityColor(t.priority);
    final isDark = colors.isDark;

    // Background gradient / solid color based on state
    Gradient? bgGradient;
    Color? bgColor;

    if (widget.isSelected) {
      bgColor = colors.sidebarActive;
    } else if (t.isCompleted) {
      bgColor = isDark ? const Color(0xFF1E1E20) : const Color(0xFFF9F9FB);
    } else {
      bgGradient = isDark ? AppColors.cardGradientDark() : AppColors.cardGradientLight();
    }

    // Border configuration
    Color borderColor = colors.border;
    if (widget.isSelected) {
      borderColor = accentColor.withOpacity(0.5);
    } else if (_hovered) {
      borderColor = colors.textTertiary.withOpacity(0.2);
    }

    // Outer Container wrapping the PressableScale
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          CustomContextMenuController.show(
            context: context,
            position: details.globalPosition, // Exact cursor coords
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
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: bgGradient == null ? bgColor : null,
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.5),
            boxShadow: t.isCompleted ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: _hovered ? 12 : 8,
                offset: const Offset(0, 1),
              ),
              if (!_hovered && !isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: t.isCompleted ? 0.55 : 1.0,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // -- Priority Left Border --
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 4,
                      color: t.isCompleted ? AppColors.green : priorityColor,
                    ),

                    // -- Main Content --
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top Row: Checkbox, Title, Icons
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1, right: 12),
                                  child: CustomCheckbox(
                                    value: t.isCompleted,
                                    onChanged: (val) {
                                      context.read<TaskProvider>().toggleComplete(t.id);
                                      if (val) {
                                        final box = context.findRenderObject() as RenderBox?;
                                        if (box != null) {
                                          final pos = box.localToGlobal(const Offset(30, 24)); // approx checkbox pos
                                          ConfettiOverlay.show(context, pos);
                                        }
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedStrikethrough(
                                        text: t.title,
                                        isStruck: t.isCompleted,
                                        strikeColor: colors.textSecondary,
                                        textStyle: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: isOverdue ? AppColors.red : colors.textPrimary,
                                        ),
                                      ),
                                      if (t.description != null && t.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          t.description!.split('\n').first,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.caption.copyWith(color: colors.textTertiary),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                                if (t.isFlagged)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(Icons.flag_rounded, size: 16, color: AppColors.orange),
                                  ),
                              ],
                            ),

                            // Bottom Row: Metadata (Date, Subtasks, Tags)
                            if (_hasMetadata(t)) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 34), // align under text
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: _buildMetadata(t, colors, isOverdue),
                                ),
                              ),
                            ],

                            // Progress Bar for Subtasks
                            if (t.subtasks.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 34),
                                child: _SubtaskProgressBar(task: t),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  bool _hasMetadata(Task t) => t.dueDate != null || t.subtasks.isNotEmpty || t.tags.isNotEmpty;

  List<Widget> _buildMetadata(Task t, AppColorsExtension colors, bool isOverdue) {
    final list = <Widget>[];

    // Due Date
    if (t.dueDate != null) {
      final text = AppDateUtils.formatDueDate(t.dueDate!, t.dueHour, t.dueMinute);
      list.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isOverdue ? AppColors.red.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: isOverdue ? AppColors.red : colors.textTertiary,
              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    // Subtask count
    if (t.subtasks.isNotEmpty) {
      if (list.isNotEmpty) list.add(_dotFormatter(colors));
      final completed = t.subtasks.where((s) => s.isCompleted).length;
      list.add(
        Text(
          '$completed/${t.subtasks.length} subtasks',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
      );
    }

    // Tags
    if (t.tags.isNotEmpty) {
      if (list.isNotEmpty) list.add(_dotFormatter(colors));
      // Show up to 2 tags
      final displayTags = t.tags.take(2).toList();
      for (int i = 0; i < displayTags.length; i++) {
        list.add(
          Text(
            '#${displayTags[i]}',
            style: AppTypography.caption.copyWith(color: AppColors.indigo),
          ),
        );
        if (i < displayTags.length - 1) list.add(const SizedBox(width: 4));
      }
      if (t.tags.length > 2) {
        list.add(
          Text(
            '+${t.tags.length - 2}',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
        );
      }
    }

    return list;
  }

  Widget _dotFormatter(AppColorsExtension colors) {
    return Text('·', style: AppTypography.caption.copyWith(color: colors.textTertiary));
  }

  Color _getPriorityColor(Priority p) {
    switch (p) {
      case Priority.none:
        return Colors.transparent;
      case Priority.low:
        return AppColors.green;
      case Priority.medium:
        return AppColors.orange;
      case Priority.high:
        return AppColors.red;
      case Priority.urgent:
        return AppColors.pinkRed;
    }
  }
}

class _SubtaskProgressBar extends StatelessWidget {
  final Task task;
  const _SubtaskProgressBar({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = task.subtasks.length;
    final completed = task.subtasks.where((s) => s.isCompleted).length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Container(
                  width: constraints.maxWidth * value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.blue],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
