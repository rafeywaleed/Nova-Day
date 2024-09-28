// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:permission_handler/permission_handler.dart';

// class NotificationService {
//   Future<void> requestPermissions() async {
//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.requestNotificationsPermission();
//   }

//   static Future<void> requestNotificationPermission() async {
//     final status = await Permission.notification.request();
//     if (status.isGranted) {
//       print("Notification permission granted.");
//     } else {
//       print("Notification permission denied.");
//     }
//   }

//   static Function? _onSelectNotificationCallback;

//   static void setOnSelectNotificationCallback(Function callback) {
//     _onSelectNotificationCallback = callback;
//   }

//   static Future<void> onSelectNotification(String? payload) async {
//     _onSelectNotificationCallback?.call();
//   }

//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     const AndroidInitializationSettings androidInitializationSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: androidInitializationSettings);

//     await _notificationsPlugin.initialize(initializationSettings);
//     await _createNotificationChannel();
//   }

//   static Future<void> _createNotificationChannel() async {
//     final channel = AndroidNotificationChannel(
//       'daily_tasks_channel',
//       'Daily Tasks',
//       description: 'Channel for daily task reminders',
//       importance: Importance.max,
//     );

//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     print("Notification channel created: ${channel.id}");
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

//     await _notificationsPlugin.show(
//       0,
//       'Test Notification',
//       'This is a test notification to verify the setup!',
//       notificationDetails,
//     );
//   }

//   static Future<void> scheduleNotifications() async {
//     print('Scheduling notifications...');
//     const androidDetails = AndroidNotificationDetails(
//       'daily_tasks_channel',
//       'Daily Tasks',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     await _scheduleAtTime(0, '09:00', notificationDetails);
//     await _scheduleAtTime(1, '18:00', notificationDetails);
//     await _scheduleAtTime(2, '01:18', notificationDetails);
//   }

//   static Future<void> _scheduleAtTime(
//       int id, String time, NotificationDetails notificationDetails) async {
//     final parts = time.split(':');
//     final hour = int.parse(parts[0]);
//     final minute = int.parse(parts[1]);

//     print("Scheduling notification at $time");
//     try {
//       await _notificationsPlugin.zonedSchedule(
//         id,
//         'Hundred Days',
//         'Have you done your tasks for today?',
//         _nextInstanceOfTime(hour, minute),
//         notificationDetails,
//         androidAllowWhileIdle: true,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.wallClockTime,
//         matchDateTimeComponents: DateTimeComponents.time,
//       );
//       print("Notification scheduled for $time");
//     } catch (e) {
//       print("Error scheduling notification: $e");
//     }
//   }

//   static Future<void> schedulePeriodicNotification() async {
//     const androidDetails = AndroidNotificationDetails(
//       'daily_tasks_channel',
//       'Daily Tasks',
//       channelDescription: 'Channel for daily task reminders',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     // Show notification daily
//     await _notificationsPlugin.periodicallyShow(
//       3,
//       'Hundred Days',
//       'Daily reminder: Have you done your tasks for today?',
//       RepeatInterval.daily,
//       notificationDetails,
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
