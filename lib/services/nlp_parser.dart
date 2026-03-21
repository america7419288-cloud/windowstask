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
  final String? listName;
  final List<String> tags;

  const ParsedTaskInput({
    required this.title,
    this.dueDate,
    this.dueHour,
    this.dueMinute,
    this.priority,
    this.isFlagged = false,
    this.recurrence,
    this.listName,
    this.tags = const [],
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
    String? listName;
    List<String> tags = [];

    // ── DATE PARSING ─────────────────────────
    // ... existing logic ...
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_match(text, r'\btoday\b')) {
      dueDate = today;
      text = _remove(text, r'\btoday\b');
    } else if (_match(text, r'\btomorrow\b')) {
      dueDate = today.add(const Duration(days: 1));
      text = _remove(text, r'\btomorrow\b');
    } else if (_match(text, r'\bnext\s+(mon|tue|wed|thu|fri|sat|sun)(day|days)?\b')) {
      final m = RegExp(r'\bnext\s+(mon|tue|wed|thu|fri|sat|sun)(day|days)?\b', caseSensitive: false).firstMatch(text);
      if (m != null) {
        dueDate = _nextWeekday(m.group(1)!.toLowerCase());
        text = text.replaceFirst(m.group(0)!, '');
      }
    } else if (_match(text, r'\b(this\s+|on\s+)?(mon|tue|wed|thu|fri|sat|sun)(day|days)?\b')) {
      final m = RegExp(r'\b(this\s+|on\s+)?(mon|tue|wed|thu|fri|sat|sun)(day|days)?\b', caseSensitive: false).firstMatch(text);
      if (m != null) {
        dueDate = _thisWeekday(m.group(2)!.toLowerCase());
        text = text.replaceFirst(m.group(0)!, '');
      }
    } else {
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
    final exactTimeMatch = RegExp(r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b|\bat\s+(\d{1,2})(?::(\d{2}))?\b|\b(\d{1,2}):(\d{2})\b', caseSensitive: false).firstMatch(text);
    if (exactTimeMatch != null) {
      String textHour = exactTimeMatch.group(1) ?? exactTimeMatch.group(4) ?? exactTimeMatch.group(6)!;
      String textMin = exactTimeMatch.group(2) ?? exactTimeMatch.group(5) ?? exactTimeMatch.group(7) ?? '0';
      String? ampm = exactTimeMatch.group(3)?.toLowerCase();

      int hour = int.parse(textHour);
      int minute = int.parse(textMin);

      if (ampm == 'pm' && hour < 12) hour += 12;
      else if (ampm == 'am' && hour == 12) hour = 0;

      dueHour = hour; dueMinute = minute;
      dueDate ??= today;
      text = text.replaceFirst(exactTimeMatch.group(0)!, '');
    }

    final relTimeMatch = RegExp(r'\bin\s+(\d+)\s+(hour|hours|hr|hrs|min|mins|minute|minutes)\b', caseSensitive: false).firstMatch(text);
    if (relTimeMatch != null && dueHour == null) {
      final amount = int.parse(relTimeMatch.group(1)!);
      final unit = relTimeMatch.group(2)!.toLowerCase();
      
      var targetTime = DateTime.now();
      if (unit.startsWith('h')) {
        targetTime = targetTime.add(Duration(hours: amount));
      } else {
        targetTime = targetTime.add(Duration(minutes: amount));
      }

      dueDate = DateTime(targetTime.year, targetTime.month, targetTime.day);
      dueHour = targetTime.hour;
      dueMinute = targetTime.minute;
      text = text.replaceFirst(relTimeMatch.group(0)!, '');
    }

    // ── PRIORITY PARSING ─────────────────────
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
    if (_match(text, r'\b(!flag|!f)\b|\*')) {
      isFlagged = true;
      text = _remove(text, r'\b(!flag|!f)\b|\*');
    }

    // ── RECURRENCE PARSING ────────────────────
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

    // ── LIST PARSING (#listname) ──────────────────
    final listMatch = RegExp(r'#(\w+)\b').firstMatch(text);
    if (listMatch != null) {
      listName = listMatch.group(1);
      text = text.replaceFirst(listMatch.group(0)!, '');
    }

    // ── TAG PARSING (@tagname) ──────────────────
    final tagMatches = RegExp(r'@(\w+)\b').allMatches(text);
    for (final m in tagMatches) {
      tags.add(m.group(1)!);
    }
    text = text.replaceAll(RegExp(r'@\w+\b'), '');

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
      listName: listName,
      tags: tags,
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
