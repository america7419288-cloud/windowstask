import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/task.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/list_provider.dart';
import '../../../providers/celebration_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../context_menu/context_menu_controller.dart';

enum HoverActionsPosition { topRight, bottomBar }

class TaskInteractionWrapper extends StatefulWidget {
  final Task task;
  final Widget child;
  final bool showHoverActions;
  final HoverActionsPosition actionsPosition;

  const TaskInteractionWrapper({
    super.key,
    required this.task,
    required this.child,
    this.showHoverActions = true,
    this.actionsPosition = HoverActionsPosition.topRight,
  });

  @override
  State<TaskInteractionWrapper> createState() => _TaskInteractionWrapperState();
}

class _TaskInteractionWrapperState extends State<TaskInteractionWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // Left click → open detail panel
        onTap: () {
          context.read<NavigationProvider>().selectTask(widget.task.id);
          CustomContextMenuController.hide();
        },
        // Right click → context menu
        onSecondaryTapUp: (details) {
          CustomContextMenuController.show(
            context: context,
            position: details.globalPosition,
            task: widget.task,
            taskProvider: context.read<TaskProvider>(),
            listProvider: context.read<ListProvider>(),
          );
        },
        child: Stack(
          children: [
            widget.child,
            // Hover action buttons
            if (_hovered && widget.showHoverActions)
              widget.actionsPosition == HoverActionsPosition.topRight
                  ? Positioned(
                      top: 8,
                      right: 8,
                      child: _HoverActionBar(task: widget.task),
                    )
                  : Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _HoverActionBottomBar(task: widget.task),
                    ),
          ],
        ),
      ),
    );
  }
}

class _HoverActionBar extends StatelessWidget {
  final Task task;
  const _HoverActionBar({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.85, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox / complete toggle
            _HoverBtn(
              icon: task.isCompleted
                  ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                  : PhosphorIcons.circle(),
              color: task.isCompleted ? AppColors.green : colors.textSecondary,
              onTap: () => context.read<TaskProvider>().toggleComplete(
                task.id,
                celebration: context.read<CelebrationProvider>(),
              ),
              tooltip: task.isCompleted ? 'Mark incomplete' : 'Complete',
            ),
            const SizedBox(width: 2),
            // Flag toggle
            _HoverBtn(
              icon: task.isFlagged
                  ? PhosphorIcons.flag(PhosphorIconsStyle.fill)
                  : PhosphorIcons.flag(),
              color: task.isFlagged ? AppColors.orange : colors.textSecondary,
              onTap: () => context.read<TaskProvider>().toggleFlag(task.id),
              tooltip: task.isFlagged ? 'Remove flag' : 'Flag',
            ),
            const SizedBox(width: 2),
            // Open detail panel
            _HoverBtn(
              icon: PhosphorIcons.arrowSquareOut(),
              color: colors.textSecondary,
              onTap: () => context.read<NavigationProvider>().selectTask(task.id),
              tooltip: 'Open',
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _HoverBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_HoverBtn> createState() => _HoverBtnState();
}

class _HoverBtnState extends State<_HoverBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered ? accent : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverActionBottomBar extends StatelessWidget {
  final Task task;
  const _HoverActionBottomBar({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 28,
      color: accent.withValues(alpha: 0.06),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Complete
          GestureDetector(
            onTap: () => context.read<TaskProvider>().toggleComplete(
              task.id,
              celebration: context.read<CelebrationProvider>(),
            ),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  task.isCompleted
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.circle(),
                  size: 12,
                  color: task.isCompleted ? AppColors.green : colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  task.isCompleted ? 'Undo' : 'Complete',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Flag
          GestureDetector(
            onTap: () => context.read<TaskProvider>().toggleFlag(task.id),
            behavior: HitTestBehavior.opaque,
            child: Icon(
              task.isFlagged
                  ? PhosphorIcons.flag(PhosphorIconsStyle.fill)
                  : PhosphorIcons.flag(),
              size: 12,
              color: task.isFlagged ? AppColors.orange : colors.textSecondary,
            ),
          ),
          const Spacer(),
          // Open detail
          GestureDetector(
            onTap: () => context.read<NavigationProvider>().selectTask(task.id),
            behavior: HitTestBehavior.opaque,
            child: Icon(
              PhosphorIcons.arrowSquareOut(),
              size: 12,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
