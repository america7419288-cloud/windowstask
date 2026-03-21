import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/constants.dart';

// --- Intents ---
class SearchIntent extends Intent { const SearchIntent(); }
class SettingsIntent extends Intent { const SettingsIntent(); }
class UndoIntent extends Intent { const UndoIntent(); }
class EscapeIntent extends Intent { const EscapeIntent(); }

class AppShortcuts extends StatelessWidget {
  final Widget child;
  const AppShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        // Search — Ctrl+F or Meta+F
        LogicalKeySet(LogicalKeyboardKey.keyF, LogicalKeyboardKey.control): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyF, LogicalKeyboardKey.meta): const SearchIntent(),

        // Settings — Ctrl+, or Meta+,
        LogicalKeySet(LogicalKeyboardKey.comma, LogicalKeyboardKey.control): const SettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.comma, LogicalKeyboardKey.meta): const SettingsIntent(),

        // Undo — Ctrl+Z or Meta+Z
        LogicalKeySet(LogicalKeyboardKey.keyZ, LogicalKeyboardKey.control): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyZ, LogicalKeyboardKey.meta): const UndoIntent(),

        // Escape
        LogicalKeySet(LogicalKeyboardKey.escape): const EscapeIntent(),
      },
      child: Actions(
        actions: {
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (_) => context.read<NavigationProvider>().openSearch(),
          ),
          SettingsIntent: CallbackAction<SettingsIntent>(
            onInvoke: (_) => context.read<NavigationProvider>().selectNav(AppConstants.navSettings),
          ),
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) => context.read<TaskProvider>().undo(),
          ),
          EscapeIntent: CallbackAction<EscapeIntent>(
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
        },
        child: Focus(
          autofocus: true,
          canRequestFocus: false,
          child: child,
        ),
      ),
    );
  }
}
