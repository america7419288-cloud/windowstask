import 'dart:io';
import 'dart:async';
import 'package:win_toast/win_toast.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final Map<String, Timer> _scheduledTimers = {};

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (Platform.isWindows) {
      _initialized = await WinToast.instance().initialize(
        aumId: 'APCore.KeepList',
        displayName: 'Taski',
        iconPath: '',
        clsid: 'EFA15552-1F74-4372-B18E-46FC1458CA8C',
      );
    } else {
      _initialized = true;
    }
  }

  Future<void> showNotification({
    required String taskId,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    final id = _hashId(taskId);
    if (Platform.isWindows) {
      final xml = """
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$title</text>
      <text>$body</text>
    </binding>
  </visual>
</toast>
""";
      await WinToast.instance().showCustomToast(xml: xml);
    }
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await init();
    await cancelNotification(taskId);
    
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    final id = _hashId(taskId);
    final delay = scheduledTime.difference(now);
    if (delay.inMinutes < 60) {
      _scheduledTimers[taskId] = Timer(delay, () {
        showNotification(taskId: taskId, title: title, body: body);
        _scheduledTimers.remove(taskId);
      });
    }
  }

  Future<void> cancelNotification(String taskId) async {
    _scheduledTimers[taskId]?.cancel();
    _scheduledTimers.remove(taskId);
    // Note: win_toast doesn't expose an ID-based cancellation for active toasts 
    // but this ensures consistency in our internal scheduling logic.
  }

  int _hashId(String id) {
    // Simple hash function for positive integers
    return id.hashCode.abs() % 1000000;
  }

  Future<void> cancelAll() async {
    // no-op
  }
}
