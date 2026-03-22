import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/constants.dart';
import '../widgets/sidebar/sidebar.dart';
import '../widgets/tasks/multi_layout_task_view.dart';
import 'task_detail_page.dart';
import 'calendar_screen.dart';
import '../widgets/shared/traffic_light_buttons.dart';
import '../widgets/focus/focus_timer_overlay.dart';
import '../widgets/shared/task_completed_overlay.dart';
import '../providers/celebration_provider.dart';
import '../widgets/layout/responsive_layout.dart';
import '../widgets/layout/app_shortcuts.dart';
import '../widgets/layout/window_controls.dart';
import '../widgets/layout/app_background.dart';
import 'settings_screen.dart';
import 'insights_screen.dart';
import 'dashboard_screen.dart';
import 'store_screen.dart';
import '../providers/user_provider.dart';

import '../services/reminder_service.dart';
import '../widgets/tasks/bulk_action_bar.dart';
import '../widgets/focus/break_screen.dart';
import '../screens/planning_screen.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ReminderService.instance.init(context);
      _checkDailyPlanning();
      
      // Run security integrity check on startup
      if (mounted) {
        await context.read<UserProvider>().init(context);
      }
    });
  }

  void _checkDailyPlanning() async {
    final storage = StorageService.instance;
    final lastPlanning = storage.getLastPlanningDate();
    final now = DateTime.now();
    
    // Auto-trigger if first launch of the day and before noon
    if (lastPlanning == null || !AppDateUtils.isToday(lastPlanning)) {
      if (now.hour < 12) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          storage.saveLastPlanningDate(now);
          PlanningScreen.show(context);
        }
      }
    }
  }

  @override
  void dispose() {
    ReminderService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShortcuts(
      child: Consumer<NavigationProvider>(
          builder: (context, nav, _) {
            final colors = context.appColors;
            Widget mainContent;
            switch (nav.selectedNavItem) {
              case AppConstants.navSettings:
                mainContent = const SettingsScreen();
                break;
              case AppConstants.navInsights:
                mainContent = const InsightsScreen();
                break;
              case AppConstants.navToday:
                mainContent = const DashboardScreen();
                break;
              case AppConstants.navCalendar:
                mainContent = const CalendarScreen();
                break;
              case AppConstants.navStore:
                mainContent = const StoreScreen();
                break;
              default:
                mainContent = const MultiLayoutTaskView();
            }

            // Full-page detail replaces main content
            if (nav.isDetailOpen && nav.selectedTaskId != null) {
              final task = context.watch<TaskProvider>().getById(nav.selectedTaskId!);
              if (task != null) {
                mainContent = TaskDetailPage(task: task);
              }
            }

            // Detail panel is removed — full page replaces it
            const showDetail = false;
            Widget? detailPanel;

            return Container(
              color: colors.background,
              child: Stack(
                children: [
                  ResponsiveLayout(
                    sidebar: const Sidebar(),
                    content: AppBackground(
                      child: Column(
                        children: [
                          WindowDragArea(child: _ContentHeader()),
                          Expanded(
                            child: PageTransitionSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                                return SharedAxisTransition(
                                  animation: primaryAnimation,
                                  secondaryAnimation: secondaryAnimation,
                                  transitionType: SharedAxisTransitionType.scaled,
                                  child: child,
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(nav.selectedNavItem + (nav.isDetailOpen ? '_detail' : '')),
                                child: mainContent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    detailPanel: detailPanel,
                    showDetailPanel: showDetail,
                  ),
                  const FocusTimerOverlay(),
                  const BreakScreen(),
                  const BulkActionBar(),
                  if (context.watch<CelebrationProvider>().isCelebrating)
                    const TaskCompletedOverlay(),
                ],
              ),
            ); // Container return
          }, // builder
        ), // Consumer
    ); // AppShortcuts return
  }
}


class _ContentHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: colors.background,
        // Surface shift separator — NO border
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!nav.isSearchOpen)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nav.pageTitle,
                  style: AppTypography.headlineSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Selector<TaskProvider, int>(
                  selector: (context, tasks) => tasks
                           .getTasksForNav(
                             nav.selectedNavItem,
                             filterMITs: nav.filterMITs,
                             filterHighPriority: nav.filterHighPriority,
                             filterOverdue: nav.filterOverdue,
                             mitIds: nav.mitTaskIds,
                           )
                           .where((t) {
                             if (nav.selectedNavItem == AppConstants.navCompleted) return true;
                             if (nav.selectedNavItem == AppConstants.navTrash) return true;
                             return !t.isCompleted;
                           })
                           .length,
                  builder: (context, count, _) {
                    return Text(
                      _subtitleForNav(nav.selectedNavItem, count),
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    );
                  },
                ),
              ],
            ),
          if (nav.isSearchOpen) Expanded(child: _SearchBar()),
          if (!nav.isSearchOpen) const Spacer(),
          if (!nav.isSearchOpen)
            _HeaderIconBtn(
              icon: PhosphorIcons.magnifyingGlass(),
              onTap: () => nav.openSearch(),
              tooltip: 'Search  Ctrl+F',
            ),
          const SizedBox(width: 8),
          if (!nav.isSearchOpen && _showNewTask(nav.selectedNavItem))
            _NewTaskButton(),
          const SizedBox(width: 8),
          const _WindowCaptionButtons(),
        ],
      ),
    );
  }

  bool _showNewTask(String navItem) {
    return navItem != AppConstants.navSettings &&
        navItem != AppConstants.navInsights &&
        navItem != AppConstants.navTrash &&
        navItem != AppConstants.navCalendar;
  }

  String _subtitleForNav(String navItem, int count) {
    switch (navItem) {
      case AppConstants.navToday:
        return 'Your workspace for today';
      case AppConstants.navUpcoming:
        return '$count tasks in the next 7 days';
      case AppConstants.navAll:
        return '$count tasks total';
      case AppConstants.navCompleted:
        return '$count tasks completed';
      case AppConstants.navTrash:
        return 'Items deleted in the last 30 days';
      case AppConstants.navHighPriority:
        return '$count high priority tasks';
      case AppConstants.navScheduled:
        return '$count scheduled tasks';
      case AppConstants.navFlagged:
        return '$count flagged tasks';
      case AppConstants.navSettings:
        return 'Customize your workspace';
      case AppConstants.navInsights:
        return 'Your productivity overview';
      case AppConstants.navCalendar:
        return 'See your schedule at a glance';
      default:
        if (navItem.startsWith('list_')) {
          return '$count tasks in this list';
        }
        return '';
    }
  }
}

class _NewTaskButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().openQuickAdd(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppColors.ambientShadow(
            opacity: 0.20,
            blur: 16,
            offset: const Offset(0, 4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 7),
            Text(
              'New Task',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
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
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border, width: 0.5),
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
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                    size: 16, color: colors.textSecondary),
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
          child: Text(
            'Cancel',
            style: AppTypography.body.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon, required this.onTap, this.tooltip});
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

class _WindowCaptionButtons extends StatelessWidget {
  const _WindowCaptionButtons();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CaptionBtn(
          icon: Icons.minimize_rounded,
          onTap: () => handleWindowAction('minimize'),
          hoverColor: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          iconColor: colors.textSecondary,
        ),
        _CaptionBtn(
          icon: Icons.crop_square_rounded,
          onTap: () => handleWindowAction('maximize'),
          hoverColor: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          iconColor: colors.textSecondary,
        ),
        _CaptionBtn(
          icon: Icons.close_rounded,
          onTap: () => handleWindowAction('close'),
          hoverColor: const Color(0xFFE81123),
          hoverIconColor: Colors.white,
          iconColor: colors.textSecondary,
        ),
      ],
    );
  }
}

class _CaptionBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;
  final Color iconColor;
  final Color? hoverIconColor;

  const _CaptionBtn({
    required this.icon,
    required this.onTap,
    required this.hoverColor,
    required this.iconColor,
    this.hoverIconColor,
  });

  @override
  State<_CaptionBtn> createState() => _CaptionBtnState();
}

class _CaptionBtnState extends State<_CaptionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered && widget.hoverIconColor != null
                ? widget.hoverIconColor
                : widget.iconColor,
          ),
        ),
      ),
    );
  }
}


