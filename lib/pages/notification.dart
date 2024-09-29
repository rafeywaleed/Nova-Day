// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     const AndroidInitializationSettings androidInitializationSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: androidInitializationSettings);

//     await _notificationsPlugin.initialize(initializationSettings);
//   }

//   static Future<void> sendTestNotification() async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'test_channel',
//       'Test Notifications',
//       channelDescription: 'Channel for testing notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//       playSound: true,
//       enableVibration: true,
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     // await _notificationsPlugin.show(
//     //   0,
//     //   'Test Notification',
//     //   'This is a test notification to verify the setup!',
//     //   notificationDetails,
//     // );
//     await _notificationsPlugin.zonedSchedule(
//         0,
//         'Test Notification',
//         'This is a test notification to verify the setup!',
//         tz.TZDateTime.local(DateTime.now().year, DateTime.now().month,
//             DateTime.now().day, 22, 27, 0, 0, 0),
//         notificationDetails,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.wallClockTime,
//         matchDateTimeComponents: DateTimeComponents.dateAndTime);
//   }

//   static Future<void> scheduleNotifications() async {
//     print('Scheduling notifications...');
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails('daily_tasks_channel', 'Daily Tasks',
//             importance: Importance.high,
//             priority: Priority.high,
//             icon: '@mipmap/ic_launcher');

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     print("Scheduling notification at 11:40");

//     await _notificationsPlugin.zonedSchedule(
//       0,
//       'Your App Name',
//       'Have you done your tasks for today? aana to chahiye, 12:30',
//       _nextInstanceOfTime(7, 00),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       1,
//       'Your App Name',
//       'Have you done your tasks for today? 12 33',
//       _nextInstanceOfTime(7, 03),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       2,
//       'Your App Name',
//       'Have you done your tasks for today? 12 35',
//       _nextInstanceOfTime(7, 05),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       0,
//       'Your App Name',
//       'Have you done your tasks for today? aana to chahiye, 12:37',
//       _nextInstanceOfTime(7, 07),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       0,
//       'Your App Name',
//       'Have you done your tasks for today? aana to chahiye, 12:40',
//       _nextInstanceOfTime(7, 10),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       0,
//       'Your App Name',
//       'Have you done your tasks for today? aana to chahiye 12:42',
//       _nextInstanceOfTime(7, 12),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       0,
//       'Your App Name',
//       'Have you done your tasks for today? aana to chahiye. 12:43',
//       _nextInstanceOfTime(7, 13),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       0,
//       'Your App Name',
//       'Have you done your tasks for today? aana to chahiye, 12:45',
//       _nextInstanceOfTime(7, 15),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );
//   }

//   static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
//     print('Scheduling notification for: $hour:$minute');
//     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//     tz.TZDateTime scheduledDate =
//         tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(const Duration(days: 1));
//     }
//     return scheduledDate;
//   }
// }

// import 'dart:ui';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     const AndroidInitializationSettings androidInitializationSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: androidInitializationSettings);

//     await _notificationsPlugin.initialize(initializationSettings);
//   }

//   static Future<void> sendTestNotification() async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'test_channel',
//       'Test Notifications',
//       channelDescription: 'Channel for testing notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher', // Replace with your app logo or custom icon
//       playSound: true,
//       enableVibration: true,
//       color: const Color(0xFF2196F3), // Change to your desired color
//       largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Large icon for emphasis
//       styleInformation: BigTextStyleInformation(
//         'This is a test notification to verify the setup. This notification is using BigTextStyle to provide more information.',
//         contentTitle: 'Test Notification',
//         htmlFormatContent: true,
//         htmlFormatContentTitle: true,
//       ),
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     await _notificationsPlugin.zonedSchedule(
//         0,
//         'Test Notification',
//         'This is a test notification to verify the setup!',
//         tz.TZDateTime.local(DateTime.now().year, DateTime.now().month,
//             DateTime.now().day, 22, 27, 0, 0, 0),
//         notificationDetails,
//         androidAllowWhileIdle: true,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.wallClockTime,
//         matchDateTimeComponents: DateTimeComponents.dateAndTime);
//   }

//   static Future<void> scheduleNotifications() async {
//     print('Scheduling notifications...');
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'daily_tasks_channel',
//       'Daily Tasks',
//       channelDescription: 'Daily task reminder notifications',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//       playSound: true,
//       enableVibration: true,
//       color: const Color(0xFF42A5F5),
//       largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
//       styleInformation: BigTextStyleInformation(
//         'Have you done your tasks for today? Remember to complete your tasks to stay on track!',
//         contentTitle: 'Daily Task Reminder',
//         htmlFormatContent: true,
//         htmlFormatContentTitle: true,
//       ),
//     );

//     const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

//     await _notificationsPlugin.zonedSchedule(
//       0,
//       'Daily Task Reminder',
//       'Have you done your tasks for today?',
//       _nextInstanceOfTime(12, 30),
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       1,
//       'Daily Task Reminder',
//       'Have you done your tasks for today?',
//       _nextInstanceOfTime(18, 0), // Schedule for 6:00 PM
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       2,
//       'Daily Task Reminder',
//       'Have you done your tasks for today?',
//       _nextInstanceOfTime(22, 0), // Schedule for 10:00 PM
//       notificationDetails,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.wallClockTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );
//   }

//   static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
//     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//     tz.TZDateTime scheduledDate =
//         tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(const Duration(days: 1));
//     }
//     return scheduledDate;
//   }
// }

import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static Future<void> enableNotifications(bool enable) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enable);

    if (enable) {
      // If enabled, schedule the notifications
      await scheduleNotifications();
    } else {
      // If disabled, cancel all notifications
      await _notificationsPlugin.cancelAll();
    }
  }

  static Future<void> scheduleNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? false;

    if (!notificationsEnabled) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_tasks_channel',
      'Daily Tasks',
      channelDescription: 'Daily task reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      color: const Color(0xFF42A5F5),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Have you done your tasks for today? Remember to complete your tasks to stay on track!',
        contentTitle: 'Daily Task Reminder',
        htmlFormatContent: true,
        htmlFormatContentTitle: true,
      ),
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Schedule the notifications at specified times
    // await _notificationsPlugin.zonedSchedule(
    //   0,
    //   'Daily Task Reminder',
    //   'Have you done your tasks for today?',
    //   _nextInstanceOfTime(8, 50),
    //   notificationDetails,
    //   androidAllowWhileIdle: true,
    //   uiLocalNotificationDateInterpretation:
    //       UILocalNotificationDateInterpretation.wallClockTime,
    //   matchDateTimeComponents: DateTimeComponents.time,
    // );

    await _notificationsPlugin.zonedSchedule(
      0,
      'Daily Task Reminder',
      'Have you done your tasks for today?',
      _nextInstanceOfTime(6, 30),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _notificationsPlugin.zonedSchedule(
      1,
      'Daily Task Reminder',
      'Have you done your tasks for today?',
      _nextInstanceOfTime(12, 30), // Schedule for 6:00 PM
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _notificationsPlugin.zonedSchedule(
      2,
      'Daily Task Reminder',
      'Have you done your tasks for today?',
      _nextInstanceOfTime(16, 30), // Schedule for 10:00 PM
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
