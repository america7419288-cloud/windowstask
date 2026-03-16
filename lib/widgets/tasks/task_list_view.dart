import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../shared/empty_state.dart';
import 'task_card.dart';
import 'quick_add_bar.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, TaskProvider>(
      builder: (context, nav, tasks, _) {
        final navItem = nav.selectedNavItem;
        final query = nav.searchQuery;
        final taskList = tasks.getTasksForNav(navItem,
            searchQuery: query.isEmpty ? null : query);

        if (taskList.isEmpty) {
          return Column(
            children: [
              if (navItem != AppConstants.navTrash &&
                  navItem != AppConstants.navCompleted)
                const QuickAddBar(),
              Expanded(child: _emptyStateForNav(navItem)),
            ],
          );
        }

        if (navItem == AppConstants.navTrash) {
          return Column(
            children: [
              _TrashActions(),
              Expanded(child: _FlatList(tasks: taskList)),
            ],
          );
        }

        if (navItem == AppConstants.navCompleted) {
          return _FlatList(tasks: taskList, header: const SizedBox.shrink());
        }

        return Column(
          children: [
            const QuickAddBar(),
            Expanded(child: _GroupedList(tasks: taskList)),
          ],
        );
      },
    );
  }

  Widget _emptyStateForNav(String navItem) {
    switch (navItem) {
      case AppConstants.navToday:
        return const EmptyState(emoji: '🌅', title: 'All clear today!',
            subtitle: 'No tasks due today. Enjoy your day!');
      case AppConstants.navCompleted:
        return const EmptyState(emoji: '🎯', title: 'Nothing completed yet',
            subtitle: 'Complete tasks to see them here.');
      case AppConstants.navTrash:
        return const EmptyState(emoji: '🗑️', title: 'Trash is empty',
            subtitle: 'Deleted tasks will appear here.');
      default:
        return const EmptyState(emoji: '📝', title: 'No tasks here',
            subtitle: 'Add a task using the bar above.');
    }
  }
}

// ── Flat list with optional drag-reorder ────────────────────────────────────
class _FlatList extends StatelessWidget {
  const _FlatList({required this.tasks, this.header});
  final List<Task> tasks;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        context.read<TaskProvider>().reorderTasks(tasks, oldIndex, newIndex);
      },
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        return _ReorderableTaskCard(
          key: ValueKey(task.id),
          task: task,
          index: i,
          isSelected: nav.selectedTaskId == task.id,
        );
      },
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final elev = Tween<double>(begin: 0, end: 8)
              .animate(CurvedAnimation(parent: animation,
                  curve: Curves.easeInOut))
              .value;
          return Material(
            elevation: elev,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

class _ReorderableTaskCard extends StatelessWidget {
  const _ReorderableTaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.isSelected,
  });

  final Task task;
  final int index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(child: TaskCard(task: task, isSelected: isSelected)),
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.drag_handle_rounded, size: 16,
                color: colors.textSecondary.withOpacity(0.4)),
          ),
        ),
      ],
    );
  }
}

// ── Grouped list ─────────────────────────────────────────────────────────────
class _GroupedList extends StatefulWidget {
  const _GroupedList({required this.tasks});
  final List<Task> tasks;

  @override
  State<_GroupedList> createState() => _GroupedListState();
}

class _GroupedListState extends State<_GroupedList> {
  final Map<String, bool> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final groups = _groupTasks(widget.tasks);

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: groups.entries.expand((entry) {
        final label = entry.key;
        final group = entry.value;
        final isCollapsed = _collapsed[label] ?? false;

        return [
          // Group header
          GestureDetector(
            onTap: () => setState(() => _collapsed[label] = !isCollapsed),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Icon(isCollapsed ? Icons.chevron_right : Icons.expand_more,
                      size: 16, color: context.appColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(label, style: AppTypography.bodySemibold.copyWith(
                      color: context.appColors.textSecondary)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: context.appColors.isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${group.length}',
                        style: AppTypography.caption.copyWith(
                            color: context.appColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed)
            ...group.map((task) => TaskCard(
              task: task,
              isSelected: nav.selectedTaskId == task.id,
            )),
        ];
      }).toList(),
    );
  }

  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    final groups = <String, List<Task>>{};
    for (final task in tasks) {
      String label;
      if (task.dueDate == null) {
        label = 'No Due Date';
      } else if (task.isOverdue && !AppDateUtils.isToday(task.dueDate!)) {
        label = 'Overdue';
      } else {
        label = AppDateUtils.groupLabel(task.dueDate!);
      }
      groups.putIfAbsent(label, () => []).add(task);
    }
    const order = ['Overdue', 'Today', 'Tomorrow', 'This Week', 'Later', 'No Due Date'];
    final sorted = <String, List<Task>>{};
    for (final key in order) {
      if (groups.containsKey(key)) sorted[key] = groups[key]!;
    }
    return sorted;
  }
}

// ── Trash header ─────────────────────────────────────────────────────────────
class _TrashActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.delete_forever_rounded, size: 16,
              color: Color(0xFFFF3B30)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Items in Trash will be permanently deleted after 30 days',
                style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => context.read<TaskProvider>().emptyTrash(),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: Text('Empty Trash',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
