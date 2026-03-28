import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;
  String _view = 'Month';

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tasks = context.watch<TaskProvider>();
    final nav = context.read<NavigationProvider>();

    final pendingCount = _pendingInMonth(tasks);
    final selectedDayTasks = _selected != null
        ? _tasksForDay(tasks, _selected!)
        : <Task>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ────────────────────────────────
            _buildHeader(colors, pendingCount),
            const SizedBox(height: 24),
            // Two columns
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left 70% — calendar grid
                  Expanded(
                    flex: 70,
                    child: _buildCalendarGrid(colors, tasks),
                  ),
                  const SizedBox(width: 24),
                  // Right 30% — day detail + focus score
                  Expanded(
                    flex: 30,
                    child: _buildRightPanel(colors, tasks, nav, selectedDayTasks),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ── HEADER ──────────────────────────────────────────────────────────
  Widget _buildHeader(AppColorsExtension colors, int pendingCount) {
    return Row(
      children: [
        // Month navigation
        GestureDetector(
          onTap: _prevMonth,
          child: Icon(Icons.chevron_left_rounded,
              size: 22, color: colors.textSecondary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_monthName(_displayMonth.month)} ${_displayMonth.year}',
              style: AppTypography.displayLG.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '$pendingCount Tasks pending this month',
              style: AppTypography.bodySM.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _nextMonth,
          child: Icon(Icons.chevron_right_rounded,
              size: 22, color: colors.textSecondary),
        ),
        const Spacer(),
        // View toggle pills
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: ['Month', 'Week', 'Day'].map((v) {
              final isActive = _view == v;
              return GestureDetector(
                onTap: () => setState(() => _view = v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isActive ? AppColors.gradPrimary : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    v,
                    style: AppTypography.labelMD.copyWith(
                      color: isActive
                          ? Colors.white
                          : colors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── CALENDAR GRID ───────────────────────────────────────────────────
  Widget _buildCalendarGrid(AppColorsExtension colors, TaskProvider tasks) {
    final weeks = _buildWeeks();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadowSM(isDark: colors.isDark),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AppTypography.micro.copyWith(
                            color: colors.textQuaternary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          // Day rows
          ...weeks.map((week) => Row(
                children: week.map((day) {
                  final isToday = _isToday(day);
                  final isSelected = _isSelected(day);
                  final isOtherMonth = _isOtherMonth(day);

                  return Expanded(
                    child: GestureDetector(
                      onTap: day != null
                          ? () => setState(() => _selected = day)
                          : null,
                      child: Container(
                        height: 52,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.indigo
                              : isSelected
                                  ? AppColors.indigoDim
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day != null ? '${day.day}' : '',
                              style: AppTypography.titleSM.copyWith(
                                color: isToday
                                    ? Colors.white
                                    : isOtherMonth
                                        ? colors.textQuaternary
                                        : colors.textPrimary,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Priority dots
                            if (day != null && _hasTasks(tasks, day))
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _dotsForDay(tasks, day)
                                    .take(3)
                                    .map((c) => Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? Colors.white
                                                    .withValues(alpha: .8)
                                                : c,
                                            shape: BoxShape.circle,
                                          ),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }

  // ── RIGHT PANEL ─────────────────────────────────────────────────────
  Widget _buildRightPanel(
    AppColorsExtension colors,
    TaskProvider tasks,
    NavigationProvider nav,
    List<Task> selectedDayTasks,
  ) {
    final focusScore = _calcFocusScore(tasks);

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // Selected day header
        Row(
          children: [
            Text(
              _selected != null
                  ? '${_dayFullName(_selected!.weekday)}, ${_selected!.day}'
                  : 'Select a day',
              style: AppTypography.displayLG.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            if (_isToday(_selected))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.gradPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'TODAY',
                  style: AppTypography.micro.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Tasks for selected day
        if (selectedDayTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No tasks for this day',
              style: AppTypography.caption
                  .copyWith(color: colors.textTertiary),
            ),
          )
        else
          ...selectedDayTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.priorityColor(task.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: AppTypography.titleSM.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.textTertiary,
                            ),
                          ),
                          if (task.dueHour != null)
                            Text(
                              '${task.dueHour.toString().padLeft(2, '0')}:'
                              '${(task.dueMinute ?? 0).toString().padLeft(2, '0')}',
                              style: AppTypography.caption.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

        const SizedBox(height: 12),

        // Add entry button
        GestureDetector(
          onTap: () => nav.openQuickAdd(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Add entry for this day',
                style: AppTypography.labelMD.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Focus Score card
        _buildFocusScore(colors, focusScore),
      ],
    );
  }

  Widget _buildFocusScore(AppColorsExtension colors, int focusScore) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradMomentum,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowPrimary(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Score',
            style: AppTypography.titleMD.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$focusScore%',
                style: AppTypography.displayXL.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _focusLabel(focusScore),
                  style: AppTypography.bodyMD.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: focusScore / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _focusComparisonText(focusScore),
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  void _prevMonth() {
    setState(() {
      _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  List<List<DateTime?>> _buildWeeks() {
    final first = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final last = DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    final startOffset = first.weekday % 7; // Sunday = 0

    final List<DateTime?> days = [];
    for (int i = 0; i < startOffset; i++) {
      days.add(null);
    }
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(_displayMonth.year, _displayMonth.month, d));
    }
    while (days.length % 7 != 0) {
      days.add(null);
    }

    final List<List<DateTime?>> weeks = [];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }
    return weeks;
  }

  bool _isToday(DateTime? day) {
    if (day == null) return false;
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  bool _isSelected(DateTime? day) {
    if (day == null || _selected == null) return false;
    return day.year == _selected!.year &&
        day.month == _selected!.month &&
        day.day == _selected!.day;
  }

  bool _isOtherMonth(DateTime? day) {
    if (day == null) return false;
    return day.month != _displayMonth.month;
  }

  bool _hasTasks(TaskProvider tasks, DateTime day) {
    return _tasksForDay(tasks, day).isNotEmpty;
  }

  List<Color> _dotsForDay(TaskProvider tasks, DateTime day) {
    return _tasksForDay(tasks, day)
        .take(3)
        .map((t) => AppColors.priorityColor(t.priority))
        .toList();
  }

  List<Task> _tasksForDay(TaskProvider tasks, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return tasks.allTasks.where((t) {
      if (t.isDeleted) return false;
      if (t.dueDate == null) return false;
      return !t.dueDate!.isBefore(dayStart) && t.dueDate!.isBefore(dayEnd);
    }).toList();
  }

  int _pendingInMonth(TaskProvider tasks) {
    final start = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final end =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0, 23, 59, 59);
    return tasks.allTasks.where((t) {
      if (t.isDeleted || t.isCompleted) return false;
      if (t.dueDate == null) return false;
      return !t.dueDate!.isBefore(start) && !t.dueDate!.isAfter(end);
    }).length;
  }

  int _calcFocusScore(TaskProvider tasks) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final start =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    int created = 0;
    int completed = 0;
    for (final t in tasks.allTasks) {
      if (t.isDeleted) continue;
      if (!t.createdAt.isBefore(start)) created++;
      if (t.isCompleted &&
          t.completedAt != null &&
          !t.completedAt!.isBefore(start)) {
        completed++;
      }
    }
    if (created == 0) return 0;
    return ((completed / created) * 100).clamp(0, 100).round();
  }

  String _focusLabel(int score) {
    if (score >= 80) return 'Highly Productive';
    if (score >= 60) return 'On Track';
    if (score >= 40) return 'Getting There';
    return 'Keep Going';
  }

  String _focusComparisonText(int score) {
    if (score >= 80) return 'Outstanding focus this week! 🔥';
    if (score >= 60) return 'Great progress, keep the momentum!';
    if (score >= 40) return 'Building momentum — stay consistent.';
    return 'Every task completed counts. You got this!';
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return names[month];
  }

  String _dayFullName(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return names[weekday - 1];
  }
}
