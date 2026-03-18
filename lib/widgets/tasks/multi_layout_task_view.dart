import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tasks/task_list_view.dart';
import '../../widgets/tasks/quick_add_bar.dart';
import '../../utils/constants.dart';
import 'today_header.dart';
import 'views/view_toggle_bar.dart';
import 'views/grid_view_layout.dart';
import 'views/compact_layout.dart';
import 'views/magazine_layout.dart';
import 'views/kanban_layout.dart';
import 'views/calendar_layout.dart';

class MultiLayoutTaskView extends StatelessWidget {
  const MultiLayoutTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    final globalDefault = context.watch<SettingsProvider>().currentLayout;
    final nav = context.watch<NavigationProvider>();
    // Use per-section layout, falling back to the global default from settings
    final layout = nav.layoutForCurrentSection(globalDefault);
    final tasks = context.watch<TaskProvider>();
    final navItem = nav.selectedNavItem;
    final query = nav.searchQuery;
    final taskList = tasks.getTasksForNav(navItem,
        searchQuery: query.isEmpty ? null : query);
    final allTasks = tasks.allTasks.where((t) => !t.isDeleted).toList();

    final bool showControls = navItem != AppConstants.navTrash &&
        navItem != AppConstants.navCompleted;

    final bool showHeader = navItem != AppConstants.navTrash &&
        navItem != AppConstants.navCompleted &&
        layout != TaskViewLayout.list;

    return Column(
      children: [
        if (showHeader)
          TodayHeader(
            taskCount: taskList.length,
            completedCount: taskList.where((t) => t.isCompleted).length,
          ),
        _LayoutHeader(showQuickAdd: showControls && layout != TaskViewLayout.list),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation, child: child,
            ),
            child: _buildLayout(
              layout, taskList, allTasks,
              key: ValueKey(layout),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayout(
    TaskViewLayout layout,
    List<Task> tasks,
    List<Task> allTasks, {
    Key? key,
  }) {
    switch (layout) {
      case TaskViewLayout.list:
        return TaskListView(key: key);
      case TaskViewLayout.grid:
        return GridViewLayout(key: key, tasks: tasks);
      case TaskViewLayout.kanban:
        return KanbanLayout(key: key, tasks: tasks);
      case TaskViewLayout.compact:
        return CompactLayout(key: key, tasks: tasks);
      case TaskViewLayout.magazine:
        return MagazineLayout(key: key, tasks: tasks);
      case TaskViewLayout.calendar:
        return CalendarLayout(key: key, allTasks: allTasks);
      default:
        return const TaskListView();
    }
  }
}

class _LayoutHeader extends StatelessWidget {
  final bool showQuickAdd;
  const _LayoutHeader({required this.showQuickAdd});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          if (showQuickAdd) const Expanded(child: QuickAddBar()),
          if (!showQuickAdd) const Spacer(),
          const SizedBox(width: 12),
          const ViewToggleBar(),
        ],
      ),
    );
  }
}
