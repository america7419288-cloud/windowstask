import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class ResizableSidebar extends StatefulWidget {
  final Widget child;
  const ResizableSidebar({super.key, required this.child});

  @override
  State<ResizableSidebar> createState() => _ResizableSidebarState();
}

class _ResizableSidebarState extends State<ResizableSidebar> {
  static const double minWidth = 180;
  static const double maxWidth = 320;
  static const double handleWidth = 4;

  late double _width;
  bool _showHandle = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _width = context.read<SettingsProvider>().sidebarWidth;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _width,
          child: widget.child,
        ),
        // Drag handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          onEnter: (_) => setState(() => _showHandle = true),
          onExit: (_) => setState(() => _showHandle = false),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _width = (_width + details.delta.dx).clamp(minWidth, maxWidth);
              });
            },
            onHorizontalDragEnd: (_) {
              context.read<SettingsProvider>().setSidebarWidth(_width);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: handleWidth,
              color: _showHandle
                  ? accent.withOpacity(0.4)
                  : Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
