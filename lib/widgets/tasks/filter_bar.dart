import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../models/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';


class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    final tasks = context.watch<TaskProvider>();

    final priorityLabel = nav.filterPriority != null
        ? _priorityName(nav.filterPriority!)
        : 'All';
    final listLabel = nav.filterListId != null
        ? context.read<ListProvider>().getById(nav.filterListId!)?.name ?? 'All'
        : 'All';
    final dateLabel = nav.filterDateRange != null
        ? _dateName(nav.filterDateRange!)
        : 'All';
    final sortLabel = _sortName(tasks.sortOption);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Priority: $priorityLabel',
            icon: Icons.filter_list_rounded,
            isActive: nav.filterPriority != null,
            onTap: () => _showPriorityFilter(context, nav),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'List: $listLabel',
            icon: Icons.folder_outlined,
            isActive: nav.filterListId != null,
            onTap: () => _showListFilter(context, nav),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Date: $dateLabel',
            icon: Icons.calendar_today_outlined,
            isActive: nav.filterDateRange != null,
            onTap: () => _showDateFilter(context, nav),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'Sort by: ',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              GestureDetector(
                onTap: () => _showSortPicker(context, tasks),
                child: Text(
                  '$sortLabel ↓',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPriorityFilter(BuildContext context, NavigationProvider nav) {
    final colors = context.appColors;
    showMenu<Priority?>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(value: null, child: Text('All', style: AppTypography.bodyMedium)),
        ...Priority.values.map((p) => PopupMenuItem(
          value: p,
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AppColors.priorityColor(p),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(_priorityName(p), style: AppTypography.bodyMedium),
            ],
          ),
        )),
      ],
    ).then((value) {
      // value is null if user tapped "All" or dismissed
      nav.setFilterPriority(value);
    });
  }

  void _showListFilter(BuildContext context, NavigationProvider nav) {
    final colors = context.appColors;
    final lists = context.read<ListProvider>().lists;
    showMenu<String?>(
      context: context,
      position: const RelativeRect.fromLTRB(200, 80, 0, 0),
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(value: null, child: Text('All', style: AppTypography.bodyMedium)),
        ...lists.map((l) => PopupMenuItem(
          value: l.id,
          child: Text(l.name, style: AppTypography.bodyMedium),
        )),
      ],
    ).then((value) {
      nav.setFilterListId(value);
    });
  }

  void _showDateFilter(BuildContext context, NavigationProvider nav) {
    final colors = context.appColors;
    showMenu<String?>(
      context: context,
      position: const RelativeRect.fromLTRB(300, 80, 0, 0),
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(value: null, child: Text('All', style: AppTypography.bodyMedium)),
        PopupMenuItem(value: 'today', child: Text('Today', style: AppTypography.bodyMedium)),
        PopupMenuItem(value: 'week', child: Text('This Week', style: AppTypography.bodyMedium)),
        PopupMenuItem(value: 'overdue', child: Text('Overdue', style: AppTypography.bodyMedium)),
      ],
    ).then((value) {
      nav.setFilterDateRange(value);
    });
  }

  void _showSortPicker(BuildContext context, TaskProvider tasks) {
    final colors = context.appColors;
    showMenu<SortOption>(
      context: context,
      position: const RelativeRect.fromLTRB(500, 80, 50, 0),
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: SortOption.values.map((opt) => PopupMenuItem(
        value: opt,
        child: Text(_sortName(opt), style: AppTypography.bodyMedium),
      )).toList(),
    ).then((value) {
      if (value != null) {
        tasks.setSortOption(value);
      }
    });
  }

  String _priorityName(Priority p) {
    switch (p) {
      case Priority.none:   return 'None';
      case Priority.low:    return 'Low';
      case Priority.medium: return 'Medium';
      case Priority.high:   return 'High';
      case Priority.urgent: return 'Urgent';
    }
  }

  String _dateName(String range) {
    switch (range) {
      case 'today':   return 'Today';
      case 'week':    return 'This Week';
      case 'overdue': return 'Overdue';
      default:        return 'All';
    }
  }

  String _sortName(SortOption opt) {
    switch (opt) {
      case SortOption.dueDate:      return 'Due Date';
      case SortOption.priority:     return 'Priority';
      case SortOption.createdDate:  return 'Created';
      case SortOption.alphabetical: return 'Title';
      case SortOption.manual:       return 'Manual';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: isActive ? AppColors.primary : colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isActive ? AppColors.primary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14,
                color: isActive ? AppColors.primary : colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
