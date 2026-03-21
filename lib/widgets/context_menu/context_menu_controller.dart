import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import 'context_menu_widget.dart';

class CustomContextMenuController {
  static OverlayEntry? _currentEntry;
  static OverlayEntry? _currentSubmenu;
  static Timer? _submenuSettleTimer;
  static String? _activeSubmenuId;

  static void show({
    required BuildContext context,
    required Offset position,
    required Task task,
    required TaskProvider taskProvider,
    required ListProvider listProvider,
  }) {
    hide(); // close any existing

    _currentEntry = OverlayEntry(
      builder: (_) => ContextMenuOverlay(
        position: position,
        task: task,
        taskProvider: taskProvider,
        listProvider: listProvider,
        onDismiss: hide,
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  static void hide() {
    _submenuSettleTimer?.cancel();
    _currentSubmenu?.remove();
    _currentSubmenu = null;
    _activeSubmenuId = null;

    _currentEntry?.remove();
    _currentEntry = null;
  }

  // --- Submenu Logic ---
  
  static void scheduleSubmenu({
    required String identifier,
    required BuildContext context,
    required Offset parentPosition,
    required double menuWidth,
    required bool openLeft,
    required bool openUp,
    required WidgetBuilder builder,
  }) {
    if (_activeSubmenuId == identifier) return; // already active

    // Cancel old timer, hide old submenu
    _submenuSettleTimer?.cancel();

    _submenuSettleTimer = Timer(const Duration(milliseconds: 80), () {
      _showSubmenuInner(
        context: context,
        identifier: identifier,
        parentPosition: parentPosition,
        menuWidth: menuWidth,
        openLeft: openLeft,
        openUp: openUp,
        builder: builder,
      );
    });
  }

  static void hideSubmenu() {
    _submenuSettleTimer?.cancel();
    if (_currentSubmenu != null) {
      _currentSubmenu?.remove();
      _currentSubmenu = null;
      _activeSubmenuId = null;
    }
  }

  static void _showSubmenuInner({
    required BuildContext context,
    required String identifier,
    required Offset parentPosition,
    required double menuWidth,
    required bool openLeft,
    required bool openUp,
    required WidgetBuilder builder,
  }) {
    _currentSubmenu?.remove();
    _activeSubmenuId = identifier;

    // Use 4px gap edge offset
    // In ContextMenuWidget we don't have exact row offsets cleanly available without GlobalKeys.
    // For simplicity & robust visual alignment, submenus pop next to the main menu container.
    // The main menu is known width 220. 
    const double menuTopPadding = 6;
    const double itemHeight = 34;
    const double dividerHeight = 9;

    double itemOffsetY;
    if (identifier == 'priority') {
      itemOffsetY = menuTopPadding + (itemHeight * 2) + dividerHeight;
    } else {
      itemOffsetY = menuTopPadding + (itemHeight * 4) + (dividerHeight * 2);
    }

    final media = MediaQuery.of(context).size;
    const double submenuWidth = 220;
    const double submenuHeight = 200; // estimated max height

    double shiftX = parentPosition.dx + menuWidth + 4;
    if (shiftX + submenuWidth > media.width) {
      shiftX = parentPosition.dx - submenuWidth - 4;
    }

    double shiftY = parentPosition.dy + itemOffsetY;
    if (shiftY + submenuHeight > media.height) {
      shiftY = media.height - submenuHeight - 8;
    }
    if (shiftY < 8) shiftY = 8;

    _currentSubmenu = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned(
            left: shiftX,
            top: shiftY,
            // Wrap the builder in a custom Scale transition logic to stagger open
            child: _SubmenuContainerWrapper(child: builder(ctx)),
          ),
        ],
      )
    );

    Overlay.of(context).insert(_currentSubmenu!);
  }
}

class _SubmenuContainerWrapper extends StatefulWidget {
  final Widget child;
  const _SubmenuContainerWrapper({required this.child});
  @override
  State<_SubmenuContainerWrapper> createState() => _SubmenuContainerWrapperState();
}
class _SubmenuContainerWrapperState extends State<_SubmenuContainerWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..forward();
  }
  @override
  void dispose() { _anim.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _anim,
        child: widget.child,
      ),
    );
  }
}

class ContextMenuOverlay extends StatelessWidget {
  final Offset position;
  final Task task;
  final TaskProvider taskProvider;
  final ListProvider listProvider;
  final VoidCallback onDismiss;

  const ContextMenuOverlay({
    super.key,
    required this.position,
    required this.task,
    required this.taskProvider,
    required this.listProvider,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Edge Detection Logic
    final media = MediaQuery.of(context).size;
    
    // Exact menu dimensions
    const menuWidth = 220.0;
    const menuHeight = 270.0; // Approx ht of our list + dividers

    bool openLeft = false;
    bool openUp = false;

    double computedX = position.dx;
    double computedY = position.dy;

    if (computedX + menuWidth > media.width) {
      computedX = position.dx - menuWidth;
      openLeft = true;
    }
    
    if (computedY + menuHeight > media.height) {
      computedY = position.dy - menuHeight;
      openUp = true;
    }

    // Constraints to never go fully offscreen if somehow window size is extremely tiny.
    computedX = computedX.clamp(0.0, media.width - menuWidth);
    computedY = computedY.clamp(0.0, media.height - menuHeight);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: computedX,
          top: computedY,
          child: ContextMenuWidget(
            task: task,
            taskProvider: taskProvider,
            listProvider: listProvider,
            onDismiss: onDismiss,
            position: Offset(computedX, computedY), // Real drawn anchor point
            openSubmenuLeft: openLeft,
            openSubmenuUp: openUp,
          ),
        ),
      ],
    );
  }
}
