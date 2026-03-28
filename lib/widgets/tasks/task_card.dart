import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/celebration_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import '../../painters/confetti_painter.dart';
import '../context_menu/context_menu_controller.dart';
import '../../data/app_stickers.dart';
import '../shared/sticker_widget.dart';
import '../../services/store_service.dart';
import '../../data/sticker_packs.dart';
import 'save_template_dialog.dart';
import 'package:flutter/services.dart';
import '../../screens/task_detail_page.dart';

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

  void _handleComplete() {
    final wasCompleted = widget.task.isCompleted;
    final tp = context.read<TaskProvider>();
    tp.toggleComplete(
      widget.task.id,
      celebration: context.read<CelebrationProvider>(),
    );

    if (!wasCompleted) {
      setState(() => _justCompleted = true);

      // Award XP via UserProvider
      context.read<UserProvider>().recordTaskCompletion(widget.task);

      // Calculate XP and show floating chip
      int xp = 10; // Default XP
      if (widget.task.priority == Priority.high) xp = 20;
      if (widget.task.priority == Priority.urgent) xp = 30;
      _showXPChip(context, xp);

      // Show celebration sticker
      _CelebrationStickerOverlay.show(context);

      // Show confetti from roughly the checkbox area
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final pos = box.localToGlobal(const Offset(30, 20));
        ConfettiOverlay.show(context, pos);
      }

      // Reset justCompleted after 600ms
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _justCompleted = false);
        }
      });
    }
  }

  void _showXPChip(BuildContext context, int xp) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset(box.size.width - 60, 0));

    final overlay = OverlayEntry(
      builder: (_) => _XPChipOverlay(left: pos.dx, top: pos.dy, xp: xp),
    );
    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(milliseconds: 1200), overlay.remove);
  }

  void _openDetail() {
    CustomContextMenuController.hide();
    final nav = context.read<NavigationProvider>();
    if (nav.isSelectionMode) {
      nav.toggleTaskSelection(widget.task.id);
    } else {
      nav.selectTask(widget.task.id);
      if (widget.task.isDeleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Restore task to edit it', style: TextStyle(color: Colors.white)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

  }

  void _showContextMenu(BuildContext context) {
    CustomContextMenuController.show(
      context: context,
      position: Offset.zero,
      task: widget.task,
      taskProvider: context.read<TaskProvider>(),
      listProvider: context.read<ListProvider>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();
    final colors = context.appColors;
    final isCompleted = t.isCompleted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openDetail,
        onSecondaryTapUp: (details) => _showContextMenu(context),
        onLongPress: () async {
          final saved = await SaveTemplateDialog.show(context, t);
          if (saved) {
            HapticFeedback.mediumImpact();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _hovered || widget.isSelected
                ? colors.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered || widget.isSelected
                ? AppColors.shadowSM(isDark: colors.isDark)
                : [],
          ),
          child: Row(
            children: [
              // Priority bar (left edge)
              if (t.priority != Priority.none)
                Container(
                  width: 3,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.priorityColor(t.priority).withValues(
                      alpha: t.priority == Priority.urgent ||
                              t.priority == Priority.high
                          ? 0.9
                          : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 15),

              // Custom checkbox
              _TaskCheckbox(
                value: isCompleted,
                priority: t.priority,
                onChanged: (_) => _handleComplete(),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.title,
                            style: AppTypography.titleMD.copyWith(
                              color: isCompleted
                                  ? colors.textQuaternary
                                  : colors.textPrimary,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.textQuaternary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Metadata row
                    if (t.dueDate != null ||
                        t.subtasks.isNotEmpty ||
                        t.isRecurring ||
                        t.hasReminder)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            // Date
                            if (t.dueDate != null)
                              _MetaChip(
                                icon: Icons.calendar_today_outlined,
                                label: _dateLabel(t.dueDate!),
                                isOverdue: _isOverdue(t),
                              ),

                            // Subtask count
                            if (t.subtasks.isNotEmpty)
                              _MetaChip(
                                icon: Icons.check_box_outline_blank,
                                label:
                                    '${t.subtasks.where((s) => s.isCompleted).length}/${t.subtasks.length}',
                              ),

                            // Recurring
                            if (t.isRecurring)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.repeat_rounded,
                                  size: 11,
                                  color: colors.textTertiary,
                                ),
                              ),

                            // Reminder
                            if (t.hasReminder)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  size: 11,
                                  color: AppColors.indigo.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Sticker (right, inline)
              if (t.stickerId != null && t.stickerId!.isNotEmpty) ...[
                const SizedBox(width: 8),
                AppStickerWidget(
                  serverSticker: StoreService.instance.data?.stickerById(t.stickerId!),
                  localSticker: StickerRegistry.findById(t.stickerId!),
                  size: 34,
                  animate: !isCompleted,
                ),
              ],



              // Flag
              if (t.isFlagged) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.bookmark_rounded,
                  size: 14,
                  color: AppColors.gold,
                ),
              ],

              // MIT star
              if (nav.isMIT(t.id)) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.gold,
                ),
              ],
            ],
          ),
        ),
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
        const SizedBox(width: 8),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// XP CHIP OVERLAY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _XPChipOverlay extends StatefulWidget {
  final double left;
  final double top;
  final int xp;

  const _XPChipOverlay({
    required this.left,
    required this.top,
    required this.xp,
  });

  @override
  State<_XPChipOverlay> createState() => __XPChipOverlayState();
}

class __XPChipOverlayState extends State<_XPChipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final offset = Tween<Offset>(
          begin: Offset(0, 0),
          end: const Offset(0, -60),
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

        final opacity = Tween<double>(begin: 1, end: 0)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

        return Positioned(
          left: widget.left + offset.value.dx,
          top: widget.top + offset.value.dy,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${widget.xp} XP',
                  style: AppTypography.labelMD.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CELEBRATION STICKER OVERLAY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CelebrationStickerOverlay extends StatefulWidget {
  const _CelebrationStickerOverlay();

  static void show(BuildContext context) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationStickerOverlay(),
    );
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(milliseconds: 1500), entry.remove);
  }

  @override
  State<_CelebrationStickerOverlay> createState() =>
      _CelebrationStickerOverlayState();
}

class _CelebrationStickerOverlayState extends State<_CelebrationStickerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final scale = Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
        final opacity = Tween<double>(begin: 1, end: 0)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

        return Center(
          child: Opacity(
            opacity: opacity.value,
            child: Transform.scale(
              scale: scale.value,
              child: AppStickerWidget(
                assetPath: AppStickers.celebrationPath,
                size: 80,
                animate: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
