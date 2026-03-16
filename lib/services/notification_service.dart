// Notification service - simplified for Windows compatibility
// flutter_local_notifications Windows support has limited API
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  Future<void> init() async {
    _initialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Notifications are handled natively where available
    // This is a no-op stub for compatibility
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // No-op for now
  }

  Future<void> cancelNotification(int id) async {
    // No-op
  }

  Future<void> cancelAll() async {
    // No-op
  }
}
