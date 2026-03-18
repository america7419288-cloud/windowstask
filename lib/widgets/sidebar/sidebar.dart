import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/task_list.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';
import 'sidebar_item.dart';
import 'list_tile_item.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.isDark
              ? [const Color(0xFF201E1C), const Color(0xFF1A1917)]
              : [const Color(0xFFF5F2EE), const Color(0xFFECE9E4)],
        ),
        border: Border(
          right: BorderSide(
            color: colors.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.75,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppConstants.titlebarHeight),
          const _SidebarHeader(),
          const SizedBox(height: 8),
          Expanded(child: _NavContent()),
          _SidebarFooter(),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.40),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                  spreadRadius: -1,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            'Taski',
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.8,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavContent extends StatefulWidget {
  @override
  State<_NavContent> createState() => _NavContentState();
}

class _NavContentState extends State<_NavContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Consumer4<NavigationProvider, TaskProvider, ListProvider, SettingsProvider>(
      builder: (context, nav, tasks, lists, settings, _) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader(context, 'Inbox'),
              SidebarItem(
                label: 'Today',
                icon: PhosphorIcons.calendarStar(),
                isSelected: nav.selectedNavItem == AppConstants.navToday,
                onTap: () => nav.selectNav(AppConstants.navToday),
                badge: tasks.todayCount,
              ),
              SidebarItem(
                label: 'Upcoming',
                icon: PhosphorIcons.calendarBlank(),
                isSelected: nav.selectedNavItem == AppConstants.navUpcoming,
                onTap: () => nav.selectNav(AppConstants.navUpcoming),
              ),
              SidebarItem(
                label: 'All Tasks',
                icon: PhosphorIcons.tray(),
                isSelected: nav.selectedNavItem == AppConstants.navAll,
                onTap: () => nav.selectNav(AppConstants.navAll),
              ),
              SidebarItem(
                label: 'Completed',
                icon: PhosphorIcons.checkCircle(),
                isSelected: nav.selectedNavItem == AppConstants.navCompleted,
                onTap: () => nav.selectNav(AppConstants.navCompleted),
              ),
              SidebarItem(
                label: 'Trash',
                icon: PhosphorIcons.trash(),
                isSelected: nav.selectedNavItem == AppConstants.navTrash,
                onTap: () => nav.selectNav(AppConstants.navTrash),
              ),
              _gradientDivider(colors),
              _sectionHeader(context, 'Smart Lists'),
              SidebarItem(
                label: 'High Priority',
                icon: PhosphorIcons.warningCircle(),
                isSelected: nav.selectedNavItem == AppConstants.navHighPriority,
                onTap: () => nav.selectNav(AppConstants.navHighPriority),
              ),
              SidebarItem(
                label: 'Scheduled',
                icon: PhosphorIcons.clock(),
                isSelected: nav.selectedNavItem == AppConstants.navScheduled,
                onTap: () => nav.selectNav(AppConstants.navScheduled),
              ),
              SidebarItem(
                label: 'Flagged',
                icon: PhosphorIcons.flag(),
                isSelected: nav.selectedNavItem == AppConstants.navFlagged,
                onTap: () => nav.selectNav(AppConstants.navFlagged),
              ),
              _gradientDivider(colors),
              _sectionHeader(context, 'My Lists'),
              ...lists.activeLists.map((list) {
                final navId = 'list_${list.id}';
                return ListTileItem(
                  list: list,
                  taskCount: tasks.countForList(list.id),
                  isSelected: nav.selectedNavItem == navId,
                  onTap: () => nav.selectList(list.id),
                  onEdit: () => _showEditListDialog(context, list),
                );
              }),
              _NewListButton(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.micro.copyWith(
          fontSize: 10,
          color: colors.textQuaternary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _gradientDivider(AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            colors.divider,
            colors.divider,
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }

  void _showEditListDialog(BuildContext context, TaskList list) {
    showDialog(context: context, builder: (_) => _EditListDialog(list: list));
  }
}

class _NewListButton extends StatefulWidget {
  @override
  State<_NewListButton> createState() => _NewListButtonState();
}

class _NewListButtonState extends State<_NewListButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog(context: context, builder: (_) => const _EditListDialog()),
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? (colors.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('New List', style: AppTypography.body.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditListDialog extends StatefulWidget {
  const _EditListDialog({this.list});
  final TaskList? list;
  @override
  State<_EditListDialog> createState() => _EditListDialogState();
}

class _EditListDialogState extends State<_EditListDialog> {
  late TextEditingController _controller;
  late String _emoji;
  late String _colorHex;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.list?.name ?? '');
    _emoji = widget.list?.emoji ?? '📋';
    _colorHex = widget.list?.colorHex ?? '6366F1';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEdit = widget.list != null;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusModal)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit List' : 'New List',
                style: AppTypography.headline.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'List name...',
                filled: true,
                fillColor: colors.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _save(context),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: AppTypography.body.copyWith(color: colors.textSecondary))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _save(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isEdit ? 'Save' : 'Create', style: AppTypography.body),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final provider = context.read<ListProvider>();
    if (widget.list != null) {
      provider.updateList(widget.list!.copyWith(name: name, emoji: _emoji, colorHex: _colorHex));
    } else {
      provider.createList(name: name, emoji: _emoji, colorHex: _colorHex);
    }
    Navigator.pop(context);
  }
}

class _SidebarFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          _SidebarIconBtn(
            icon: Icons.settings_outlined,
            onTap: () => nav.selectNav(AppConstants.navSettings),
            isActive: nav.selectedNavItem == AppConstants.navSettings,
          ),
          const SizedBox(width: 6),
          _SidebarIconBtn(
            icon: Icons.bar_chart_rounded,
            onTap: () => nav.selectNav(AppConstants.navInsights),
            isActive: nav.selectedNavItem == AppConstants.navInsights,
          ),
        ],
      ),
    );
  }
}

class _SidebarIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _SidebarIconBtn({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_SidebarIconBtn> createState() => _SidebarIconBtnState();
}

class _SidebarIconBtnState extends State<_SidebarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : _hovered
                    ? (colors.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.isActive ? AppColors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

