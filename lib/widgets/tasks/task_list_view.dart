import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../shared/empty_state_widget.dart';
import '../../painters/empty_state_painters.dart';
import 'task_card.dart';
import 'quick_add_bar.dart';
import 'group_header.dart';
import 'today_header.dart';

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
              Expanded(child: _emptyStateForNav(context, navItem)),
            ],
          );
        }

        Widget content;
        if (navItem == AppConstants.navTrash) {
          content = Column(
            children: [
              _TrashActions(),
              Expanded(child: _FlatList(tasks: taskList)),
            ],
          );
        } else if (navItem == AppConstants.navCompleted) {
          content = _FlatList(tasks: taskList, header: const SizedBox.shrink());
        } else {
          final todayCompleted = taskList.where((t) => t.isCompleted).length;
          content = Column(
            children: [
              TodayHeader(
                taskCount: taskList.length,
                completedCount: todayCompleted,
              ),
              const QuickAddBar(),
              Expanded(child: _GroupedList(tasks: taskList)),
            ],
          );
        }

        return _SmoothScrollWrapper(child: content);
      },
    );
  }

  Widget _emptyStateForNav(BuildContext context, String navItem) {
    switch (navItem) {
      case AppConstants.navToday:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            painterBuilder: (v) => TodayEmptyPainter(v),
            headline: 'Nothing due today',
            subline: 'Enjoy the breathing room — or get ahead on tomorrow.',
            ctaLabel: 'Add a task',
            onCta: () {},
          ),
        );
      case AppConstants.navUpcoming:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            painterBuilder: (v) => UpcomingEmptyPainter(v),
            headline: 'Clear skies ahead',
            subline: 'No tasks scheduled for the coming week.',
            ctaLabel: 'Plan ahead',
          ),
        );
      case AppConstants.navCompleted:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            painterBuilder: (_) => CompletedEmptyPainter(1.0),
            headline: 'Nothing completed yet',
            subline: 'Finish a task and it\'ll show up here.',
          ),
        );
      case AppConstants.navTrash:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            painterBuilder: (v) => SearchEmptyPainter(v),
            headline: 'Trash is empty',
            subline: 'Deleted tasks will appear here.',
          ),
        );
      case AppConstants.navAll:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            painterBuilder: (v) => AllTasksEmptyPainter(v),
            headline: 'Your space, your tasks',
            subline: 'Start by adding your first task. It only takes a second.',
            ctaLabel: 'Create your first task',
          ),
        );
      default:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            painterBuilder: (v) => SearchEmptyPainter(v),
            headline: 'No tasks here',
            subline: 'Try different keywords or clear your filters.',
          ),
        );
    }
  }
}

// ── Smooth Scroll Wrapper ──────────────────────────────────────────────────
class _SmoothScrollWrapper extends StatefulWidget {
  final Widget child;
  const _SmoothScrollWrapper({required this.child});

  @override
  State<_SmoothScrollWrapper> createState() => _SmoothScrollWrapperState();
}

class _SmoothScrollWrapperState extends State<_SmoothScrollWrapper> {
  final _scrollController = ScrollController();
  final _containerKey = GlobalKey();
  bool _isHoveringScrollbar = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PrimaryScrollController(
      controller: _scrollController,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false, overscroll: false),
        child: RawScrollbar(
          controller: _scrollController,
          thumbColor: colors.textTertiary.withValues(alpha: _isHoveringScrollbar ? 0.6 : 0.3),
          radius: const Radius.circular(4),
          thickness: 6,
          crossAxisMargin: 2,
          fadeDuration: const Duration(milliseconds: 200),
          timeToFade: const Duration(milliseconds: 800),
          child: Container(
            key: _containerKey,
            child: MouseRegion(
              onHover: (e) {
                final box = _containerKey.currentContext
                    ?.findRenderObject() as RenderBox?;
                final width = box?.size.width ?? 0;
                final isNearScrollbar = e.localPosition.dx > width - 20;
                if (isNearScrollbar != _isHoveringScrollbar) {
                  setState(() => _isHoveringScrollbar = isNearScrollbar);
                }
              },
              onExit: (_) {
                if (_isHoveringScrollbar) {
                  setState(() => _isHoveringScrollbar = false);
                }
              },
              child: ShaderMask(
                shaderCallback: (Rect rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.05, 0.95, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: widget.child,
              ),
            ),
        ),
      ),
      ),
    );
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
      padding: const EdgeInsets.only(top: 12, bottom: 40),
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
          final elev = Tween<double>(begin: 0, end: 12)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic))
              .value;
          return Material(
            color: Colors.transparent,
            elevation: elev,
            shadowColor: Colors.black26,
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
                color: colors.textTertiary.withValues(alpha: 0.4)),
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
      padding: const EdgeInsets.only(top: 4, bottom: 40),
      children: groups.entries.expand((entry) {
        final label = entry.key;
        final group = entry.value;
        final isCollapsed = _collapsed[label] ?? false;

        return [
          GroupHeader(
            label: label,
            count: group.length,
            isCollapsed: isCollapsed,
            onTap: () => setState(() => _collapsed[label] = !isCollapsed),
          ),
          // We wrap the list in AnimatedCrossFade or similar for smooth collapse
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
            crossFadeState: isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: group.map((task) => TaskCard(
                key: ValueKey(task.id),
                task: task,
                isSelected: nav.selectedTaskId == task.id,
              )).toList(),
            ),
          ),
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
        color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.2)),
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
