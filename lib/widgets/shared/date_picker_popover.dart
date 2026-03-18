import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';

class DatePickerPopover extends StatefulWidget {
  const DatePickerPopover({
    super.key,
    this.initialDate,
    required this.onDateSelected,
    this.onClear,
  });

  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onClear;

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    DateTime? result;
    await showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: _DatePickerDialog(
          initialDate: initialDate,
          onDateSelected: (d) {
            result = d;
            Navigator.pop(ctx);
          },
        ),
      ),
    );
    return result;
  }

  @override
  State<DatePickerPopover> createState() => _DatePickerPopoverState();
}

class _DatePickerPopoverState extends State<DatePickerPopover> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({
    this.initialDate,
    required this.onDateSelected,
  });

  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _displayMonth;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _displayMonth = DateTime(
      widget.initialDate?.year ?? DateTime.now().year,
      widget.initialDate?.month ?? DateTime.now().month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final days = AppDateUtils.daysInMonth(_displayMonth.year, _displayMonth.month);
    final firstWeekday = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday;
    final totalCells = firstWeekday - 1 + days.length;
    final rows = (totalCells / 7).ceil();

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusModal),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month nav
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: () => setState(() {
                  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Expanded(
                child: Text(
                  '${_monthName(_displayMonth.month)} ${_displayMonth.year}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySemibold.copyWith(color: colors.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed: () => setState(() {
                  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekdays
          Row(
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          // Days grid
          for (int row = 0; row < rows; row++)
            Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayIndex = cellIndex - (firstWeekday - 1);
                if (dayIndex < 0 || dayIndex >= days.length) {
                  return const Expanded(child: SizedBox(height: 32));
                }
                final date = days[dayIndex];
                final isSelected = _selected != null &&
                    date.year == _selected!.year &&
                    date.month == _selected!.month &&
                    date.day == _selected!.day;
                final isToday = AppDateUtils.isToday(date);
                final accent = Theme.of(context).colorScheme.primary;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = date);
                      widget.onDateSelected(date);
                    },
                    child: Container(
                      height: 32,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday && !isSelected
                            ? Border.all(color: accent, width: 1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: AppTypography.body.copyWith(
                            color: isSelected
                                ? Colors.white
                                : colors.textPrimary,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          // Quick pick
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              _quickPick('Today', DateTime.now()),
              _quickPick('Tomorrow', DateTime.now().add(const Duration(days: 1))),
              _quickPick('Next Week', DateTime.now().add(const Duration(days: 7))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickPick(String label, DateTime date) {
    return GestureDetector(
      onTap: () {
        setState(() => _selected = date);
        widget.onDateSelected(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusChip),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
