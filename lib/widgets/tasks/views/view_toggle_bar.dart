import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';

class ViewToggleBar extends StatelessWidget {
  const ViewToggleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final current = settings.currentLayout;
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TaskViewLayout.values.map((layout) {
        final isActive = layout == current;
        return Tooltip(
          message: _label(layout),
          waitDuration: const Duration(milliseconds: 500),
          child: GestureDetector(
            onTap: () {
              context.read<NavigationProvider>().setLayoutForCurrentSection(layout);
              settings.setViewLayout(layout);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? accent.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isActive ? _iconFilled(layout) : _iconOutline(layout),
                size: 14,
                color: isActive ? accent : colors.textTertiary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _label(TaskViewLayout l) {
    switch (l) {
      case TaskViewLayout.list:     return 'List';
      case TaskViewLayout.grid:     return 'Grid';
      case TaskViewLayout.kanban:   return 'Kanban';
      case TaskViewLayout.compact:  return 'Compact';
      case TaskViewLayout.magazine: return 'Magazine';
    }
  }

  IconData _iconOutline(TaskViewLayout l) {
    switch (l) {
      case TaskViewLayout.list:     return PhosphorIcons.listBullets();
      case TaskViewLayout.grid:     return PhosphorIcons.squaresFour();
      case TaskViewLayout.kanban:   return PhosphorIcons.kanban();
      case TaskViewLayout.compact:  return PhosphorIcons.rows();
      case TaskViewLayout.magazine: return PhosphorIcons.newspaper();
    }
  }

  IconData _iconFilled(TaskViewLayout l) {
    switch (l) {
      case TaskViewLayout.list:     return PhosphorIcons.listBullets(PhosphorIconsStyle.fill);
      case TaskViewLayout.grid:     return PhosphorIcons.squaresFour(PhosphorIconsStyle.fill);
      case TaskViewLayout.kanban:   return PhosphorIcons.kanban(PhosphorIconsStyle.fill);
      case TaskViewLayout.compact:  return PhosphorIcons.rows(PhosphorIconsStyle.fill);
      case TaskViewLayout.magazine: return PhosphorIcons.newspaper(PhosphorIconsStyle.fill);
    }
  }
}
