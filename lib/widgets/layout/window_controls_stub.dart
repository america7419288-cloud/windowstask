import 'package:flutter/material.dart';

// No-op widget for the web
class WindowDragArea extends StatelessWidget {
  final Widget child;
  const WindowDragArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// No-op traffic actions for the web
void handleWindowAction(String action) {}
