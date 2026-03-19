import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sticker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/task.dart';
import '../../models/subtask.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/celebration_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import 'shared/custom_checkbox.dart';
import '../../painters/confetti_painter.dart';
import '../context_menu/context_menu_controller.dart';
import '../../data/sticker_packs.dart';
import '../shared/sticker_widget.dart';
import '../shared/deco_sticker.dart';
import '../../data/app_stickers.dart';

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

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final nav = context.watch<NavigationProvider>();
    final isCompleted = t.isCompleted;
    final accent = Theme.of(context).colorScheme.primary;
    final priorityColor = AppColors.getPriorityColor(t.priority);

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
        onLongPress: () {
          context.read<NavigationProvider>().enterSelectionMode(t.id);
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
            }
          }
        },
        child: Opacity(
          opacity: isCompleted && !_justCompleted ? 0.6 : 1.0,
          child: Stack(
            children: [
              // 1. The main card container
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: nav.isTaskSelected(t.id) ? accent.withValues(alpha: 0.06) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected || nav.isTaskSelected(t.id) ? accent : AppColors.border,
                    width: widget.isSelected || nav.isTaskSelected(t.id) ? 1.5 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000), // 0.08
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Color(0x0A000000), // 0.04
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.taskTitle.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        decorationColor: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
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
                            if (t.dueDate != null || t.tags.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildMetadataRow(context, t),
                            ],
                          ],
                        ),
                      ),
                      // Bottom priority bar
                      if (t.priority != Priority.none)
                        Container(
                          height: 4,
                          color: priorityColor,
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Priority dot or Selection Indicator (Top-left)
              if (nav.isSelectionMode)
                Positioned(
                  top: 16,
                  left: 16,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: nav.isTaskSelected(t.id) ? accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nav.isTaskSelected(t.id) ? accent : context.appColors.textTertiary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: nav.isTaskSelected(t.id)
                        ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                        : null,
                  ),
                )
              else if (t.priority != Priority.none && !isCompleted)
                Positioned(
                  top: 16,
                  left: 20,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // 3. Completed checkmark overlay
              if (isCompleted)
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 32,
                      color: accent,
                    ),
                  ),
                ),

              // 4. Sticker (Bottom-right)
              if (t.stickerId != null && t.stickerId!.isNotEmpty)
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: _StickerBadge(stickerId: t.stickerId!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, Task t) {
    final colors = context.appColors;
    // metadata row implementation...
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (t.dueDate != null)
           _MetaChip(
            icon: PhosphorIcons.calendarBlank(),
            label: AppDateUtils.formatDueDate(t.dueDate!, t.dueHour, t.dueMinute),
            color: AppColors.textMuted,
          ),
        if (t.hasReminder)
          Icon(Icons.notifications_rounded, size: 10, color: colors.textTertiary),
        if (t.isRecurring)
          Icon(Icons.repeat_rounded, size: 10, color: colors.textTertiary),
      ],
    );
  }
}

  Widget _buildTopSection(BuildContext context, Task t, AppColorsExtension colors, Color accent, bool isCompleted, bool isOverdue) {
    final nav = context.watch<NavigationProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Indicator or Dot
              if (nav.isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: nav.isTaskSelected(t.id) ? accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nav.isTaskSelected(t.id) ? accent : colors.textTertiary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: nav.isTaskSelected(t.id)
                        ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                        : null,
                  ),
                )
              else
                const SizedBox(width: 8),
              const SizedBox(width: 10),

              // Task name
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySemibold.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.3,
                          color: isCompleted ? colors.textTertiary : colors.textPrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: colors.textTertiary,
                        ),
                      ),
                    ),
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
              ),

              // Expand arrow
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.read<NavigationProvider>().selectTask(t.id),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: colors.textQuaternary,
                ),
              ),
            ],
          ),

          // Metadata row
          if (t.dueDate != null || t.tags.isNotEmpty || t.isFlagged)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 5),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (t.dueDate != null)
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      label: AppDateUtils.formatDueDate(t.dueDate!, t.dueHour, t.dueMinute),
                      color: t.isOverdue && !isCompleted ? AppColors.red : colors.textTertiary,
                    ),
                  if (t.hasReminder)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.notifications_rounded, size: 10, color: colors.textTertiary),
                    ),
                  if (t.isRecurring)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.repeat_rounded, size: 10, color: colors.textTertiary),
                    ),
                  if (t.isFlagged)
                    const _MetaChip(
                      icon: Icons.bookmark_rounded,
                      label: 'Flagged',
                      color: AppColors.orange,
                    ),
                  ...t.tags.take(2).map((tagId) {
                    final tag = context.read<TagProvider>().getById(tagId);
                    if (tag == null) return const SizedBox.shrink();
                    return _TagPill(tagName: tag.name);
                  }),
                  if (t.tags.length > 2)
                    _MetaChip(
                      label: '+${t.tags.length - 2}',
                      color: colors.textQuaternary,
                    ),
                ],
              ),
            ),
        ],
      ),
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

class _PriorityBar extends StatelessWidget {
  final Priority priority;
  const _PriorityBar({required this.priority});

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.none:   return Colors.transparent;
      case Priority.low:    return AppColors.priorityLow;
      case Priority.medium: return AppColors.priorityMedium;
      case Priority.high:   return AppColors.priorityHigh;
      case Priority.urgent: return AppColors.priorityUrgent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      width: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
        boxShadow: priority == Priority.urgent
            ? [
                BoxShadow(
                  color: AppColors.priorityUrgent.withValues(alpha: 0.5),
                  blurRadius: 8,
                )
              ]
            : null,
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
    final sticker = StickerRegistry.findById(stickerId);
    if (sticker == null) return const SizedBox.shrink();

    return StickerWidget(
      sticker: sticker,
      size: 28,
      animate: true,
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
    final stickers = [
      AppStickers.celebration,
    ];
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
