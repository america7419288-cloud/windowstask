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
import '../shared/card_helpers.dart';
import '../../shared/sticker_widget.dart';
import '../../shared/deco_sticker.dart';
import '../../../data/app_stickers.dart';
import '../../../data/sticker_packs.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
          sticker: AppStickers.allTasksEmpty,
          headline: 'No tasks',
          subline: 'Tasks will appear here once added.',
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
        childAspectRatio: 0.72,
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
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();
    final isSelected = nav.selectedTaskId == t.id || nav.isTaskSelected(t.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          if (nav.isSelectionMode) {
            nav.toggleTaskSelection(t.id);
          } else {
            nav.selectTask(t.id);
          }
        },
        onLongPress: () => nav.enterSelectionMode(t.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: CardDesign.background(context),
            borderRadius: BorderRadius.circular(CardDesign.radius),
            border: isSelected 
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : CardDesign.border(context),
            boxShadow: _hovered ? [
              BoxShadow(
                color: colors.isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              )
            ] : CardDesign.shadow(context),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(CardDesign.radius - 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GridCover(task: t),
                    Expanded(child: _GridContent(task: t)),
                    _GridFooter(task: t),
                  ],
                ),
              ),
              // Quick Actions Overlay
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QuickActionButton(
                          icon: t.isCompleted ? PhosphorIcons.circle(PhosphorIconsStyle.bold) : PhosphorIcons.checkCircle(PhosphorIconsStyle.bold),
                          color: t.isCompleted ? colors.textTertiary : AppColors.primary,
                          onTap: () => context.read<TaskProvider>().toggleComplete(t.id),
                        ),
                        _QuickActionButton(
                          icon: PhosphorIcons.flag(t.isFlagged ? PhosphorIconsStyle.fill : PhosphorIconsStyle.bold),
                          color: t.isFlagged ? AppColors.orange : colors.textTertiary,
                          onTap: () => context.read<TaskProvider>().toggleFlag(t.id),
                        ),
                        _QuickActionButton(
                          icon: PhosphorIcons.trash(PhosphorIconsStyle.bold),
                          color: AppColors.priorityHigh,
                          onTap: () => context.read<TaskProvider>().moveToTrash(t.id),
                        ),
                      ],
                    ),
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _GridCover extends StatelessWidget {
  final Task task;
  const _GridCover({required this.task});

  @override
  Widget build(BuildContext context) {
    final t = task;
    final colors = context.appColors;
    final isDark = colors.isDark;
    final priorityColor = getPriorityColor(t.priority);

    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            priorityColor.withValues(alpha: isDark ? 0.25 : 0.15),
            priorityColor.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Centered sticker — HERO element
          Center(
            child: t.stickerId != null && t.stickerId!.isNotEmpty
                ? StickerWidget(
                    sticker: StickerRegistry.findById(t.stickerId!) ?? AppStickers.detailDefault,
                    size: 72,
                    animate: true,
                  )
                : Opacity(
                    opacity: 0.3,
                    child: Text(
                      _priorityEmoji(t.priority),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
          ),

          // Completion overlay
          if (t.isCompleted)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          )),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Priority dot — top right
          Positioned(
            top: 10, right: 10,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: priorityColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                )],
              ),
            ),
          ),

          // Flag indicator — top left
          if (t.isFlagged)
            const Positioned(
              top: 8, left: 8,
              child: Icon(
                Icons.bookmark_rounded,
                size: 14,
                color: AppColors.orange,
              ),
            ),
        ],
      ),
    );
  }

  String _priorityEmoji(Priority p) {
    switch (p) {
      case Priority.urgent: return '🔥';
      case Priority.high:   return '⚡';
      case Priority.medium: return '📌';
      case Priority.low:    return '🌿';
      default:              return '📋';
    }
  }
}

class _GridContent extends StatelessWidget {
  final Task task;
  const _GridContent({required this.task});

  @override
  Widget build(BuildContext context) {
    final t = task;
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(t.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySemibold.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.3,
              color: t.isCompleted ? colors.textTertiary : colors.textPrimary,
              decoration: t.isCompleted ? TextDecoration.lineThrough : null,
            )),

          // Note preview
          if (t.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(t.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: colors.textTertiary,
                height: 1.4,
              )),
          ],

          // Dashed divider if subtasks
          if (t.subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const DashedDivider(),
            const SizedBox(height: 6),
            // First 2 subtasks
            ...t.subtasks.take(2).map((sub) => InlineSubtaskRow(sub: sub, taskId: t.id, compact: true)),
            // +N more
            if (t.subtasks.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 18),
                child: Text(
                  '+${t.subtasks.length - 2} more',
                  style: AppTypography.micro.copyWith(
                    fontSize: 10,
                    color: accent.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  )),
              ),
          ],
        ],
      ),
    );
  }
}

class _GridFooter extends StatelessWidget {
  final Task task;
  const _GridFooter({required this.task});

  @override
  Widget build(BuildContext context) {
    final t = task;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          // Tags (max 2)
          ...t.tags.take(2).map((tagId) {
            final tag = context.read<TagProvider>().getById(tagId);
            if (tag == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CardTagPill(tagName: tag.name),
            );
          }),
          const Spacer(),
          // Due date
          if (t.dueDate != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 10,
                    color: t.isOverdue && !t.isCompleted ? AppColors.red : colors.textQuaternary),
                const SizedBox(width: 3),
                Text(
                  AppDateUtils.formatShortDate(t.dueDate!),
                  style: AppTypography.micro.copyWith(
                    fontSize: 10,
                    color: t.isOverdue && !t.isCompleted ? AppColors.red : colors.textQuaternary,
                  )),
              ],
            ),
        ],
      ),
    );
  }
}
