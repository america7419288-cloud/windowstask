import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';

class MiniCalendar extends StatefulWidget {
  const MiniCalendar({super.key, this.onDaySelected});
  final ValueChanged<DateTime>? onDaySelected;

  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final tasks = context.watch<TaskProvider>();
    final days = AppDateUtils.daysInMonth(_displayMonth.year, _displayMonth.month);
    final firstWeekday = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday;

    // Get days with tasks
    final daysWithTasks = <int>{};
    for (final task in tasks.allTasks) {
      if (!task.isDeleted && task.dueDate != null &&
          task.dueDate!.year == _displayMonth.year &&
          task.dueDate!.month == _displayMonth.month) {
        daysWithTasks.add(task.dueDate!.day);
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Column(
        children: [
          // Month header
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
                }),
                child: Icon(Icons.chevron_left, size: 16, color: colors.textSecondary),
              ),
              Expanded(
                child: Text(
                  '${_monthName(_displayMonth.month)} ${_displayMonth.year}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
                }),
                child: Icon(Icons.chevron_right, size: 16, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekdays
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => Expanded(
              child: Text(d, textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: colors.textSecondary)),
            )).toList(),
          ),
          const SizedBox(height: 4),
          // Days
          ..._buildWeeks(context, days, firstWeekday, daysWithTasks, accent),
        ],
      ),
    );
  }

  List<Widget> _buildWeeks(BuildContext context, List<DateTime> days, int firstWeekday,
      Set<int> daysWithTasks, Color accent) {
    final colors = context.appColors;
    final rows = <Widget>[];
    int dayIdx = 0;

    final totalCells = firstWeekday - 1 + days.length;
    final numRows = (totalCells / 7).ceil();

    for (int row = 0; row < numRows; row++) {
      rows.add(Row(
        children: List.generate(7, (col) {
          final cellIdx = row * 7 + col;
          final dIdx = cellIdx - (firstWeekday - 1);
          if (dIdx < 0 || dIdx >= days.length) {
            return const Expanded(child: SizedBox(height: 28));
          }
          final date = days[dIdx];
          final isToday = AppDateUtils.isToday(date);
          final isSelected = _selected != null &&
              date.year == _selected!.year &&
              date.month == _selected!.month &&
              date.day == _selected!.day;
          final hasTask = daysWithTasks.contains(date.day);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selected = date);
                widget.onDaySelected?.call(date);
              },
              child: Container(
                height: 28,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: isToday && !isSelected
                      ? Border.all(color: accent, width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white : colors.textPrimary,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (hasTask && !isSelected)
                      Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ));
    }
    return rows;
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
