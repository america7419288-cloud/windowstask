import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/recurrence.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RecurrencePicker extends StatefulWidget {
  final RecurrenceRule? initial;

  const RecurrencePicker({super.key, this.initial});

  static Future<RecurrenceRule?> show(
    BuildContext context, {
    RecurrenceRule? initial,
  }) async {
    return showDialog<RecurrenceRule>(
      context: context,
      builder: (context) => RecurrencePicker(initial: initial),
    );
  }

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  late RecurrenceFrequency _frequency;
  late int _interval;
  late List<int> _weekdays;
  DateTime? _endDate;
  int? _maxOccurrences;

  String _endOption = 'Never';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _frequency = widget.initial!.frequency;
      _interval = widget.initial!.interval;
      _weekdays = List.from(widget.initial!.weekdays);
      _endDate = widget.initial!.endDate;
      _maxOccurrences = widget.initial!.maxOccurrences;
      
      if (_endDate != null) _endOption = 'On Date';
      else if (_maxOccurrences != null) _endOption = 'After N times';
      else _endOption = 'Never';
    } else {
      _frequency = RecurrenceFrequency.daily;
      _interval = 1;
      _weekdays = [];
      _endOption = 'Never';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = colors.accent;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIcons.repeat(), color: accent, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Set Recurrence',
                  style: AppTypography.title2.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildLabel('Frequency'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RecurrenceFrequency>(
                  value: _frequency,
                  isExpanded: true,
                  dropdownColor: colors.surfaceElevated,
                  items: RecurrenceFrequency.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(
                        f.name[0].toUpperCase() + f.name.substring(1),
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _frequency = val);
                  },
                ),
              ),
            ),
            
            if (_frequency == RecurrenceFrequency.weekly) ...[
              const SizedBox(height: 24),
              _buildLabel('Repeat on'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [1, 2, 3, 4, 5, 6, 7].map((d) {
                  final isSelected = _weekdays.contains(d);
                  final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d - 1];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _weekdays.remove(d);
                        } else {
                          _weekdays.add(d);
                        }
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? accent : colors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? accent : colors.border),
                      ),
                      child: Text(
                        dayName,
                        style: AppTypography.caption.copyWith(
                          color: isSelected ? Colors.white : colors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            if (_frequency == RecurrenceFrequency.custom) ...[
              const SizedBox(height: 24),
              _buildLabel('Every (days)'),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Days',
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: TextEditingController(text: _interval.toString()),
                onChanged: (val) {
                  final n = int.tryParse(val);
                  if (n != null && n > 0) _interval = n;
                },
              ),
            ],

            const SizedBox(height: 24),
            _buildLabel('Ends'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildEndChip('Never'),
                const SizedBox(width: 8),
                _buildEndChip('On Date'),
                const SizedBox(width: 8),
                _buildEndChip('After N times'),
              ],
            ),
            
            if (_endOption == 'On Date') ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _endDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.calendar(), size: 16, color: colors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _endDate == null ? 'Pick date' : DateFormat('MMM d, yyyy').format(_endDate!),
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            if (_endOption == 'After N times') ...[
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Occurrences',
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: TextEditingController(text: (_maxOccurrences ?? 10).toString()),
                onChanged: (val) {
                  final n = int.tryParse(val);
                  if (n != null && n > 0) _maxOccurrences = n;
                },
              ),
            ],

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Remove Recurrence', style: AppTypography.body.copyWith(color: Colors.redAccent)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, RecurrenceRule(
                      frequency: _frequency,
                      interval: _interval,
                      weekdays: _weekdays,
                      endDate: _endOption == 'On Date' ? _endDate : null,
                      maxOccurrences: _endOption == 'After N times' ? _maxOccurrences : null,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.caption.copyWith(
        color: context.appColors.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEndChip(String label) {
    final colors = context.appColors;
    final accent = colors.accent;
    final isSelected = _endOption == label;

    return GestureDetector(
      onTap: () => setState(() => _endOption = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.1) : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? accent : colors.border),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? accent : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
