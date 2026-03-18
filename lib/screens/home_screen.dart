import 'package:flutter/material.dart';
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
import '../widgets/tasks/task_detail_panel.dart';
import '../widgets/shared/traffic_light_buttons.dart';
import '../widgets/focus/focus_timer_overlay.dart';
import '../widgets/shared/task_completed_overlay.dart';
import '../providers/celebration_provider.dart';
import '../widgets/layout/responsive_layout.dart';
import '../widgets/layout/app_shortcuts.dart';
import '../widgets/layout/window_controls.dart';
import '../widgets/layout/content_wallpaper.dart';
import 'settings_screen.dart';
import 'insights_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              default:
                mainContent = const MultiLayoutTaskView();
            }

            final showDetail = nav.isDetailPanelOpen && nav.selectedTaskId != null;
            Widget? detailPanel;
            if (showDetail) {
              final task = context.watch<TaskProvider>().getById(nav.selectedTaskId!);
              if (task != null) {
                detailPanel = TaskDetailPanel(task: task);
              }
            }

            return Container(
              color: colors.background,
              child: Stack(
                children: [
                  ResponsiveLayout(
                    sidebar: const Sidebar(),
                    content: ContentWallpaper(
                      child: Column(
                        children: [
                          WindowDragArea(child: _ContentHeader()),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.015),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: mainContent,
                          ),
                        ),
                        ],
                      ),
                    ),
                    detailPanel: detailPanel,
                    showDetailPanel: showDetail,
                  ),
                  const FocusTimerOverlay(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(color: colors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (!nav.isSearchOpen)
            Text(
              nav.pageTitle,
              style: AppTypography.headline.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          if (nav.isSearchOpen) Expanded(child: _SearchBar()),
          if (!nav.isSearchOpen) const Spacer(),
          if (!nav.isSearchOpen)
            _HeaderIconBtn(
              icon: PhosphorIcons.magnifyingGlass(),
              onTap: () => nav.openSearch(),
              tooltip: 'Search  Ctrl+F',
            ),
          const SizedBox(width: 6),
          if (!nav.isSearchOpen &&
              nav.selectedNavItem != AppConstants.navSettings &&
              nav.selectedNavItem != AppConstants.navInsights &&
              nav.selectedNavItem != AppConstants.navTrash)
            _NewTaskButton(),
          const SizedBox(width: 8),
          const _WindowCaptionButtons(),
        ],
      ),
    );
  }
}

class _NewTaskButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().openQuickAdd(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'New Task',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
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


