import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';
import '../../shared/empty_state_widget.dart';
import '../../shared/sticker_widget.dart';
import '../../../data/app_stickers.dart';
import '../../../services/store_service.dart';
import '../../../data/sticker_packs.dart';

class GridViewLayout extends StatelessWidget {

  final List<Task> tasks;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  const GridViewLayout({
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
          stickerPath: AppStickers.emptyAllTasksPath,
          headline: 'No tasks yet',
          subline: 'Your grid will look great once you add some tasks.',
        ),
      );
    }


    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _GridTaskCard(task: tasks[index]),
    );
  }
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GRID CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GridTaskCard extends StatefulWidget {
  final Task task;

  const _GridTaskCard({required this.task});

  @override
  State<_GridTaskCard> createState() => _GridTaskCardState();
}

class _GridTaskCardState extends State<_GridTaskCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    final isSelected = nav.selectedTaskId == widget.task.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (nav.isSelectionMode) {
            nav.toggleTaskSelection(widget.task.id);
          } else {
            nav.selectTask(widget.task.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.shadowSM(isDark: colors.isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover area (120px)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.priorityColor(widget.task.priority)
                          .withValues(alpha: 0.10),
                      AppColors.priorityColor(widget.task.priority)
                          .withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    // Sticker or emoji (centered)
                    Center(
                      child: widget.task.stickerId != null &&
                              widget.task.stickerId!.isNotEmpty
                          ? AppStickerWidget(
                              serverSticker: StoreService.instance.data?.stickerById(widget.task.stickerId!),
                              localSticker: StickerRegistry.findById(widget.task.stickerId!),
                              size: 68,
                              animate: true,
                            )
                          : Text(
                              _priorityEmoji(widget.task.priority),
                              style: const TextStyle(fontSize: 40),
                            ),
                    ),

                    // Priority dot (top right)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.priorityColor(widget.task.priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Flag (top left)
                    if (widget.task.isFlagged)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Icon(
                          Icons.bookmark_rounded,
                          size: 14,
                          color: AppColors.gold,
                        ),
                      ),
                  ],
                ),
              ),

              // Content (below cover) — Expanded to prevent overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          widget.task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMD.copyWith(
                            color: widget.task.isCompleted
                                ? colors.textQuaternary
                                : colors.textPrimary,
                            decoration: widget.task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (widget.task.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: _dateLabel(widget.task.dueDate!),
                            isOverdue: _isOverdue(widget.task),
                          ),
                        ),
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
