import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../shared/task_interaction_wrapper.dart';
import '../../context_menu/context_menu_controller.dart';
import '../../../providers/task_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CalendarLayout extends StatefulWidget {
  final List<Task> allTasks;
  const CalendarLayout({super.key, required this.allTasks});

  @override
  State<CalendarLayout> createState() => _CalendarLayoutState();
}

class _CalendarLayoutState extends State<CalendarLayout> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  final PageController _pageController = PageController(initialPage: 600);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    final dayTasksForSelected = _selectedDay != null
        ? widget.allTasks.where((t) =>
            t.dueDate != null &&
            t.dueDate!.year == _selectedDay!.year &&
            t.dueDate!.month == _selectedDay!.month &&
            t.dueDate!.day == _selectedDay!.day).toList()
        : <Task>[];

    return Column(
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _CalNavBtn(
                icon: PhosphorIcons.caretLeft(),
                onTap: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                ),
              ),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: '${_monthNameFull(_currentMonth)} ',
                    style: AppTypography.headline.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                    children: [
                      TextSpan(
                        text: '${_currentMonth.year}',
                        style: AppTypography.headline.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _CalNavBtn(
                icon: PhosphorIcons.caretRight(),
                onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ],
          ),
        ),
        // Day labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .asMap().entries.map((entry) {
                  final isWeekend = entry.key >= 5;
                  return Expanded(
                    child: Center(
                      child: Text(
                        entry.value,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isWeekend ? colors.textQuaternary : colors.textTertiary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Calendar grid via PageView for slide animation
        Expanded(
          flex: 3,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 1200,
            onPageChanged: (page) {
              final now = DateTime.now();
              final base = DateTime(now.year, now.month);
              final monthOffset = page - 600;
              setState(() {
                try {
                  _currentMonth = DateTime(base.year, base.month + monthOffset);
                } catch (_) {}
              });
            },
            itemBuilder: (context, page) {
              final now = DateTime.now();
              final base = DateTime(now.year, now.month);
              final monthOffset = page - 600;
              DateTime month;
              try {
                month = DateTime(base.year, base.month + monthOffset);
              } catch (_) {
                return const SizedBox.shrink();
              }
              return _buildCalendarGrid(month, colors, accent);
            },
          ),
        ),
        // Selected day tasks panel
        if (_selectedDay != null && dayTasksForSelected.isNotEmpty) ...[
          Divider(height: 1, color: colors.divider),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '${_selectedDay!.day} ${_monthName(_selectedDay!.month)} — ${dayTasksForSelected.length} task${dayTasksForSelected.length == 1 ? '' : 's'}',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dayTasksForSelected.length,
                    itemBuilder: (context, i) {
                      final t = dayTasksForSelected[i];
                      return _DayTaskRow(task: t);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime month, AppColorsExtension colors, Color accent) {
    final firstDay = DateTime(month.year, month.month, 1);
    // Weekday: Monday = 1, so offset is (weekday - 1)
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, idx) {
        final dayNum = idx - startOffset + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return const SizedBox.shrink(); // Empty cells
        }

        final date = DateTime(month.year, month.month, dayNum);
        final isToday = _isToday(date);
        final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);
        final dayTasks = widget.allTasks
            .where((t) => t.dueDate != null && _isSameDay(t.dueDate!, date))
            .toList();

        return GestureDetector(
          onTap: () => setState(() {
            _selectedDay = isSelected ? null : date;
          }),
          child: _DayCell(
            day: dayNum,
            tasks: dayTasks,
            isToday: isToday,
            isSelected: isSelected,
            colors: colors,
            accent: accent,
          ),
        );
      },
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthNameFull(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[d.month - 1];
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}

class _CalNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalNavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<Task> tasks;
  final bool isToday;
  final bool isSelected;
  final AppColorsExtension colors;
  final Color accent;

  const _DayCell({
    required this.day,
    required this.tasks,
    required this.isToday,
    required this.isSelected,
    required this.colors,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isToday ? accent.withValues(alpha: 0.08) : (isSelected ? colors.surface : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? accent : (isToday ? accent.withValues(alpha: 0.3) : colors.border.withValues(alpha: 0.4)),
          width: isSelected || isToday ? 1.5 : 0.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day number
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isToday ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$day',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? Colors.white : colors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Task pills
          ...tasks.take(3).map((t) => _TaskPill(task: t, colors: colors, accent: accent)),
          // Overflow
          if (tasks.length > 3)
            Text(
              '+${tasks.length - 3}',
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: colors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskPill extends StatelessWidget {
  final Task task;
  final AppColorsExtension colors;
  final Color accent;

  const _TaskPill({required this.task, required this.colors, required this.accent});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    final isCompleted = task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isCompleted
            ? colors.textTertiary.withValues(alpha: 0.1)
            : priorityColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCompleted ? Colors.transparent : priorityColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isCompleted ? colors.textTertiary : priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCompleted ? FontWeight.w400 : FontWeight.w500,
                color: isCompleted ? colors.textSecondary : colors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.none:    return AppColors.blue;
      case Priority.low:     return AppColors.green;
      case Priority.medium:  return AppColors.orange;
      case Priority.high:    return AppColors.red;
      case Priority.urgent:  return AppColors.pink;
    }
  }
}

class _DayTaskRow extends StatelessWidget {
  final Task task;
  const _DayTaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.read<NavigationProvider>();

    return TaskInteractionWrapper(
      task: task,
      actionsPosition: HoverActionsPosition.bottomBar,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => nav.selectTask(task.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.read<TaskProvider>().toggleComplete(task.id),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? AppColors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: task.isCompleted
                          ? null
                          : Border.all(color: colors.textSecondary, width: 1.5),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.none:    return AppColors.blue;
      case Priority.low:     return AppColors.green;
      case Priority.medium:  return AppColors.orange;
      case Priority.high:    return AppColors.red;
      case Priority.urgent:  return AppColors.pink;
    }
  }
}
