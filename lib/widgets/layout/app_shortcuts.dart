import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';

// ── Intent classes ────────────────────────────────────────────────────────────
class NewTaskIntent extends Intent { const NewTaskIntent(); }
class SearchIntent extends Intent { const SearchIntent(); }
class SettingsIntent extends Intent { const SettingsIntent(); }
class ToggleCompleteIntent extends Intent { const ToggleCompleteIntent(); }
class CloseDetailIntent extends Intent { const CloseDetailIntent(); }

class AppShortcuts extends StatelessWidget {
  final Widget child;
  const AppShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const NewTaskIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta,    LogicalKeyboardKey.keyN): const NewTaskIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta,    LogicalKeyboardKey.keyF): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma): const SettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta,    LogicalKeyboardKey.comma): const SettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const CloseDetailIntent(),
        LogicalKeySet(LogicalKeyboardKey.space):  const ToggleCompleteIntent(),
      },
      child: Actions(
        actions: {
          NewTaskIntent: CallbackAction<NewTaskIntent>(
            onInvoke: (_) {
              context.read<NavigationProvider>().openSearch();
              return null;
            },
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (_) {
              context.read<NavigationProvider>().openSearch();
              return null;
            },
          ),
          SettingsIntent: CallbackAction<SettingsIntent>(
            onInvoke: (_) {
              context.read<NavigationProvider>().selectNav('settings');
              return null;
            },
          ),
          CloseDetailIntent: CallbackAction<CloseDetailIntent>(
            onInvoke: (_) {
              final nav = context.read<NavigationProvider>();
              if (nav.isDetailPanelOpen) {
                nav.closeDetailPanel();
              } else if (nav.isSearchOpen) {
                nav.closeSearch();
              }
              return null;
            },
          ),
          ToggleCompleteIntent: CallbackAction<ToggleCompleteIntent>(
            onInvoke: (_) {
              final nav = context.read<NavigationProvider>();
              if (nav.selectedTaskId != null) {
                context.read<TaskProvider>().toggleComplete(nav.selectedTaskId!);
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
