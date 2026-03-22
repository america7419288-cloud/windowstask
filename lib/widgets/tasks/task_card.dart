import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../../screens/task_detail_page.dart';
import 'package:provider/provider.dart';
import '../../models/sticker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/task.dart';
import '../../models/subtask.dart';
import '../../models/achievement.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/celebration_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import 'shared/custom_checkbox.dart';
import 'shared/card_helpers.dart';
import '../../painters/confetti_painter.dart';
import '../context_menu/context_menu_controller.dart';
import '../../data/sticker_packs.dart';
import '../shared/sticker_widget.dart';
import '../../services/store_service.dart';
import '../shared/deco_sticker.dart';
import '../../data/app_stickers.dart';
import 'package:flutter/services.dart';
import 'save_template_dialog.dart';

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
    final tp = context.read<TaskProvider>();
    tp.toggleComplete(
      widget.task.id,
      celebration: context.read<CelebrationProvider>(),
    );

    if (!wasCompleted) {
      setState(() {
        _justCompleted = true;
        _completionFlash = true;
      });

      // Award XP via UserProvider
      context.read<UserProvider>().recordTaskCompletion(widget.task);

      // Calculate XP and show floating chip
      int xp = XPValues.completeTask;
      if (widget.task.priority == Priority.high) xp = XPValues.completeHigh;
      if (widget.task.priority == Priority.urgent) xp = XPValues.completeUrgent;
      _showXPChip(context, xp);

      // Show celebration sticker
      _CelebrationStickerOverlay.show(context);

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

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();
    final colors = context.appColors;
    final isCompleted = t.isCompleted;
    final accent = Theme.of(context).colorScheme.primary;
    final priorityColor = isCompleted ? const Color(0xFF94A3B8) : AppColors.getPriorityColor(t.priority);

    return OpenContainer(
      useRootNavigator: true,
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: colors.background,
      tappable: false, // Handled manually by our GestureDetector
      onClosed: (_) {
        if (mounted) {
          context.read<NavigationProvider>().closeDetail();
        }
      },
      openBuilder: (context, action) => TaskDetailPage(task: t),
      closedBuilder: (context, action) {
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
            onLongPress: () async {
              final saved = await SaveTemplateDialog.show(context, t);
              if (saved) {
                HapticFeedback.mediumImpact();
              }
            },
            onTap: () {
              CustomContextMenuController.hide();
              final nav = context.read<NavigationProvider>();
              if (nav.isSelectionMode) {
                nav.toggleTaskSelection(t.id);
              } else {
                if (widget.onTap != null) {
                  widget.onTap!();
                } else {
                  nav.selectTask(t.id);
                  if (t.isDeleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Restore task to edit it', style: TextStyle(color: Colors.white)),
                        backgroundColor: colors.isDark ? const Color(0xFF333333) : const Color(0xFF222222),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    action(); // Trigger OpenContainer
                  }
                }
              }
            },
            child: RepaintBoundary(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isCompleted && !_justCompleted ? 0.65 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              decoration: BoxDecoration(
                color: _hovered || nav.isTaskSelected(t.id)
                    ? (colors.isDark ? AppColors.surfaceContainerHighDk : AppColors.surfaceContainerLowest)
                    : (colors.isDark ? AppColors.surfaceContainerDk : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                // Ambient shadow ONLY on hover/selected
                boxShadow: (_hovered || nav.isTaskSelected(t.id)) && !colors.isDark
                    ? AppColors.ambientShadow(
                        opacity: 0.06,
                        blur: 20,
                        offset: const Offset(0, 4),
                      )
                    : [],
                // Ghost border on selected only
                border: nav.isTaskSelected(t.id) ? AppColors.ghostBorder() : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selection or Checkbox
                        if (nav.isSelectionMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: nav.isTaskSelected(t.id) ? accent : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: nav.isTaskSelected(t.id)
                                      ? accent
                                      : colors.textTertiary.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: nav.isTaskSelected(t.id)
                                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                  : null,
                            ),
                          )
                        else if (t.isDeleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 12),
                            child: Icon(
                              PhosphorIcons.trash(),
                              size: 20,
                              color: colors.textTertiary.withValues(alpha: 0.5),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 12),
                            child: CustomCheckbox(
                              value: isCompleted,
                              onChanged: (_) => _handleComplete(),
                              activeColor: accent,
                            ),
                          ),
                        
                        // Title Text + Inline elements
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Priority dot (only if not in selection mode and not completed)
                                  if (!nav.isSelectionMode && t.priority != Priority.none && !isCompleted)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: priorityColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: isCompleted ? colors.textTertiary : AppColors.onSurface,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        decorationColor: colors.textTertiary,
                                      ),
                                    ),
                                  ),
  
                                  // Inline Sticker
                                  if (t.stickerId != null && t.stickerId!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Consumer<StoreService>(
                                        builder: (context, store, _) {
                                          final serverSticker = store.data?.stickerById(t.stickerId!);
                                          final localSticker = StickerRegistry.findById(t.stickerId!);
                                          return StickerWidget(
                                            serverSticker: serverSticker,
                                            localSticker: localSticker ?? AppStickers.detailDefault,
                                            size: 28,
                                            animate: true,
                                          );
                                        },
                                      ),
                                    ),
                                  
                                  // Flag icon
                                  if (t.isFlagged)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Icon(
                                        Icons.bookmark_rounded,
                                        size: 14,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                  
                                  // MIT star
                                  if (nav.isMIT(t.id))
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: Color(0xFFFFD60A),
                                      ),
                                    ),
                                ],
                              ),
                              
                              // Metadata row
                              if (t.dueDate != null || t.tags.isNotEmpty || t.isRecurring || t.hasReminder)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _buildMetadataRow(context, t),
                                ),
                            ],
                          ),
                        ),
                        
                        // Trailing Actions for Deleted tasks
                        if (t.isDeleted)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(PhosphorIcons.arrowCounterClockwise(), size: 20),
                                  tooltip: 'Restore Task',
                                  color: accent,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => context.read<TaskProvider>().restoreTask(t.id),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(PhosphorIcons.trash(), size: 20),
                                  tooltip: 'Delete Permanently',
                                  color: colors.isDark ? Colors.red[400] : AppColors.red,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => context.read<TaskProvider>().permanentlyDelete(t.id),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
  
                    // Subtasks Section
                    if (t.subtasks.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: _DashedDivider(),
                      ),
                      _buildSubtasksSection(context, t, colors, accent, isCompleted),
                    ],
                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildMetadataRow(BuildContext context, Task t) {
    final colors = context.appColors;
    
    String formatTime(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $p';
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (t.isCompleted && t.completedAt != null)
          _MetaChip(
            icon: Icons.check_circle_outline,
            label: 'Completed at ${formatTime(t.completedAt!)}',
            color: AppColors.tertiary,
          ),
        if (!t.isCompleted && t.dueDate != null)
          _MetaChip(
            icon: PhosphorIcons.calendarBlank(),
            label: AppDateUtils.formatDueDate(t.dueDate!, t.dueHour, t.dueMinute),
            color: AppColors.textMuted,
          ),
        if (t.hasReminder)
          Icon(Icons.notifications_rounded, size: 10, color: colors.textTertiary),
        if (t.isRecurring)
          Icon(Icons.repeat_rounded, size: 10, color: colors.textTertiary),
        ...t.tags.take(2).map((tagId) {
          final tag = context.read<TagProvider>().getById(tagId);
          if (tag == null) return const SizedBox.shrink();
          return _TagPill(tagName: tag.name);
        }),
      ],
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
    return Consumer<StoreService>(
      builder: (context, store, _) {
        final serverSticker = store.data?.stickerById(stickerId);
        final localSticker = StickerRegistry.findById(stickerId);
        if (serverSticker == null && localSticker == null) return const SizedBox.shrink();

        return StickerWidget(
          serverSticker: serverSticker,
          localSticker: localSticker,
          size: 34,
          animate: true,
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _MetaChip({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color.withValues(alpha: 0.55)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.metadata.copyWith(
              color: color.withValues(alpha: 0.55),
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
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$tagName',
        style: AppTypography.metadata.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: accent,
        ),
      ),
    );
  }
}

class _CelebrationStickerOverlay extends StatefulWidget {
  const _CelebrationStickerOverlay();

  static void show(BuildContext context) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => const _CelebrationStickerOverlay(),
    );
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  @override
  State<_CelebrationStickerOverlay> createState() => _CelebrationStickerOverlayState();
}

class _CelebrationStickerOverlayState extends State<_CelebrationStickerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _slide;
  late Sticker _sticker;

  @override
  void initState() {
    super.initState();
    final stickers = AppStickers.celebrationStickers;
    _sticker = stickers[DateTime.now().millisecond % stickers.length];

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _slide = Tween(begin: 0.0, end: -40.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _slide.value),
              child: Transform.scale(
                scale: _scale.value,
                child: DecoSticker(
                  sticker: _sticker,
                  size: 160,
                  animate: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── XP Chip Overlay ─────────────────────────────────────────────────────────
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
  State<_XPChipOverlay> createState() => _XPChipOverlayState();
}

class _XPChipOverlayState extends State<_XPChipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideUp;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideUp = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: AppColors.gradientSuccess,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.ambientShadow(
              opacity: 0.15,
              blur: 12,
              offset: const Offset(0, 4),
            ),
          ),
          child: Text(
            '+${widget.xp} XP',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.onTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineSticker extends StatelessWidget {
  final String stickerId;
  const _InlineSticker({required this.stickerId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: CardDesign.background(context),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Consumer<StoreService>(
          builder: (context, store, _) {
            final serverSticker = store.data?.stickerById(stickerId);
            final localSticker = StickerRegistry.findById(stickerId) ?? AppStickers.detailDefault;
            
            return StickerWidget(
              serverSticker: serverSticker,
              localSticker: localSticker,
              size: 24,
              animate: true,
            );
          },
        ),
      ),
    );
  }
}
