import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    const windowsInit = WindowsInitializationSettings(
      appName: 'Taski',
      appUserModelId: 'com.taski.app',
      guid: '12345678-1234-1234-1234-123456789012',
    );

    const initSettings = InitializationSettings(windows: windowsInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
    _initialized = true;
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) return;
    // For Windows, we show immediate notifications (scheduled not fully supported)
    await showNotification(id: id, title: title, body: body);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    try {
      const windowsDetails = WindowsNotificationDetails();
      const details = NotificationDetails(windows: windowsDetails);
      await _plugin.show(id, title, body, details);
    } catch (_) {
      // Silently fail if notifications not supported
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
