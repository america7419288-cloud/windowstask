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
import '../../shared/empty_state_widget.dart';
import '../../../services/store_service.dart';

class CompactLayout extends StatelessWidget {
  final List<Task> tasks;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const CompactLayout({
    super.key,
    required this.tasks,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyStateWidget(
        config: EmptyStateConfig(
          sticker: AppStickers.allTasksEmpty,
          headline: 'No tasks',
          subline: 'Tasks will appear here once added.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _CompactRow(task: tasks[index]),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPACT ROW
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CompactRow extends StatefulWidget {
  final Task task;

  const _CompactRow({required this.task});

  @override
  State<_CompactRow> createState() => _CompactRowState();
}

class _CompactRowState extends State<_CompactRow> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: t.priority == Priority.none
                ? Colors.transparent
                : AppColors.priorityColor(t.priority).withValues(
                    alpha: t.priority == Priority.urgent ||
                            t.priority == Priority.high
                        ? 0.9
                        : 0.45,
                  ),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sticker as tap target OR checkbox
          GestureDetector(
            onTap: () => context.read<TaskProvider>().toggleComplete(t.id),
            child: t.stickerId != null && t.stickerId!.isNotEmpty
                ? Stack(
                    children: [
                      AppStickerWidget(
                        serverSticker: StoreService.instance.data
                            ?.stickerById(t.stickerId!),
                        size: 30,
                        animate: !t.isCompleted,
                      ),
                      if (t.isCompleted)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.background,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  )
                : _TaskCheckbox(
                    value: t.isCompleted,
                    priority: t.priority,
                    onChanged: (_) =>
                        context.read<TaskProvider>().toggleComplete(t.id),
                  ),
          ),

          const SizedBox(width: 10),

          // Title + meta
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.title,
                    style: AppTypography.titleSM.copyWith(
                      color: t.isCompleted
                          ? colors.textQuaternary
                          : colors.textPrimary,
                      decoration: t.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (t.dueDate != null)
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: _dateLabel(t.dueDate!),
                    isOverdue: _isOverdue(t),
                  ),
              ],
            ),
          ),

          // Arrow to detail
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: colors.textQuaternary,
          ),
        ],
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
// CUSTOM CHECKBOX
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _TaskCheckbox extends StatelessWidget {
  final bool value;
  final Priority priority;
  final Function(bool) onChanged;

  const _TaskCheckbox({
    required this.value,
    required this.priority,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = value
        ? AppColors.success
        : AppColors.priorityColor(priority);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? color : color.withValues(alpha: 0.10),
          border: Border.all(
            color: value ? color : color.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: value
            ? Icon(
                Icons.check_rounded,
                size: 11,
                color: Colors.white,
              )
            : null,
      ),
    );
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
