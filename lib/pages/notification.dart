import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

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

  static Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // await _notificationsPlugin.show(
    //   0,
    //   'Test Notification',
    //   'This is a test notification to verify the setup!',
    //   notificationDetails,
    // );
    await _notificationsPlugin.zonedSchedule(
        0,
        'Test Notification',
        'This is a test notification to verify the setup!',
        tz.TZDateTime.local(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 22, 27, 0, 0, 0),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime);
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
      'Have you done your tasks for today? aana to chahiye',
      _nextInstanceOfTime(22, 50),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _notificationsPlugin.zonedSchedule(
      1,
      'Your App Name',
      'Have you done your tasks for today? 4 22',
      _nextInstanceOfTime(22, 52),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _notificationsPlugin.zonedSchedule(
      2,
      'Your App Name',
      'Have you done your tasks for today? 4 25',
      _nextInstanceOfTime(22, 55),
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
