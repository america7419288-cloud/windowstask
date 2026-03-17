import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

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
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
              Expanded(
                child: Text(
                  _monthTitle(_currentMonth),
                  textAlign: TextAlign.center,
                  style: AppTypography.headline.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ],
          ),
        ),
        // Day labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
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
        childAspectRatio: 0.85,
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

  String _monthTitle(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
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
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isToday ? accent.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? accent : colors.border.withOpacity(0.5),
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day number top-right
          Align(
            alignment: Alignment.topRight,
            child: Text(
              '$day',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday ? accent : colors.textPrimary,
              ),
            ),
          ),
          // Task dots
          ...tasks.take(3).map((t) => _TaskDot(task: t, colors: colors)),
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

class _TaskDot extends StatelessWidget {
  final Task task;
  final AppColorsExtension colors;

  const _TaskDot({required this.task, required this.colors});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: colors.textSecondary,
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
      case Priority.urgent:  return AppColors.pinkRed;
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

    return GestureDetector(
      onTap: () => nav.selectTask(task.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _priorityColor(task.priority),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                task.title,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  color: colors.textPrimary,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
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
      case Priority.urgent:  return AppColors.pinkRed;
    }
  }
}
