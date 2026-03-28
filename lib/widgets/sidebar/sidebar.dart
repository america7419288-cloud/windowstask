import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/task.dart';
import '../../models/task_list.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/focus_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';
import '../../data/app_stickers.dart';
import '../shared/sticker_widget.dart' as app_sticker;
import '../focus/session_setup_dialog.dart';

const double sidebarWidth = 240.0;

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sidebarWidth,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientSidebar,
      ),
      child: Column(children: [
        const _Logo(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              _Section('INBOX', [
                _NavItem(AppConstants.navToday, 'Today', PhosphorIcons.calendar()),
                _NavItem(AppConstants.navUpcoming, 'Upcoming', PhosphorIcons.calendarBlank()),
                _NavItem(AppConstants.navAll, 'All Tasks', PhosphorIcons.listBullets()),
                _NavItem(AppConstants.navCompleted, 'Completed', PhosphorIcons.checkCircle()),
              ]),
              _Section('SMART LISTS', [
                _NavItem(AppConstants.navHighPriority, 'High Priority', PhosphorIcons.warning()),
                _NavItem(AppConstants.navScheduled, 'Scheduled', PhosphorIcons.clock()),
                _NavItem(AppConstants.navFlagged, 'Flagged', PhosphorIcons.flag()),
                _NavItem(AppConstants.navCalendar, 'Calendar', PhosphorIcons.calendarDots()),
              ]),
              _Section('MY LISTS', [
                ..._buildLists(context),
                const _NewListButton(),
              ]),
            ]),
          ),
        ),
        const _Footer(),
      ]),
    );
  }

  List<Widget> _buildLists(BuildContext context) {
    final lists = context.watch<ListProvider>().activeLists;
    return lists.map((list) {
      return _NavItem(
        'list_${list.id}',
        list.name,
        PhosphorIcons.hash(),
      );
    }).toList();
  }
}

// ── LOGO ──────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(9),
            boxShadow: AppColors.shadowPrimary(),
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.checkFat(PhosphorIconsStyle.fill),
              size: 16,
              color: Colors.white,
            )),
        ),
        const SizedBox(width: 10),
        Text('Taski',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          )),
      ]),
    );
  }
}

// ── SECTION ───────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> items;

  const _Section(this.label, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          child: Text(
            label,
            style: AppTypography.micro.copyWith(
              color: AppColors.sidebarTextDim,
            )),
        ),
        ...items,
      ],
    );
  }
}

// ── NAV ITEM ──────────────────────────────

class _NavItem extends StatefulWidget {
  final String navId;
  final String label;
  final IconData icon;

  const _NavItem(this.navId, this.label, this.icon);

  @override
  _NavItemState createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  int _badgeCount(String navId, TaskProvider tasks) {
    if (navId == AppConstants.navToday) return tasks.todayCount;
    if (navId == AppConstants.navHighPriority) return tasks.getTasksForNav(AppConstants.navHighPriority).length;
    if (navId.startsWith('list_')) {
      final listId = navId.replaceFirst('list_', '');
      return tasks.countForList(listId);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final isActive = nav.selectedNavItem == widget.navId;
    final tasks = context.watch<TaskProvider>();

    final count = _badgeCount(widget.navId, tasks);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (widget.navId.startsWith('list_')) {
            nav.selectList(widget.navId.replaceFirst('list_', ''));
          } else {
            nav.selectNav(widget.navId);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.sidebarActive
                : _hovered
                    ? AppColors.sidebarHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Row(children: [
              Icon(widget.icon,
                size: 16,
                color: isActive ? Colors.white : AppColors.sidebarTextDim),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isActive ? Colors.white : AppColors.sidebarText,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ))),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.20) : AppColors.primaryDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$count',
                    style: AppTypography.micro.copyWith(
                      color: isActive ? Colors.white : AppColors.primaryLight,
                      letterSpacing: 0,
                    ))),
            ]),

            if (isActive)
              Positioned(
                left: -10,
                top: 2,
                bottom: 2,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientGold,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── FOOTER ────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final nav = context.read<NavigationProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.sidebarBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.gradientGold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: app_sticker.StickerWidget(
                localSticker: AppStickers.sidebarMascot,
                size: 28,
                animate: true,
              )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.firstName,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
                Text(
                  '${_formatXP(user.totalXP)} XP · ${user.streak}d',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.sidebarTextDim,
                  )),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),

        Row(children: [
          _FooterIconBtn(
            icon: PhosphorIcons.timer(),
            tooltip: 'Focus',
            onTap: () => _openFocus(context),
          ),
          _FooterIconBtn(
            icon: PhosphorIcons.gear(),
            tooltip: 'Settings',
            onTap: () => nav.selectNav(AppConstants.navSettings),
          ),
          _FooterIconBtn(
            icon: PhosphorIcons.chartBar(),
            tooltip: 'Insights',
            onTap: () => nav.selectNav(AppConstants.navInsights),
          ),
          const Spacer(),
          const _StoreBtn(),
        ]),
      ]),
    );
  }

  void _openFocus(BuildContext context) {
    final focus = context.read<FocusProvider>();
    if (focus.isActive) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const Center(child: SessionSetupDialog()),
    );
  }
}

class _FooterIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _FooterIconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_FooterIconBtn> createState() => _FooterIconBtnState();
}

class _FooterIconBtnState extends State<_FooterIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 18, color: AppColors.sidebarTextDim),
          ),
        ),
      ),
    );
  }
}

class _StoreBtn extends StatefulWidget {
  const _StoreBtn();
  @override
  _StoreBtnState createState() => _StoreBtnState();
}

class _StoreBtnState extends State<_StoreBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navStore),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.gold.withValues(alpha: 0.20) : AppColors.gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(PhosphorIcons.storefront(), size: 14, color: AppColors.gold),
            const SizedBox(width: 5),
            Text('Store',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              )),
          ]),
        ),
      ),
    );
  }
}

class _NewListButton extends StatefulWidget {
  const _NewListButton();
  @override
  State<_NewListButton> createState() => _NewListButtonState();
}

class _NewListButtonState extends State<_NewListButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Placeholder for showEditListDialog
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1, style: BorderStyle.none),
          ),
          child: Row(children: [
            Icon(PhosphorIcons.plus(), size: 16, color: AppColors.sidebarTextDim),
            const SizedBox(width: 10),
            Text('New List',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.sidebarTextDim)),
          ]),
        ),
      ),
    );
  }
}

String _formatXP(int xp) {
  if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
  if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(0)}K';
  return '$xp';
}
