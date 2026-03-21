import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../../providers/celebration_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../utils/date_utils.dart';
import '../shared/card_helpers.dart';
import '../../shared/sticker_widget.dart';
import '../../shared/deco_sticker.dart';
import '../../../data/app_stickers.dart';
import '../../../data/sticker_packs.dart';
import '../../shared/empty_state_widget.dart';
import '../shared/custom_checkbox.dart';
import '../../../data/app_stickers.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final colors = context.appColors;
    if (tasks.isEmpty) {
      return EmptyStateWidget(
        config: EmptyStateConfig(
          sticker: AppStickers.allTasksEmpty,
          headline: 'No tasks',
          subline: 'Tasks will appear here once added.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 16,
        endIndent: 16,
        color: colors.isDark 
            ? Colors.white.withValues(alpha: 0.08) 
            : Colors.black.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) => _CompactRow(task: tasks[index]),
    );
  }
}

class _CompactRow extends StatefulWidget {
  final Task task;
  const _CompactRow({required this.task});

  @override
  State<_CompactRow> createState() => _CompactRowState();
}

class _CompactRowState extends State<_CompactRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();
    final isSelected = nav.selectedTaskId == t.id || nav.isTaskSelected(t.id);
    final priorityColor = getPriorityColor(t.priority);

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
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : _hovered ? colors.surface.withValues(alpha: 0.5) : Colors.transparent,
            border: Border(
              left: BorderSide(color: priorityColor, width: 3),
              bottom: BorderSide(color: colors.border.withValues(alpha: 0.4), width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              // STICKER OR SELECTION
              SizedBox(
                width: 32, height: 32,
                child: nav.isSelectionMode
                  ? Center(
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: nav.isTaskSelected(t.id) ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: nav.isTaskSelected(t.id) ? Theme.of(context).colorScheme.primary : colors.textQuaternary,
                            width: 1.5,
                          ),
                        ),
                        child: nav.isTaskSelected(t.id)
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    )
                  : GestureDetector(
                      onTap: () => context.read<TaskProvider>().toggleComplete(
                        t.id,
                        celebration: context.read<CelebrationProvider>(),
                      ),
                      child: Stack(
                        children: [
                          t.stickerId != null && t.stickerId!.isNotEmpty
                            ? StickerWidget(
                                sticker: StickerRegistry.findById(t.stickerId!) ?? AppStickers.detailDefault,
                                size: 32,
                                animate: !t.isCompleted,
                              )
                            : CustomCheckbox(
                                value: t.isCompleted,
                                onChanged: (_) => context.read<TaskProvider>().toggleComplete(t.id),
                                activeColor: AppColors.primary,
                                size: 18,
                              ),
                          if (t.stickerId != null && t.stickerId!.isNotEmpty && t.isCompleted)
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.tertiary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.background, width: 1.5),
                                ),
                                child: const Icon(Icons.check_rounded, size: 9, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
              const SizedBox(width: 12),

              // CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySemibold.copyWith(
                        fontSize: 14,
                        color: t.isCompleted ? colors.textTertiary : colors.textPrimary,
                        decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                      )),
                    
                    // Metadata inline
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (t.priority != Priority.none)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: PriorityBadgeInline(priority: t.priority),
                          ),
                        if (t.dueDate != null)
                          Row(children: [
                            Icon(Icons.schedule_rounded, size: 10, color: t.isOverdue && !t.isCompleted ? AppColors.red : colors.textQuaternary),
                            const SizedBox(width: 3),
                            Text(AppDateUtils.formatShortDate(t.dueDate!),
                              style: AppTypography.micro.copyWith(
                                color: t.isOverdue && !t.isCompleted ? AppColors.red : colors.textQuaternary,
                              )),
                            const SizedBox(width: 8),
                          ]),
                        if (t.subtasks.isNotEmpty)
                          Row(children: [
                            Icon(Icons.check_box_outlined, size: 10, color: colors.textQuaternary),
                            const SizedBox(width: 3),
                            Text('${t.subtasks.where((s)=>s.isCompleted).length}/${t.subtasks.length}',
                              style: AppTypography.micro.copyWith(color: colors.textQuaternary)),
                            const SizedBox(width: 8),
                          ]),
                        // Tags
                        ...t.tags.take(1).map((tagId) {
                          final tag = context.read<TagProvider>().getById(tagId);
                          if (tag == null) return const SizedBox.shrink();
                          return CardTagPill(tagName: tag.name);
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              // FLAG
              if (t.isFlagged)
                const Icon(Icons.bookmark_rounded, size: 14, color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
