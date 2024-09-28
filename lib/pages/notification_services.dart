import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleNotifications() async {
    print('Scheduling notifications...');
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('daily_tasks_channel', 'Daily Tasks',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher');

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    print("Scheduling notification at 17:50");

    await _notificationsPlugin.zonedSchedule(
      0,
      'Your App Name',
      'Have you done your tasks for today?',
      _nextInstanceOfTime(18, 02),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _notificationsPlugin.zonedSchedule(
      1,
      'Your App Name',
      'Have you done your tasks for today?',
      _nextInstanceOfTime(18, 0),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _notificationsPlugin.zonedSchedule(
      2,
      'Your App Name',
      'Have you done your tasks for today?',
      _nextInstanceOfTime(22, 0),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    print('Scheduling notification for: $hour:$minute');
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
