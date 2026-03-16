import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import '../../utils/constants.dart';
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
        final taskList = tasks.getTasksForNav(navItem, searchQuery: query.isEmpty ? null : query);

        if (taskList.isEmpty) {
          return Column(
            children: [
              const QuickAddBar(),
              Expanded(child: _emptyStateForNav(navItem)),
            ],
          );
        }

        // Group tasks for certain views
        if (navItem == AppConstants.navToday ||
            navItem == AppConstants.navUpcoming ||
            navItem == AppConstants.navAll) {
          return _GroupedTaskList(tasks: taskList, navItem: navItem);
        }

        if (navItem == AppConstants.navCompleted) {
          return _CompletedTaskList(tasks: taskList);
        }

        return _FlatTaskList(navItem: navItem, tasks: taskList);
      },
    );
  }

  Widget _emptyStateForNav(String navItem) {
    switch (navItem) {
      case AppConstants.navToday:
        return const EmptyState(
          emoji: '🌅',
          title: 'All clear today!',
          subtitle: 'No tasks due today. Enjoy your day!',
        );
      case AppConstants.navCompleted:
        return const EmptyState(
          emoji: '🎯',
          title: 'Nothing completed yet',
          subtitle: 'Complete tasks to see them here.',
        );
      case AppConstants.navTrash:
        return const EmptyState(
          emoji: '🗑️',
          title: 'Trash is empty',
          subtitle: 'Deleted tasks will appear here.',
        );
      default:
        return const EmptyState(
          emoji: '📝',
          title: 'No tasks here',
          subtitle: 'Add a task using the bar above.',
        );
    }
  }
}

class _FlatTaskList extends StatelessWidget {
  const _FlatTaskList({required this.navItem, required this.tasks});

  final String navItem;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final isTrash = navItem == AppConstants.navTrash;
    final nav = context.read<NavigationProvider>();

    return Column(
      children: [
        if (!isTrash) const QuickAddBar(),
        if (isTrash) _TrashActions(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            itemCount: tasks.length,
            itemBuilder: (ctx, i) => TaskCard(
              task: tasks[i],
              isSelected: nav.selectedTaskId == tasks[i].id,
            ),
          ),
        ),
      ],
    );
  }
}

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
          const Icon(Icons.delete_forever_rounded, size: 16, color: Color(0xFFFF3B30)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Items in Trash will be permanently deleted after 30 days',
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => context.read<TaskProvider>().emptyTrash(),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: Text('Empty Trash', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _GroupedTaskList extends StatefulWidget {
  const _GroupedTaskList({required this.tasks, required this.navItem});

  final List<Task> tasks;
  final String navItem;

  @override
  State<_GroupedTaskList> createState() => _GroupedTaskListState();
}

class _GroupedTaskListState extends State<_GroupedTaskList> {
  final Map<String, bool> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final groups = _groupTasks(widget.tasks);

    return Column(
      children: [
        const QuickAddBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            children: groups.entries.map((entry) {
              final label = entry.key;
              final group = entry.value;
              final isCollapsed = _collapsed[label] ?? false;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group header
                  GestureDetector(
                    onTap: () => setState(() => _collapsed[label] = !isCollapsed),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          Icon(
                            isCollapsed ? Icons.chevron_right : Icons.expand_more,
                            size: 16,
                            color: context.appColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: AppTypography.bodySemibold.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.appColors.isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${group.length}',
                              style: AppTypography.caption.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
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
                ],
              );
            }).toList(),
          ),
        ),
      ],
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
    // Sort by date priority
    const order = ['Overdue', 'Today', 'Tomorrow', 'This Week', 'Later', 'No Due Date'];
    final sorted = <String, List<Task>>{};
    for (final key in order) {
      if (groups.containsKey(key)) sorted[key] = groups[key]!;
    }
    return sorted;
  }
}

class _CompletedTaskList extends StatelessWidget {
  const _CompletedTaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    // Group by completion date
    final groups = <String, List<Task>>{};
    for (final task in tasks) {
      final key = task.completedAt != null
          ? AppDateUtils.formatShortDate(task.completedAt!)
          : 'Unknown';
      groups.putIfAbsent(key, () => []).add(task);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                entry.key,
                style: AppTypography.bodySemibold.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
            ...entry.value.map((task) => TaskCard(
                  task: task,
                  isSelected: nav.selectedTaskId == task.id,
                )),
          ],
        );
      }).toList(),
    );
  }
}
