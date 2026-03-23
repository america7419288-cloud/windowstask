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
import '../../shared/priority_pill.dart';

class MagazineLayout extends StatelessWidget {
  final List<Task> tasks;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const MagazineLayout({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _MagazineCard(task: tasks[index]),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAGAZINE CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _MagazineCard extends StatefulWidget {
  final Task task;

  const _MagazineCard({required this.task});

  @override
  State<_MagazineCard> createState() => _MagazineCardState();
}

class _MagazineCardState extends State<_MagazineCard> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 190),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.shadowSM(isDark: colors.isDark),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticker circle (fixed 72x72)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.priorityColor(t.priority)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: t.stickerId != null && t.stickerId!.isNotEmpty
                    ? AppStickerWidget(
                        serverSticker: StoreService.instance.data
                            ?.stickerById(t.stickerId!),
                        size: 52,
                        animate: true,
                      )
                    : Text(
                        _priorityEmoji(t.priority),
                        style: const TextStyle(fontSize: 32),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority pill
                  PriorityPill(priority: t.priority),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    t.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSM.copyWith(
                      color: t.isCompleted
                          ? colors.textTertiary
                          : colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  // Footer: date + complete button
                  Row(
                    children: [
                      if (t.dueDate != null)
                        _MetaChip(
                          icon: Icons.calendar_today_outlined,
                          label: _dateLabel(t.dueDate!),
                          isOverdue: _isOverdue(t),
                        ),
                      const Spacer(),
                      // Complete pill
                      GestureDetector(
                        onTap: () =>
                            context.read<TaskProvider>().toggleComplete(t.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: t.isCompleted
                                ? AppColors.success.withValues(alpha: 0.10)
                                : AppColors.indigoDim,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t.isCompleted ? '✓ Done' : 'Complete',
                            style: AppTypography.labelMD.copyWith(
                              color: t.isCompleted
                                  ? AppColors.success
                                  : AppColors.indigo,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
