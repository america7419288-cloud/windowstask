import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/constants.dart';

class AppShortcuts extends StatelessWidget {
  final Widget child;
  const AppShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // Search — both Ctrl and Meta (Mac)
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            () => context.read<NavigationProvider>().openSearch(),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            () => context.read<NavigationProvider>().openSearch(),

        // Settings
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            () => context.read<NavigationProvider>().selectNav(AppConstants.navSettings),
        const SingleActivator(LogicalKeyboardKey.comma, meta: true):
            () => context.read<NavigationProvider>().selectNav(AppConstants.navSettings),

        // Undo
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            () => context.read<TaskProvider>().undo(),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            () => context.read<TaskProvider>().undo(),

        // Escape — close detail panel or search
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final nav = context.read<NavigationProvider>();
          if (nav.isDetailPanelOpen) {
            nav.closeDetailPanel();
          } else if (nav.isSearchOpen) {
            nav.closeSearch();
          }
        },

        // Space — toggle complete on selected task
        const SingleActivator(LogicalKeyboardKey.space): () {
          final nav = context.read<NavigationProvider>();
          if (nav.selectedTaskId != null) {
            context.read<TaskProvider>().toggleComplete(nav.selectedTaskId!);
          }
        },
      },
      child: Focus(
        autofocus: true,
        // canRequestFocus ensures the Focus node grabs keyboard events
        // even if a text field is not active
        canRequestFocus: false,
        child: child,
      ),
    );
  }
}
