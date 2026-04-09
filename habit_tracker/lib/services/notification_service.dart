import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required List<int> weekdays,
  }) async {
    for (final day in weekdays) {
      await _plugin.periodicallyShow(
        id + day,
        title,
        '今日の習慣を完了しましょう！',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminder',
            '習慣リマインダー',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
