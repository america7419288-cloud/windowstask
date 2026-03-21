import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class WindowDragArea extends StatelessWidget {
  final Widget child;
  const WindowDragArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Uses window_manager's DragToMoveArea to make the wrapped widget act as a window handle
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          windowManager.startDragging();
        },
        onDoubleTap: () async {
          if (await windowManager.isMaximized()) {
            windowManager.unmaximize();
          } else {
            windowManager.maximize();
          }
        },
        child: child,
      ),
    );
  }
}

void handleWindowAction(String action) {
  switch (action) {
    case 'close':
      appWindow.close();
      break;
    case 'minimize':
      appWindow.minimize();
      break;
    case 'maximize':
      appWindow.maximizeOrRestore();
      break;
  }
}
