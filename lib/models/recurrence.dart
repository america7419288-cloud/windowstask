import 'package:intl/intl.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,    // every 2 weeks
  monthly,
  yearly,
  custom,      // every N days
}

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;      // for custom: every N days
  final List<int> weekdays; // for weekly: [1,3,5] = Mon,Wed,Fri
  final DateTime? endDate; // null = forever
  final int? maxOccurrences;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const [],
    this.endDate,
    this.maxOccurrences,
  });

  Map<String, dynamic> toJson() => {
    'frequency': frequency.name,
    'interval': interval,
    'weekdays': weekdays,
    'endDate': endDate?.toIso8601String(),
    'maxOccurrences': maxOccurrences,
  };

  factory RecurrenceRule.fromJson(Map<String, dynamic> j) =>
    RecurrenceRule(
      frequency: RecurrenceFrequency.values
          .byName(j['frequency'] as String),
      interval: j['interval'] as int? ?? 1,
      weekdays: (j['weekdays'] as List?)
          ?.map((e) => e as int).toList() ?? [],
      endDate: j['endDate'] != null
          ? DateTime.parse(j['endDate'] as String)
          : null,
      maxOccurrences: j['maxOccurrences'] as int?,
    );

  // Calculate next due date from a given date
  DateTime nextDate(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(Duration(days: interval));
      case RecurrenceFrequency.weekly:
        if (weekdays.isEmpty) {
          return from.add(const Duration(days: 7));
        }
        // Find next weekday in the list
        DateTime next = from.add(const Duration(days: 1));
        while (!weekdays.contains(next.weekday)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RecurrenceFrequency.biweekly:
        return from.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        // Leap directly to the next month by setting day to 1 (avoiding skip/overflow)
        final nextTargetStart = DateTime(from.year, from.month + 1, 1);
        final targetYear = nextTargetStart.year;
        final targetMonth = nextTargetStart.month;
        
        // Find the last day of the target month by looking at the 0th day of the NEXT month
        final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
        final targetDay = from.day > lastDay ? lastDay : from.day;
        
        return DateTime(targetYear, targetMonth, targetDay, from.hour, from.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
      case RecurrenceFrequency.custom:
        return from.add(Duration(days: interval));
    }
  }

  String get displayLabel {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceFrequency.weekly:
        if (weekdays.isEmpty) return 'Weekly';
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays.map((d) => days[d - 1]).join(', ');
      case RecurrenceFrequency.biweekly:
        return 'Every 2 weeks';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
      case RecurrenceFrequency.custom:
        return 'Every $interval days';
    }
  }
}
