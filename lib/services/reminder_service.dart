import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:win_toast/win_toast.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  Timer? _timer;
  List<Task> _tasks = [];
  final Set<String> _firedToday = {};
  BuildContext? _context;

  void init(BuildContext context) {
    _context = context;
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(minutes: 1), (_) => _check());
  }

  void updateTasks(List<Task> tasks) {
    _tasks = tasks;
    // Reset fired set at midnight
    final now = DateTime.now();
    if (now.hour == 0 && now.minute == 0) {
      _firedToday.clear();
    }
  }

  void _check() {
    final now = DateTime.now();
    for (final task in _tasks) {
      if (task.isCompleted || task.isDeleted) continue;
      if (task.dueDate == null) continue;
      if (!task.hasReminder) continue;
      if (task.dueHour == null) continue;

      final dueDateTime = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.dueHour!,
        task.dueMinute ?? 0,
      );

      final reminderTime = dueDateTime.subtract(
        Duration(minutes: task.reminderMinutesBefore));

      // Fire if within the current minute
      final diff = now.difference(reminderTime);
      if (diff.inSeconds >= 0 && diff.inSeconds < 60) {
        final key = '${task.id}_${reminderTime.toIso8601String()}';
        if (!_firedToday.contains(key)) {
          _firedToday.add(key);
          _showNotification(task, dueDateTime);
        }
      }
    }
  }

  void _showNotification(Task task, DateTime dueDateTime) async {
    final timeStr =
        '${task.dueHour!.toString().padLeft(2,'0')}:'
        '${(task.dueMinute ?? 0).toString().padLeft(2,'0')}';

    if (!kIsWeb) {
      try {
        await NotificationService.instance.showNotification(
          taskId: task.id,
          title: '⏰ ${task.title}',
          body: 'Due at $timeStr',
        );
        return;
      } catch (_) {}
    }

    // In-app fallback
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(SnackBar(
        content: Row(children: [
          const Text('⏰ '),
          Expanded(child: Text('${task.title} — due at $timeStr')),
        ]),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ));
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
