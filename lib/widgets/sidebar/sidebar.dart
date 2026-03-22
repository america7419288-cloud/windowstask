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
import 'list_tile_item.dart';
import 'sidebar_item.dart';
import '../../data/app_stickers.dart';
import '../../providers/user_provider.dart';
import '../../data/app_stickers.dart';
import '../shared/deco_sticker.dart';
import '../../providers/focus_provider.dart';
import '../focus/session_setup_dialog.dart';

import 'dart:ui';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Container(
      width: AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowDk : AppColors.surfaceContainerLow,
      ),
      child: Column(
        children: const [
          SizedBox(height: AppConstants.titlebarHeight),
          _SidebarHeader(),
          SizedBox(height: 8),
          Expanded(child: _NavContent()),
          _UserHeader(),
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
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            'Taski',
            style: AppTypography.taskTitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.5,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavContent extends StatefulWidget {
  const _NavContent();
  @override
  State<_NavContent> createState() => _NavContentState();
}

class _NavContentState extends State<_NavContent> {
  final ScrollController _scrollController = ScrollController();
  NavigationProvider? _navProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navProvider == null) {
      _navProvider = context.read<NavigationProvider>();
      _navProvider!.addListener(_onNavChanged);
    }
  }

  void _onNavChanged() {
    if (_navProvider == null) return;
    // If we switch to Today or Upcoming, scroll to top
    if (_navProvider!.selectedNavItem == AppConstants.navToday || 
        _navProvider!.selectedNavItem == AppConstants.navUpcoming) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _navProvider?.removeListener(_onNavChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InboxSection(),
          _SmartListSection(),
          _CustomListSection(),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InboxSection extends StatelessWidget {
  const _InboxSection();
  @override
  Widget build(BuildContext context) {
    final isSelected = context.select<NavigationProvider, bool>(
      (n) => n.selectedNavItem == AppConstants.navToday
    );
    final count = context.select<TaskProvider, int>((t) => t.todayCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(context, 'Inbox'),
        SidebarItem(
          label: 'Today',
          icon: PhosphorIcons.calendarStar(),
          isSelected: isSelected,
          onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navToday),
          badge: count,
        ),
        Selector<NavigationProvider, bool>(
          selector: (_, n) => n.selectedNavItem == AppConstants.navUpcoming,
          builder: (context, isSelected, _) => SidebarItem(
            label: 'Upcoming',
            icon: PhosphorIcons.calendarBlank(),
            isSelected: isSelected,
            onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navUpcoming),
          ),
        ),
        Selector<NavigationProvider, bool>(
          selector: (_, n) => n.selectedNavItem == AppConstants.navAll,
          builder: (context, isSelected, _) => SidebarItem(
            label: 'All Tasks',
            icon: PhosphorIcons.tray(),
            isSelected: isSelected,
            onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navAll),
          ),
        ),
        Selector<NavigationProvider, bool>(
          selector: (_, n) => n.selectedNavItem == AppConstants.navCompleted,
          builder: (context, isSelected, _) => SidebarItem(
            label: 'Completed',
            icon: PhosphorIcons.checkCircle(),
            isSelected: isSelected,
            onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navCompleted),
          ),
        ),
      ],
    );
  }
}

class _SmartListSection extends StatelessWidget {
  const _SmartListSection();
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sidebarDivider(colors),
        _sectionHeader(context, 'Smart Lists'),
        Selector<NavigationProvider, bool>(
          selector: (_, n) => n.selectedNavItem == AppConstants.navHighPriority,
          builder: (context, isSelected, _) => SidebarItem(
            label: 'High Priority',
            icon: PhosphorIcons.warningCircle(),
            isSelected: isSelected,
            onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navHighPriority),
          ),
        ),
        Selector<NavigationProvider, bool>(
          selector: (_, n) => n.selectedNavItem == AppConstants.navScheduled,
          builder: (context, isSelected, _) => SidebarItem(
            label: 'Scheduled',
            icon: PhosphorIcons.clock(),
            isSelected: isSelected,
            onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navScheduled),
          ),
        ),
        Selector<NavigationProvider, bool>(
          selector: (_, n) => n.selectedNavItem == AppConstants.navFlagged,
          builder: (context, isSelected, _) => SidebarItem(
            label: 'Flagged',
            icon: PhosphorIcons.flag(),
            isSelected: isSelected,
            onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navFlagged),
          ),
        ),
        Selector<NavigationProvider, bool>(
          selector: (_, n) => n.selectedNavItem == AppConstants.navCalendar,
          builder: (context, isSelected, _) => SidebarItem(
            label: 'Calendar',
            icon: PhosphorIcons.calendarDots(),
            isSelected: isSelected,
            onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navCalendar),
          ),
        ),
      ],
    );
  }
}

class _CustomListSection extends StatelessWidget {
  const _CustomListSection();
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final tasks = context.watch<TaskProvider>();
    final lists = context.watch<ListProvider>();
    final colors = context.appColors;

    final Map<String, List<TaskList>> folders = {};
    final List<TaskList> noFolder = [];

    for (var list in lists.activeLists) {
      if (list.folderName != null && list.folderName!.trim().isNotEmpty) {
        folders.putIfAbsent(list.folderName!.trim(), () => []).add(list);
      } else {
        noFolder.add(list);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sidebarDivider(colors),
        _sectionHeader(context, 'My Lists'),
        ...folders.entries.map((e) => _FolderGroup(
          folderName: e.key,
          lists: e.value,
        )),
        ...noFolder.map((list) {
          final navId = 'list_${list.id}';
          return ListTileItem(
            list: list,
            taskCount: tasks.countForList(list.id),
            isSelected: nav.selectedNavItem == navId,
            onTap: () => nav.selectList(list.id),
            onEdit: () => _showEditListDialog(context, list),
          );
        }),
        const _NewListButton(),
      ],
    );
  }
}

class _FolderGroup extends StatefulWidget {
  final String folderName;
  final List<TaskList> lists;
  const _FolderGroup({required this.folderName, required this.lists});

  @override
  State<_FolderGroup> createState() => _FolderGroupState();
}

class _FolderGroupState extends State<_FolderGroup> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    final tasks = context.watch<TaskProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(_isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded, 
                     size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text(widget.folderName, 
                  style: AppTypography.labelMedium.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.lists.map((list) {
                final navId = 'list_${list.id}';
                return ListTileItem(
                  list: list,
                  taskCount: tasks.countForList(list.id),
                  isSelected: nav.selectedNavItem == navId,
                  onTap: () => nav.selectList(list.id),
                  onEdit: () => _showEditListDialog(context, list),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

void _showEditListDialog(BuildContext context, TaskList list) {
  showDialog(context: context, builder: (_) => _EditListDialog(list: list));
}

Widget _sectionHeader(BuildContext context, String title) {
  final colors = context.appColors;
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
    child: Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        fontSize: 10,
        color: colors.textQuaternary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
  );
}

Widget sidebarDivider(AppColorsExtension colors) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    height: 1,
    color: colors.border,
  );
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
  late TextEditingController _nameController;
  late TextEditingController _folderController;
  late String _emoji;
  late String _colorHex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list?.name ?? '');
    _folderController = TextEditingController(text: widget.list?.folderName ?? '');
    _emoji = widget.list?.emoji ?? '📋';
    _colorHex = widget.list?.colorHex ?? '6366F1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _folderController.dispose();
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
              controller: _nameController,
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
            const SizedBox(height: 12),
            TextField(
              controller: _folderController,
              decoration: InputDecoration(
                hintText: 'Folder name (Optional)...',
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
    final name = _nameController.text.trim();
    final folder = _folderController.text.trim();
    if (name.isEmpty) return;
    final provider = context.read<ListProvider>();
    if (widget.list != null) {
      provider.updateList(widget.list!.copyWith(
        name: name, 
        emoji: _emoji, 
        colorHex: _colorHex,
        folderName: folder.isEmpty ? null : folder,
        clearFolderName: folder.isEmpty,
      ));
    } else {
      provider.createList(
        name: name, 
        emoji: _emoji, 
        colorHex: _colorHex,
        folderName: folder.isEmpty ? null : folder,
      );
    }
    Navigator.pop(context);
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final firstName = context.select<UserProvider, String>((p) => p.firstName);
    final xp = context.select<UserProvider, int>((p) => p.totalXP);
    final streak = context.select<UserProvider, int>((p) => p.streak);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          const DecoSticker(
            sticker: AppStickers.sidebarMascot,
            size: 40,
            animate: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName,
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$xp XP · $streak d streak',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final focus = context.watch<FocusProvider>();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        children: [
          _SidebarIconBtn(
            icon: focus.isActive ? PhosphorIcons.timer(PhosphorIconsStyle.fill) : PhosphorIcons.timer(),
            onTap: () {
              if (focus.isActive) return;
              showDialog(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.4),
                builder: (context) => const Center(child: SessionSetupDialog()),
              );
            },
            isActive: focus.isActive,
            color: focus.isActive ? AppColors.red : null,
          ),
          const SizedBox(width: 6),
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
          const SizedBox(width: 6),
          _SidebarIconBtn(
            icon: Icons.storefront_rounded,
            onTap: () => nav.selectNav(AppConstants.navStore),
            isActive: nav.selectedNavItem == AppConstants.navStore,
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
  final Color? color;

  const _SidebarIconBtn({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.color,
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
                ? AppColors.primary.withValues(alpha: 0.10)
                : _hovered
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.isActive ? AppColors.primary : colors.textTertiary,
          ),
        ),
      ),
    );
  }
}

