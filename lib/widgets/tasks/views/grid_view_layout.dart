import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../../providers/list_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';
import '../../shared/empty_state_widget.dart';
import '../../../painters/empty_state_painters.dart';
import '../../../painters/grid_cover_painter.dart';
import '../shared/task_interaction_wrapper.dart';
import '../shared/sticker_badge.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GridViewLayout extends StatelessWidget {
  final List<Task> tasks;
  const GridViewLayout({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyStateWidget(
        config: EmptyStateConfig(
          painterBuilder: (v) => SearchEmptyPainter(v),
          headline: 'No tasks',
          subline: 'Tasks will appear here once added.',
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _GridTaskCard(task: tasks[index]),
    );
  }
}

// ─── Grid Card ───────────────────────────────────────────────────────

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
    final accent = Theme.of(context).colorScheme.primary;
    final t = widget.task;
    final isDark = colors.isDark;
    final isSelected = context.watch<NavigationProvider>().selectedTaskId == t.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TaskInteractionWrapper(
        task: t,
        actionsPosition: HoverActionsPosition.topRight,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: t.isCompleted
                ? (isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF9F9FB))
                : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accent : colors.border,
              width: isSelected ? 1.5 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: _hovered ? 16 : 8,
                offset: Offset(0, _hovered ? 4 : 2),
              ),
            ],
          ),
          child: AnimatedScale(
            scale: _hovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // COVER — 40%
                      Expanded(flex: 4, child: _CardCover(task: t)),
                      // BODY — 45%
                      Expanded(flex: 4, child: _CardBody(task: t)),
                      // FOOTER
                      _CardFooter(task: t),
                    ],
                  ),
                ),
                if (t.stickerId != null && t.stickerId!.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: StickerBadge(stickerId: t.stickerId!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Cover ───────────────────────────────────────────────────────────

class _CardCover extends StatelessWidget {
  final Task task;
  const _CardCover({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = context.appColors.isDark;
    final priorityColor = _priorityBaseColor(task.priority);
    final isCompleted = task.isCompleted;

    final listEmoji = task.listId != null
        ? context.read<ListProvider>().getById(task.listId!)?.emoji
        : null;

    final gradient = _getPriorityGradient(task.priority, isDark);

    return Opacity(
      opacity: isCompleted ? 0.5 : 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base Gradient
          Container(decoration: BoxDecoration(gradient: gradient)),
          // 2. Geometric art
          if (!isCompleted || task.priority != Priority.none)
            CustomPaint(
              painter: GridCoverPainter(
                taskId: task.id,
                baseColor: priorityColor,
              ),
            ),
          // 3. Emoji overlay
          if (listEmoji != null)
            Center(
              child: Text(
                listEmoji,
                style: const TextStyle(
                  fontSize: 32,
                  shadows: [
                    Shadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 10),
                  ],
                ),
              ),
            ),
          // 4. Priority dot (top-left)
          if (task.priority != Priority.none)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // 5. Completion overlay
          if (isCompleted)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  LinearGradient _getPriorityGradient(Priority p, bool isDark) {
    final double oStart = isDark ? 0.35 : 0.5;
    final double oEnd = isDark ? 0.12 : 0.25;

    switch (p) {
      case Priority.low:
        return LinearGradient(colors: [
          const Color(0xFF34C759).withValues(alpha: oStart),
          const Color(0xFF30D158).withValues(alpha: oEnd),
        ]);
      case Priority.medium:
        return LinearGradient(colors: [
          const Color(0xFFFF9500).withValues(alpha: oStart),
          const Color(0xFFFFCC00).withValues(alpha: oEnd),
        ]);
      case Priority.high:
        return LinearGradient(colors: [
          const Color(0xFFFF3B30).withValues(alpha: oStart),
          const Color(0xFFFF6B6B).withValues(alpha: oEnd),
        ]);
      case Priority.urgent:
        return LinearGradient(colors: [
          const Color(0xFFFF2D55).withValues(alpha: oStart + 0.1),
          const Color(0xFFAF52DE).withValues(alpha: oEnd + 0.1),
        ]);
      case Priority.none:
        if (isDark) {
          return LinearGradient(colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ]);
        }
        return const LinearGradient(colors: [
          Color(0xFFE8E8ED),
          Color(0xFFF2F2F7),
        ]);
    }
  }

  Color _priorityBaseColor(Priority p) {
    switch (p) {
      case Priority.low:    return AppColors.green;
      case Priority.medium: return AppColors.orange;
      case Priority.high:   return AppColors.red;
      case Priority.urgent: return AppColors.pink;
      case Priority.none:   return Colors.grey;
    }
  }
}

// ─── Body ────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  final Task task;
  const _CardBody({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Flexible(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySemibold.copyWith(
                fontSize: 13,
                color: task.isCompleted
                    ? colors.textSecondary
                    : colors.textPrimary,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: colors.textTertiary,
              ),
            ),
          ),
          // Description
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: colors.textTertiary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Footer ──────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  final Task task;
  const _CardFooter({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isOverdue = task.isOverdue && !task.isCompleted;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Due date
          if (task.dueDate != null)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.calendarBlank(),
                    size: 10,
                    color: isOverdue ? AppColors.red : colors.textQuaternary,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      AppDateUtils.formatShortDate(task.dueDate!),
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: isOverdue ? AppColors.red : colors.textQuaternary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Tags
          if (task.tags.isNotEmpty)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${context.read<TagProvider>().getById(task.tags.first)?.name ?? 'Tag'}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.indigo,
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
