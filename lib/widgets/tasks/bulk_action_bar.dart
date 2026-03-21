import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/list_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../models/task.dart';
import '../shared/priority_badge.dart';

class BulkActionBar extends StatelessWidget {
  const BulkActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final tasks = context.read<TaskProvider>();
    final lists = context.read<ListProvider>();
    final colors = context.appColors;
    
    if (!nav.isSelectionMode) {
      return const SizedBox.shrink();
    }

    final ids = nav.selectedTaskIds.toList();
    final count = nav.selectedCount;

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          elevation: 0,
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: colors.isDark ? const Color(0xFF2A2725) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.border,
                width: 0.75,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Count label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count selected',
                    style: AppTypography.bodySemibold.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const SizedBox(
                  height: 20,
                  child: VerticalDivider(width: 1, thickness: 1),
                ),
                const SizedBox(width: 16),

                // Complete
                _BulkBtn(
                  icon: Icons.check_circle_outline,
                  label: 'Complete',
                  color: AppColors.green,
                  onTap: () async {
                    await tasks.bulkComplete(ids);
                    nav.clearSelection();
                  },
                ),
                const SizedBox(width: 8),

                // Tomorrow
                _BulkBtn(
                  icon: Icons.next_plan_outlined,
                  label: 'Tomorrow',
                  color: AppColors.blue,
                  onTap: () async {
                    final tomorrow = DateTime.now().add(const Duration(days: 1));
                    await tasks.bulkUpdateDueDate(ids, DateTime(tomorrow.year, tomorrow.month, tomorrow.day));
                    nav.clearSelection();
                  },
                ),
                const SizedBox(width: 8),

                // Priority

                // Priority
                _BulkBtn(
                  icon: Icons.flag_outlined,
                  label: 'Priority',
                  color: AppColors.orange,
                  onTap: () => _showPriorityPicker(context, ids, tasks, nav),
                ),
                const SizedBox(width: 8),

                // Move to list
                _BulkBtn(
                  icon: Icons.folder_outlined,
                  label: 'Move',
                  color: AppColors.blue,
                  onTap: () => _showListPicker(context, ids, tasks, lists, nav),
                ),
                const SizedBox(width: 8),

                // Delete
                _BulkBtn(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.red,
                  onTap: () async {
                    await tasks.bulkDelete(ids);
                    nav.clearSelection();
                  },
                ),
                const SizedBox(width: 12),

                // Cancel
                IconButton(
                  onPressed: nav.clearSelection,
                  icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPriorityPicker(BuildContext context, List<String> ids, TaskProvider tasks, NavigationProvider nav) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Priority.values.map((p) {
            return ListTile(
              leading: Icon(Icons.flag_rounded, color: AppColors.getPriorityColor(p)),
              title: Text(PriorityBadge.labelForPriority(p)),
              onTap: () async {
                await tasks.bulkSetPriority(ids, p);
                nav.clearSelection();
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showListPicker(BuildContext context, List<String> ids, TaskProvider tasks, ListProvider lists, NavigationProvider nav) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to List'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.inbox_rounded),
                title: const Text('Inbox (No List)'),
                onTap: () async {
                  await tasks.bulkMoveToList(ids, null);
                  nav.clearSelection();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ...lists.activeLists.map((l) {
                return ListTile(
                  leading: Text(l.emoji),
                  title: Text(l.name),
                  onTap: () async {
                    await tasks.bulkMoveToList(ids, l.id);
                    nav.clearSelection();
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BulkBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_BulkBtn> createState() => _BulkBtnState();
}

class _BulkBtnState extends State<_BulkBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _hovered ? widget.color : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
