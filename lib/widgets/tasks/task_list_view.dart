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
import '../../data/app_stickers.dart';
import 'task_card.dart';
import 'quick_add_bar.dart';
import 'group_header.dart';
import 'filter_bar.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector2<NavigationProvider, TaskProvider, Map<String, dynamic>>(
      selector: (context, nav, tasks) => {
        'navItem': nav.selectedNavItem,
        'query': nav.searchQuery,
        'filterMITs': nav.filterMITs,
        'filterHighPriority': nav.filterHighPriority,
        'filterOverdue': nav.filterOverdue,
        'mitIds': nav.mitTaskIds,
        'taskList': tasks.getTasksForNav(
          nav.selectedNavItem,
          searchQuery: nav.searchQuery.isEmpty ? null : nav.searchQuery,
          filterMITs: nav.filterMITs,
          filterHighPriority: nav.filterHighPriority,
          filterOverdue: nav.filterOverdue,
          mitIds: nav.mitTaskIds,
        ),
      },
      builder: (context, data, _) {
        final navItem = data['navItem'] as String;
        final taskList = data['taskList'] as List<Task>;
        final mitIds = data['mitIds'] as List<String>;

        if (taskList.isEmpty) {
          return Column(
            children: [
              if (navItem != AppConstants.navTrash &&
                  navItem != AppConstants.navCompleted)
                QuickAddBar(),
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
          content = Column(
            children: [
              QuickAddBar(),
              const FilterBar(),
              if (navItem == AppConstants.navToday && mitIds.isNotEmpty)
                _MITSection(mitIds: mitIds),
              Expanded(child: _GroupedList(tasks: taskList)),
            ],
          );
        }

        return content;
      },
    );
  }

  Widget _emptyStateForNav(BuildContext context, String navItem) {
    switch (navItem) {
      case AppConstants.navToday:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            stickerPath: AppStickers.emptyTodayPath,
            headline: 'Nothing on your plate today',
            subline: 'Use the capture bar to add tasks or check your upcoming schedule.',
            ctaLabel: 'Add a Task',
            onCta: () => context.read<NavigationProvider>().openQuickAdd(),
          ),
        );
      case AppConstants.navUpcoming:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            stickerPath: AppStickers.emptyUpcomingPath,
            headline: 'Your future is clear',
            subline: 'Tasks with upcoming due dates will appear here.',
            ctaLabel: null,
          ),
        );
      case AppConstants.navCompleted:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            stickerPath: AppStickers.emptyCompletedPath,
            headline: 'No finished tasks yet',
            subline: 'Complete tasks to see your progress here and earn XP.',
            ctaLabel: null,
          ),
        );
      case AppConstants.navTrash:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            stickerPath: AppStickers.emptyAllTasksPath,
            headline: 'Trash is empty',
            subline: 'Deleted tasks will appear here.',
            ctaLabel: null,
          ),
        );
      case AppConstants.navAll:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            stickerPath: AppStickers.emptyAllTasksPath,
            headline: 'No tasks yet',
            subline: 'Start capturing your thoughts and tasks to get organized.',
            ctaLabel: 'Create First Task',
            onCta: () => context.read<NavigationProvider>().openQuickAdd(),
          ),
        );
      case AppConstants.navFlagged:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            stickerPath: AppStickers.emptyTodayPath,
            headline: 'No flagged tasks',
            subline: 'Bookmark important tasks so you can find them quickly.',
            ctaLabel: null,
          ),
        );
      case AppConstants.navHighPriority:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            stickerPath: AppStickers.emptyAllTasksPath,
            headline: 'All clear on the urgent front',
            subline: 'Tasks marked high or urgent priority will appear here.',
            ctaLabel: null,
          ),
        );
      default:
        return EmptyStateWidget(
          config: EmptyStateConfig(
            stickerPath: AppStickers.emptyAllTasksPath,
            headline: 'No tasks here',
            subline: 'Try different keywords or clear your filters.',
            ctaLabel: null,
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
        return Selector<NavigationProvider, bool>(
          key: ValueKey('reorder_item_${task.id}'),
          selector: (_, n) => n.selectedTaskId == task.id,
          builder: (context, isSelected, _) => _ReorderableTaskCard(
            task: task,
            index: i,
            isSelected: isSelected,
          ),
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
    return ReorderableDragStartListener(
      index: index,
      child: TaskCard(task: task, isSelected: isSelected),
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
      children: groups.entries.expand<Widget>((entry) {
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
              children: group.map<Widget>((task) => Selector<NavigationProvider, bool>(
                selector: (_, n) => n.selectedTaskId == task.id,
                builder: (context, isSelected, _) => TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  isSelected: isSelected,
                ),
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
      if (context.read<NavigationProvider>().selectedNavItem == AppConstants.navAll && task.isCompleted) {
        groups.putIfAbsent('Completed', () => []).add(task);
        continue;
      }

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
    const order = ['Overdue', 'Today', 'Tomorrow', 'This Week', 'Later', 'No Due Date', 'Completed'];
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
class _MITSection extends StatelessWidget {
  final List<String> mitIds;
  const _MITSection({required this.mitIds});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tasks = context.watch<TaskProvider>();
    final mitTasks = mitIds
        .map((id) => tasks.getById(id))
        .whereType<Task>()
        .where((t) => !t.isCompleted)
        .toList();

    if (mitTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MIT header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(children: [
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD60A)),
            const SizedBox(width: 6),
            Text('TOP PRIORITIES',
              style: AppTypography.micro.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFFFFD60A),
              )),
            const SizedBox(width: 12),
            Expanded(child: Container(
              height: 0.5,
              color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
            )),
          ]),
        ),
        // MIT task cards
        ...mitTasks.map((t) => TaskCard(
          key: ValueKey('mit_${t.id}'),
          task: t,
          isSelected: false,
        )),
        const SizedBox(height: 8),
        Divider(height: 1, color: colors.divider),
      ],
    );
  }
}
