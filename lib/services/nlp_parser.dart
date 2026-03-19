import '../models/task.dart';
import '../models/recurrence.dart';

class ParsedTaskInput {
  final String title;        // cleaned title
  final DateTime? dueDate;
  final int? dueHour;
  final int? dueMinute;
  final Priority? priority;
  final bool isFlagged;
  final RecurrenceRule? recurrence;

  const ParsedTaskInput({
    required this.title,
    this.dueDate,
    this.dueHour,
    this.dueMinute,
    this.priority,
    this.isFlagged = false,
    this.recurrence,
  });
}

class NlpParser {
  static ParsedTaskInput parse(String raw) {
    String text = raw.trim();
    DateTime? dueDate;
    int? dueHour;
    int? dueMinute;
    Priority? priority;
    bool isFlagged = false;
    RecurrenceRule? recurrence;

    // ── DATE PARSING ─────────────────────────
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // "today"
    if (_match(text, r'\btoday\b')) {
      dueDate = today;
      text = _remove(text, r'\btoday\b');
    }
    // "tomorrow"
    else if (_match(text, r'\btomorrow\b')) {
      dueDate = today.add(const Duration(days: 1));
      text = _remove(text, r'\btomorrow\b');
    }
    // "next monday/tuesday/..." 
    else if (_match(text, r'\bnext\s+(mon|tue|wed|thu|fri|sat|sun)(\w*)\b')) {
      final m = RegExp(r'\bnext\s+(mon|tue|wed|thu|fri|sat|sun)(\w*)\b', caseSensitive: false).firstMatch(text);
      if (m != null) {
        dueDate = _nextWeekday(m.group(1)!.toLowerCase());
        text = text.replaceFirst(m.group(0)!, '');
      }
    }
    // "this friday" / "on friday"
    else if (_match(text, r'\b(this\s+|on\s+)?(mon|tue|wed|thu|fri|sat|sun)(\w*)\b')) {
      final m = RegExp(r'\b(this\s+|on\s+)?(mon|tue|wed|thu|fri|sat|sun)(\w*)\b', caseSensitive: false).firstMatch(text);
      if (m != null) {
        dueDate = _thisWeekday(m.group(2)!.toLowerCase());
        text = text.replaceFirst(m.group(0)!, '');
      }
    }
    // "in 3 days" / "in 2 weeks"
    else {
      final inMatch = RegExp(r'\bin\s+(\d+)\s+(day|days|week|weeks)\b', caseSensitive: false).firstMatch(text);
      if (inMatch != null) {
        final n = int.parse(inMatch.group(1)!);
        final unit = inMatch.group(2)!.toLowerCase();
        final days = unit.startsWith('week') ? n * 7 : n;
        dueDate = today.add(Duration(days: days));
        text = text.replaceFirst(inMatch.group(0)!, '');
      }
    }

    // ── TIME PARSING ─────────────────────────
    // "at 3pm" / "at 14:30" / "3:30pm"
    final timeMatch = RegExp(r'\bat?\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b', caseSensitive: false).firstMatch(text);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final period = timeMatch.group(3)?.toLowerCase();

      if (period == 'pm' && hour < 12) {
        hour += 12;
      } else if (period == 'am' && hour == 12) {
        hour = 0;
      }

      dueHour = hour;
      dueMinute = minute;
      // Default to today if only time given
      dueDate ??= today;
      text = text.replaceFirst(timeMatch.group(0)!, '');
    }

    // ── PRIORITY PARSING ─────────────────────
    // "!urgent" / "!u" / "p0"
    if (_match(text, r'\b(!urgent|!u|p0)\b')) {
      priority = Priority.urgent;
      text = _remove(text, r'\b(!urgent|!u|p0)\b');
    } else if (_match(text, r'\b(!high|!h|p1)\b')) {
      priority = Priority.high;
      text = _remove(text, r'\b(!high|!h|p1)\b');
    } else if (_match(text, r'\b(!medium|!med|!m|p2)\b')) {
      priority = Priority.medium;
      text = _remove(text, r'\b(!medium|!med|!m|p2)\b');
    } else if (_match(text, r'\b(!low|!l|p3)\b')) {
      priority = Priority.low;
      text = _remove(text, r'\b(!low|!l|p3)\b');
    }

    // ── FLAG PARSING ──────────────────────────
    // "!flag" / "!f" / "*"
    if (_match(text, r'\b(!flag|!f)\b|\*')) {
      isFlagged = true;
      text = _remove(text, r'\b(!flag|!f)\b|\*');
    }

    // ── RECURRENCE PARSING ────────────────────
    // "every day" / "every week" / "daily" / "weekly"
    if (_match(text, r'\b(daily|every\s+day)\b')) {
      recurrence = const RecurrenceRule(frequency: RecurrenceFrequency.daily);
      text = _remove(text, r'\b(daily|every\s+day)\b');
    } else if (_match(text, r'\b(weekly|every\s+week)\b')) {
      recurrence = const RecurrenceRule(frequency: RecurrenceFrequency.weekly);
      text = _remove(text, r'\b(weekly|every\s+week)\b');
    } else if (_match(text, r'\b(monthly|every\s+month)\b')) {
      recurrence = const RecurrenceRule(frequency: RecurrenceFrequency.monthly);
      text = _remove(text, r'\b(monthly|every\s+month)\b');
    }

    // Clean up extra whitespace
    final title = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedTaskInput(
      title: title.isEmpty ? raw : title,
      dueDate: dueDate,
      dueHour: dueHour,
      dueMinute: dueMinute,
      priority: priority,
      isFlagged: isFlagged,
      recurrence: recurrence,
    );
  }

  // ── Helpers ───────────────────────────────

  static bool _match(String text, String pattern) =>
      RegExp(pattern, caseSensitive: false).hasMatch(text);

  static String _remove(String text, String pattern) =>
      text.replaceAll(RegExp(pattern, caseSensitive: false), '').trim();

  static DateTime _nextWeekday(String abbr) {
    final map = {'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7};
    final target = map[abbr] ?? 1;
    final now = DateTime.now();
    int daysAhead = target - now.weekday;
    if (daysAhead <= 0) daysAhead += 7;
    return DateTime(now.year, now.month, now.day + daysAhead);
  }

  static DateTime _thisWeekday(String abbr) {
    final map = {'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7};
    final target = map[abbr] ?? 1;
    final now = DateTime.now();
    int daysAhead = target - now.weekday;
    if (daysAhead < 0) daysAhead += 7;
    return DateTime(now.year, now.month, now.day + daysAhead);
  }
}
