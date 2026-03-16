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
        border: Border(
          right: BorderSide(color: colors.divider, width: 1),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // Titlebar area spacer (traffic lights are in app bar)
              const SizedBox(height: AppConstants.titlebarHeight),
              // App Logo
              _AppLogo(),
              const SizedBox(height: 8),
              // Navigation
              Expanded(
                child: _NavContent(),
              ),
              // Bottom bar
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

class _NavContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer4<NavigationProvider, TaskProvider, ListProvider, SettingsProvider>(
      builder: (context, nav, tasks, lists, settings, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            _sectionHeader(context, 'Inbox'),
            SidebarItem(
              label: 'Today',
              icon: Icons.calendar_today_rounded,
              isSelected: nav.selectedNavItem == AppConstants.navToday,
              onTap: () => nav.selectNav(AppConstants.navToday),
              badge: tasks.todayCount,
            ),
            SidebarItem(
              label: 'Upcoming',
              icon: Icons.upcoming_rounded,
              isSelected: nav.selectedNavItem == AppConstants.navUpcoming,
              onTap: () => nav.selectNav(AppConstants.navUpcoming),
            ),
            SidebarItem(
              label: 'All Tasks',
              icon: Icons.list_alt_rounded,
              isSelected: nav.selectedNavItem == AppConstants.navAll,
              onTap: () => nav.selectNav(AppConstants.navAll),
            ),
            SidebarItem(
              label: 'Completed',
              icon: Icons.check_circle_outline_rounded,
              isSelected: nav.selectedNavItem == AppConstants.navCompleted,
              onTap: () => nav.selectNav(AppConstants.navCompleted),
            ),
            SidebarItem(
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
              label: 'High Priority',
              icon: Icons.priority_high_rounded,
              isSelected: nav.selectedNavItem == AppConstants.navHighPriority,
              onTap: () => nav.selectNav(AppConstants.navHighPriority),
            ),
            SidebarItem(
              label: 'Scheduled',
              icon: Icons.schedule_rounded,
              isSelected: nav.selectedNavItem == AppConstants.navScheduled,
              onTap: () => nav.selectNav(AppConstants.navScheduled),
            ),
            SidebarItem(
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
            // User lists
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
            // New List button
            _NewListButton(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Divider(height: 1, color: colors.divider),
            ),
            SidebarItem(
              label: 'Insights',
              icon: Icons.bar_chart_rounded,
              isSelected: nav.selectedNavItem == AppConstants.navInsights,
              onTap: () => nav.selectNav(AppConstants.navInsights),
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
        onTap: () => _showNewListDialog(context),
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? (colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'New List',
                style: AppTypography.body.copyWith(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewListDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _EditListDialog());
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
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit List' : 'New List',
              style: AppTypography.headline.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 16),
            // Emoji picker
            Text('Icon', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _emojis.map((e) {
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _emoji == e
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: _emoji == e
                          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 16))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Color picker
            Text('Color', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: _colors.map((hex) {
                final color = Color(int.parse('FF$hex', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _colorHex == hex
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: _colorHex == hex
                          ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Name field
            Text('Name', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'List name...',
                filled: true,
                fillColor: colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _save(context),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _save(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Text(
              'T',
              style: AppTypography.body.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          GestureDetector(
            onTap: () => nav.selectNav(AppConstants.navSettings),
            child: Icon(Icons.settings_outlined, size: 18, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
