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
import '../../../providers/list_provider.dart';
import '../../../data/app_stickers.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/sticker.dart';

class MagazineLayout extends StatelessWidget {
  final List<Task> tasks;
  const MagazineLayout({super.key, required this.tasks});

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _MagazineCard(task: tasks[index]),
    );
  }
}

class _MagazineCard extends StatefulWidget {
  final Task task;
  const _MagazineCard({required this.task});

  @override
  State<_MagazineCard> createState() => _MagazineCardState();
}

class _MagazineCardState extends State<_MagazineCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();
    final isSelected = nav.selectedTaskId == t.id || nav.isTaskSelected(t.id);
    final accent = Theme.of(context).colorScheme.primary;

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
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: CardDesign.background(context),
            borderRadius: BorderRadius.circular(CardDesign.radius),
            border: isSelected 
                ? Border.all(color: accent, width: 2)
                : CardDesign.border(context),
            boxShadow: _hovered 
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))]
                : CardDesign.shadow(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CardDesign.radius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HERO SECTION — Large sticker
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        getPriorityColor(t.priority).withValues(alpha: 0.12),
                        getPriorityColor(t.priority).withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  child: Center(
                    child: t.stickerId != null && t.stickerId!.isNotEmpty
                      ? StickerWidget(
                          sticker: StickerRegistry.findById(t.stickerId!) ?? AppStickers.todayMorning,
                          size: 130,
                          animate: true,
                        )
                      : Icon(Icons.auto_awesome_rounded, size: 80, color: colors.textQuaternary.withValues(alpha: 0.3)),
                  ),
                ),

                // CONTENT SECTION
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta row
                      Row(
                        children: [
                          PriorityBadgeInline(priority: t.priority),
                          const SizedBox(width: 8),
                          if (t.dueDate != null)
                             CardTagPill(tagName: AppDateUtils.formatShortDate(t.dueDate!)),
                          const Spacer(),
                          if (t.isFlagged)
                            const Icon(Icons.bookmark_rounded, color: AppColors.orange, size: 18),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(t.title,
                        style: AppTypography.headline.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                          color: t.isCompleted ? colors.textTertiary : colors.textPrimary,
                          decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                        )),
                      
                      // Note
                      if (t.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(t.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontSize: 15,
                            color: colors.textSecondary,
                            height: 1.5,
                          )),
                      ],

                      // SUBTASKS GRID (2 columns)
                      if (t.subtasks.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const DashedDivider(),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 28,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: t.subtasks.length,
                          itemBuilder: (context, idx) => InlineSubtaskRow(sub: t.subtasks[idx], taskId: t.id),
                        ),
                      ],
                    ],
                  ),
                ),

                // FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                    border: Border(top: BorderSide(color: colors.divider, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      // Completion pill
                      GestureDetector(
                        onTap: () => context.read<TaskProvider>().toggleComplete(
                          t.id,
                          celebration: context.read<CelebrationProvider>(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: t.isCompleted ? AppColors.green : accent,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: (t.isCompleted ? AppColors.green : accent).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(t.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined, size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(t.isCompleted ? 'Completed' : 'Mark complete',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // List name
                      if (t.listId != null)
                        Text(
                          'in ${context.read<ListProvider>().getById(t.listId!)?.name ?? 'Inbox'}',
                          style: AppTypography.caption.copyWith(color: colors.textTertiary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
