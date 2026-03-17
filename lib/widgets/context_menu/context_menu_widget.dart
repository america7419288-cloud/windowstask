import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../theme/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'context_menu_item.dart';
import 'context_menu_divider.dart';
import 'priority_submenu.dart';
import 'move_to_list_submenu.dart';
import 'context_menu_controller.dart';

class ContextMenuWidget extends StatefulWidget {
  final Task task;
  final TaskProvider taskProvider;
  final ListProvider listProvider;
  final VoidCallback onDismiss;
  final Offset position;
  final bool openSubmenuLeft;
  final bool openSubmenuUp;

  const ContextMenuWidget({
    super.key,
    required this.task,
    required this.taskProvider,
    required this.listProvider,
    required this.onDismiss,
    required this.position,
    required this.openSubmenuLeft,
    required this.openSubmenuUp,
  });

  @override
  State<ContextMenuWidget> createState() => _ContextMenuWidgetState();
}

class _ContextMenuWidgetState extends State<ContextMenuWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeAnd(VoidCallback action) async {
    // Reverse animation for snappy dismissal
    await _animationController.reverse(from: 1.0);
    action();
    widget.onDismiss();
  }

  // Helper handles submenu hovering to delay appearance
  void _handleSubmenuHover(BuildContext context, String identifier, WidgetBuilder builder) {
    CustomContextMenuController.scheduleSubmenu(
      identifier: identifier,
      context: context,
      parentPosition: widget.position,
      menuWidth: 220, // fixed width
      openLeft: widget.openSubmenuLeft,
      openUp: widget.openSubmenuUp,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          // We set origin so it scales from the click point natively. 
          // The click point is top-left if not flipped.
          alignment: Alignment.topLeft, 
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // Listen for Escape key to close
          if (event.logicalKey.keyLabel == 'Escape') {
            _closeAnd(() {});
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 220,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: colors.isDark 
                ? const Color(0xFF242426).withOpacity(0.94)
                : const Color(0xFFF8F8FC).withOpacity(0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: colors.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08), 
                width: 0.5),
            boxShadow: [
              BoxShadow(
                color: colors.isDark ? Colors.black.withOpacity(0.40) : Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: colors.isDark ? Colors.black.withOpacity(0.20) : Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAnimatedItem(
                    index: 0,
                    child: ContextMenuItem(
                      icon: widget.task.isCompleted ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.checkCircle(),
                      label: widget.task.isCompleted ? 'Mark Incomplete' : 'Mark as Complete',
                      onHoverAction: () => CustomContextMenuController.hideSubmenu(),
                      onTap: () => _closeAnd(() => widget.taskProvider.toggleComplete(widget.task.id)),
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 1,
                    child: const ContextMenuDivider(),
                  ),
                  _buildAnimatedItem(
                    index: 2,
                    child: ContextMenuItem(
                      icon: widget.task.isFlagged ? PhosphorIcons.flag(PhosphorIconsStyle.fill) : PhosphorIcons.flag(),
                      label: widget.task.isFlagged ? 'Remove Flag' : 'Add Flag',
                      onHoverAction: () => CustomContextMenuController.hideSubmenu(),
                      onTap: () => _closeAnd(() => widget.taskProvider.toggleFlag(widget.task.id)),
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 3,
                    child: const ContextMenuDivider(),
                  ),
                  _buildAnimatedItem(
                    index: 4,
                    child: ContextMenuItem(
                      icon: PhosphorIcons.chartBar(),
                      label: 'Priority',
                      trailing: Icon(PhosphorIcons.caretRight(), size: 12, color: colors.textSecondary),
                      onHoverAction: () => _handleSubmenuHover(
                        context, 'priority',
                        (ctx) => PrioritySubmenu(
                          currentPriority: widget.task.priority,
                          onSelect: (p) => _closeAnd(() => widget.taskProvider.updatePriority(widget.task.id, p)),
                        ),
                      ),
                      onTap: () {}, // Submenu opening is hover-based 
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 5,
                    child: ContextMenuItem(
                      icon: PhosphorIcons.calendarBlank(),
                      label: 'Set Due Date',
                      onHoverAction: () => CustomContextMenuController.hideSubmenu(),
                      onTap: () => _closeAnd(() => _handleDateSelection(context)),
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 6,
                    child: ContextMenuItem(
                      icon: PhosphorIcons.folderOpen(),
                      label: 'Move to List',
                      trailing: Icon(PhosphorIcons.caretRight(), size: 12, color: colors.textSecondary),
                      onHoverAction: () => _handleSubmenuHover(
                        context, 'list',
                        (ctx) => MoveToListSubmenu(
                          activeLists: widget.listProvider.activeLists,
                          currentListId: widget.task.listId,
                          onSelect: (lId) => _closeAnd(() => widget.taskProvider.moveToList(widget.task.id, lId)),
                        ),
                      ),
                      onTap: () {},
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 7,
                    child: const ContextMenuDivider(),
                  ),
                  _buildAnimatedItem(
                    index: 8,
                    child: ContextMenuItem(
                      icon: PhosphorIcons.trash(),
                      label: 'Delete Task',
                      isDestructive: true,
                      onHoverAction: () => CustomContextMenuController.hideSubmenu(),
                      onTap: () => _closeAnd(() {
                        widget.taskProvider.moveToTrash(widget.task.id);
                        // The Undo Snackbar is handled in task_card.dart when this action completes
                        // because we need the card's BuildContext to show it securely.
                      }),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Staggers children in by delaying animations per index
  Widget _buildAnimatedItem({required int index, required Widget child}) {
    // Math logic matching exact spec: fades + slides up 4px with 18ms delay per row
    final delay = index * 0.018; 
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay.clamp(0.0, 1.0), (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
        )
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay.clamp(0.0, 1.0), (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
          )
        ),
        child: child,
      ),
    );
  }

  Future<void> _handleDateSelection(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.task.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Theme.of(context).colorScheme.primary, // matches AppTheme wrapper blue/accent
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      widget.taskProvider.updateDueDate(widget.task.id, date);
    }
  }
}
