import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  static bool isWithinNextDays(DateTime date, int days) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return date.isAfter(now.subtract(const Duration(days: 1))) &&
        date.isBefore(future.add(const Duration(days: 1)));
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    if (date.year == now.year) {
      return DateFormat('EEE, MMM d').format(date);
    }
    return DateFormat('MMM d, y').format(date);
  }

  static String formatShortDate(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    return DateFormat('MMM d').format(date);
  }

  static String formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  static String formatDateTime(DateTime date, {int? hour, int? minute}) {
    final dateStr = formatDate(date);
    if (hour != null && minute != null) {
      return '$dateStr at ${formatTime(hour, minute)}';
    }
    return dateStr;
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  static String groupLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff <= 7) return 'This Week';
    return 'Later';
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  static List<DateTime> daysInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final daysCount = DateTime(year, month + 1, 0).day;
    return List.generate(daysCount, (i) => first.add(Duration(days: i)));
  }

  static String weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
