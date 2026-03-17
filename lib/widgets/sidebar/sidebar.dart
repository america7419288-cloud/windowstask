import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_list.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/springs.dart';
import '../../theme/colors.dart';
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
        color: colors.sidebar.withOpacity(colors.isDark ? 1.0 : 0.85),
        border: Border(right: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.titlebarHeight),
              _AppLogo(),
              const SizedBox(height: 8),
              Expanded(child: _NavContent()),
              _BottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Taski',
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
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
  final Map<String, GlobalKey> _itemKeys = {};
  double _indicatorY = -50;
  double _indicatorHeight = 0;
  final ScrollController _scrollController = ScrollController();

  GlobalKey _getKey(String id) {
    return _itemKeys.putIfAbsent(id, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
    _scrollController.addListener(_updateIndicator);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateIndicator);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateIndicator() {
    if (!mounted) return;
    final nav = context.read<NavigationProvider>().selectedNavItem;
    final key = _itemKeys[nav];
    if (key != null && key.currentContext != null) {
      final box = key.currentContext!.findRenderObject() as RenderBox?;
      final parentBox = context.findRenderObject() as RenderBox?;
      if (box != null && parentBox != null) {
        final pos = box.localToGlobal(Offset.zero, ancestor: parentBox);
        setState(() {
          _indicatorY = pos.dy;
          _indicatorHeight = box.size.height;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Consumer4<NavigationProvider, TaskProvider, ListProvider, SettingsProvider>(
      builder: (context, nav, tasks, lists, settings, _) {
        // Schedule an indicator update in case the layout shifts
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());

        return Stack(
          children: [
            // Scrollable Content
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader(context, 'Inbox'),
                    SidebarItem(
                      key: _getKey(AppConstants.navToday),
                      label: 'Today',
                      icon: Icons.calendar_today_rounded,
                      isSelected: nav.selectedNavItem == AppConstants.navToday,
                      onTap: () => nav.selectNav(AppConstants.navToday),
                      badge: tasks.todayCount,
                    ),
                    SidebarItem(
                      key: _getKey(AppConstants.navUpcoming),
                      label: 'Upcoming',
                      icon: Icons.upcoming_rounded,
                      isSelected: nav.selectedNavItem == AppConstants.navUpcoming,
                      onTap: () => nav.selectNav(AppConstants.navUpcoming),
                    ),
                    SidebarItem(
                      key: _getKey(AppConstants.navAll),
                      label: 'All Tasks',
                      icon: Icons.list_alt_rounded,
                      isSelected: nav.selectedNavItem == AppConstants.navAll,
                      onTap: () => nav.selectNav(AppConstants.navAll),
                    ),
                    SidebarItem(
                      key: _getKey(AppConstants.navCompleted),
                      label: 'Completed',
                      icon: Icons.check_circle_outline_rounded,
                      isSelected: nav.selectedNavItem == AppConstants.navCompleted,
                      onTap: () => nav.selectNav(AppConstants.navCompleted),
                    ),
                    SidebarItem(
                      key: _getKey(AppConstants.navTrash),
                      label: 'Trash',
                      icon: Icons.delete_outline_rounded,
                      isSelected: nav.selectedNavItem == AppConstants.navTrash,
                      onTap: () => nav.selectNav(AppConstants.navTrash),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Divider(height: 1, color: colors.divider),
                    ),
                    _sectionHeader(context, 'Smart Lists'),
                    SidebarItem(
                      key: _getKey(AppConstants.navHighPriority),
                      label: 'High Priority',
                      icon: Icons.priority_high_rounded,
                      isSelected: nav.selectedNavItem == AppConstants.navHighPriority,
                      onTap: () => nav.selectNav(AppConstants.navHighPriority),
                    ),
                    SidebarItem(
                      key: _getKey(AppConstants.navScheduled),
                      label: 'Scheduled',
                      icon: Icons.schedule_rounded,
                      isSelected: nav.selectedNavItem == AppConstants.navScheduled,
                      onTap: () => nav.selectNav(AppConstants.navScheduled),
                    ),
                    SidebarItem(
                      key: _getKey(AppConstants.navFlagged),
                      label: 'Flagged',
                      icon: Icons.flag_outlined,
                      isSelected: nav.selectedNavItem == AppConstants.navFlagged,
                      onTap: () => nav.selectNav(AppConstants.navFlagged),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Divider(height: 1, color: colors.divider),
                    ),
                    _sectionHeader(context, 'My Lists'),
                    ...lists.activeLists.map((list) {
                      final navId = 'list_${list.id}';
                      return ListTileItem(
                        key: _getKey(navId),
                        list: list,
                        taskCount: tasks.countForList(list.id),
                        isSelected: nav.selectedNavItem == navId,
                        onTap: () => nav.selectList(list.id),
                        onEdit: () => _showEditListDialog(context, list),
                      );
                    }),
                    _NewListButton(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Divider(height: 1, color: colors.divider),
                    ),
                    SidebarItem(
                      key: _getKey(AppConstants.navInsights),
                      label: 'Insights',
                      icon: Icons.bar_chart_rounded,
                      isSelected: nav.selectedNavItem == AppConstants.navInsights,
                      onTap: () => nav.selectNav(AppConstants.navInsights),
                    ),
                  ],
                ),
              ),
            ),
            
            // The Sliding Animated Indicator (Blue Pill)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              top: _indicatorY + 6, // 6px padding offset to center in the item
              left: 8,
              height: _indicatorHeight > 12 ? _indicatorHeight - 12 : 0, // shrink to fit inside margin
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showEditListDialog(BuildContext context, TaskList list) {
    showDialog(context: context, builder: (_) => _EditListDialog(list: list));
  }
}

// ... Additional helper classes (_NewListButton, _EditListDialog, _BottomBar) remain practically identical
class _NewListButton extends StatefulWidget {
  @override
  State<_NewListButton> createState() => _NewListButtonState();
}

class _NewListButtonState extends State<_NewListButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
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
            color: _hovered ? (colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text('New List', style: AppTypography.body.copyWith(color: accent)),
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
  final List<String> _emojis = AppConstants.listEmojis;
  final List<String> _colors = ['007AFF', 'AF52DE', 'FF2D55', 'FF3B30', 'FF9500', '34C759', '5AC8FA'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.list?.name ?? '');
    _emoji = widget.list?.emoji ?? '📋';
    _colorHex = widget.list?.colorHex ?? '007AFF';
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
        width: 340, padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit List' : 'New List', style: AppTypography.headline.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'List name...',
                filled: true,
                fillColor: colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _save(context),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: AppTypography.body.copyWith(color: colors.textSecondary))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _save(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white,
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

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.divider))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16, backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Text('T', style: AppTypography.body.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taski User', style: AppTypography.bodySemibold.copyWith(color: colors.textPrimary)),
                Text('Pro Plan', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(onTap: () => nav.selectNav(AppConstants.navSettings), child: Icon(Icons.settings_outlined, size: 18, color: colors.textSecondary)),
        ],
      ),
    );
  }
}
