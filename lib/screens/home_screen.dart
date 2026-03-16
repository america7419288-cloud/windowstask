import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/list_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/focus_provider.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../utils/constants.dart';
import '../widgets/sidebar/sidebar.dart';
import '../widgets/tasks/task_list_view.dart';
import '../widgets/tasks/task_detail_panel.dart';
import '../widgets/shared/traffic_light_buttons.dart';
import '../widgets/shared/macos_button.dart';
import '../widgets/focus/focus_timer_overlay.dart';
import 'settings_screen.dart';
import 'insights_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          // focus on quick add bar — handled by QuickAddBar itself
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          context.read<NavigationProvider>().toggleSearch();
        },
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () {
          context.read<NavigationProvider>().selectNav(AppConstants.navSettings);
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          context.read<TaskProvider>().undo();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final nav = context.read<NavigationProvider>();
          if (nav.isDetailPanelOpen) {
            nav.closeDetailPanel();
          } else if (nav.isSearchOpen) {
            nav.closeSearch();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: _HomeLayout(),
      ),
    );
  }
}

class _HomeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, nav, _) {
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

        return Stack(
          children: [
            Row(
              children: [
                const Sidebar(),
                Expanded(
                  child: Column(
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
                ),
                // Right detail panel
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: nav.isDetailPanelOpen ? AppConstants.detailPanelWidth : 0,
                  child: nav.isDetailPanelOpen && nav.selectedTaskId != null
                      ? _DetailPanelWrapper(taskId: nav.selectedTaskId!)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            // Focus timer overlay
            const FocusTimerOverlay(),
          ],
        );
      },
    );
  }
}

class _ContentHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final nav = context.watch<NavigationProvider>();
    final tasks = context.read<TaskProvider>();
    final settings = context.read<SettingsProvider>();

    return Container(
      height: AppConstants.titlebarHeight + 12,
      decoration: BoxDecoration(
        color: colors.isDark
            ? colors.background.withOpacity(0.9)
            : colors.background.withOpacity(0.85),
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            children: [
              // Traffic lights (window drag area)
              Container(
                width: AppConstants.sidebarWidth,
                height: double.infinity,
                padding: const EdgeInsets.only(left: 16),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: TrafficLightButtons(),
                ),
              ),
              // Page title & search
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (!nav.isSearchOpen)
                        Text(
                          nav.pageTitle,
                          style: AppTypography.headline.copyWith(color: colors.textPrimary),
                        ),
                      if (nav.isSearchOpen)
                        Expanded(child: _SearchBar()),
                      if (!nav.isSearchOpen) const Spacer(),
                      // Search toggle
                      if (!nav.isSearchOpen)
                        _HeaderBtn(
                          icon: Icons.search_rounded,
                          onTap: () => nav.openSearch(),
                          tooltip: 'Search (Ctrl+F)',
                        ),
                      const SizedBox(width: 8),
                      // Add Task button
                      if (nav.selectedNavItem != AppConstants.navSettings &&
                          nav.selectedNavItem != AppConstants.navInsights &&
                          nav.selectedNavItem != AppConstants.navTrash)
                        GestureDetector(
                          onTap: () {
                            // Will focus quick add bar
                          },
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
                                Text(
                                  'Add Task',
                                  style: AppTypography.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
              color: colors.isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                hintStyle: AppTypography.body.copyWith(color: colors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: colors.textSecondary),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
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
          child: Text('Cancel', style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.primary,
          )),
        ),
      ],
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, required this.onTap, this.tooltip});
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: w) : w;
  }
}

class _DetailPanelWrapper extends StatelessWidget {
  const _DetailPanelWrapper({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final task = tasks.getById(taskId);
    if (task == null) return const SizedBox.shrink();
    return TaskDetailPanel(task: task);
  }
}
