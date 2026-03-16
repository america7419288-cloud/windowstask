import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../utils/constants.dart';
import '../widgets/sidebar/sidebar.dart';
import '../widgets/tasks/task_list_view.dart';
import '../widgets/tasks/task_detail_panel.dart';
import '../widgets/shared/traffic_light_buttons.dart';
import '../widgets/focus/focus_timer_overlay.dart';
import '../widgets/layout/responsive_layout.dart';
import '../widgets/layout/app_shortcuts.dart';
import 'settings_screen.dart';
import 'insights_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShortcuts(
      child: Consumer<NavigationProvider>(
        builder: (context, nav, _) {
          // Build main content area based on nav selection
          Widget mainContent;
          switch (nav.selectedNavItem) {
            case AppConstants.navSettings:
              mainContent = const SettingsScreen();
              break;
            case AppConstants.navInsights:
              mainContent = const InsightsScreen();
              break;
            default:
              mainContent = const TaskListView();
          }

          // Detail panel only when a task is selected
          final showDetail = nav.isDetailPanelOpen && nav.selectedTaskId != null;
          Widget? detailPanel;
          if (showDetail) {
            final task = context.watch<TaskProvider>().getById(nav.selectedTaskId!);
            if (task != null) {
              detailPanel = TaskDetailPanel(task: task);
            }
          }

          return Stack(
            children: [
              ResponsiveLayout(
                sidebar: Column(
                  children: [
                    // Custom TitleBar traffic lights area for desktop
                    const _TitleBarArea(),
                    Expanded(child: const Sidebar()),
                  ],
                ),
                content: Column(
                  children: [
                    _ContentHeader(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: AppConstants.animMedium,
                        child: mainContent,
                      ),
                    ),
                  ],
                ),
                detailPanel: detailPanel,
                showDetailPanel: showDetail,
              ),
              // Floating focus timer
              const FocusTimerOverlay(),
            ],
          );
        },
      ),
    );
  }
}

class _TitleBarArea extends StatelessWidget {
  const _TitleBarArea();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: AppConstants.titlebarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: TrafficLightButtons(),
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final nav = context.watch<NavigationProvider>();

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colors.isDark
            ? colors.background.withOpacity(0.9)
            : colors.background.withOpacity(0.85),
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (!nav.isSearchOpen)
                  Text(nav.pageTitle,
                      style: AppTypography.headline
                          .copyWith(color: colors.textPrimary)),
                if (nav.isSearchOpen) Expanded(child: _SearchBar()),
                if (!nav.isSearchOpen) const Spacer(),
                if (!nav.isSearchOpen)
                  _HeaderBtn(
                    icon: Icons.search_rounded,
                    onTap: () => nav.openSearch(),
                    tooltip: 'Search  Ctrl+F',
                  ),
                const SizedBox(width: 8),
                if (!nav.isSearchOpen &&
                    nav.selectedNavItem != AppConstants.navSettings &&
                    nav.selectedNavItem != AppConstants.navInsights &&
                    nav.selectedNavItem != AppConstants.navTrash)
                  _AddTaskButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {}, // QuickAddBar handles its own focus
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text('Add Task',
                style: AppTypography.body
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.read<NavigationProvider>();
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: colors.isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                hintStyle: AppTypography.body
                    .copyWith(color: colors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 16, color: colors.textSecondary),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 36),
              ),
              onChanged: (q) => nav.updateSearchQuery(q),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            nav.closeSearch();
            _ctrl.clear();
          },
          child: Text('Cancel',
              style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn(
      {required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget w = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: w) : w;
  }
}
