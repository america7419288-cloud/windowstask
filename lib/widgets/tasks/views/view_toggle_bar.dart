import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';

class ViewToggleBar extends StatelessWidget {
  const ViewToggleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final current = settings.currentLayout;
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
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
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isActive ? AppColors.shadowSM(isDark: colors.isDark) : [],
                ),
                child: Icon(
                  isActive ? _iconFilled(layout) : _iconOutline(layout),
                  size: 14,
                  color: isActive ? AppColors.indigo : colors.textTertiary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
