// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:workmanager/src/workmanager.dart';
// import 'package:workmanager/workmanager.dart';

// class NotificationScheduler {
//   static const String notificationTask = 'dailyNotificationsTask';

//   static void scheduleDailyNotifications() {
//     Workmanager().registerPeriodicTask(
//       notificationTask,
//       notificationTask,
//       frequency: const Duration(hours: 24),
//       initialDelay: const Duration(minutes: 1),
//     );
//   }

//   static void callbackDispatcher() {
//     Workmanager().executeTask((task) async {
//       final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//           FlutterLocalNotificationsPlugin();

//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');

//       const InitializationSettings initializationSettings =
//           InitializationSettings(android: initializationSettingsAndroid);

//       await flutterLocalNotificationsPlugin.initialize(initializationSettings);

//       // Request notification permissions
//       if (await Permission.notification.request().isGranted) {
//         // Schedule notifications
//         List<NotificationTime> notificationTimes = [
//           NotificationTime(hour: 6, minute: 45),
//           NotificationTime(hour: 18, minute: 0),
//           NotificationTime(hour: 22, minute: 0),
//         ];

//         for (var notificationTime in notificationTimes) {
//           await scheduleDailyNotification(
//             flutterLocalNotificationsPlugin,
//             notificationTime,
//           );
//         }
//       } else {
//         print('Notification permission denied');
//       }

//       return Future.value(true);
//     } as BackgroundTaskHandler);
//   }

//   static Future<void> scheduleDailyNotification(
//     FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
//     NotificationTime notificationTime,
//   ) async {
//     tz.initializeTimeZones();
//     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//     final tz.TZDateTime scheduledDate = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       notificationTime.hour,
//       notificationTime.minute,
//     );

//     if (scheduledDate.isBefore(now)) {
//       scheduledDate.add(Duration(days: 1));
//     }

//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       0,
//       'Reminder',
//       'Complete your tasks!',
//       scheduledDate,
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'channelId',
//           'channelName',
//           importance: Importance.max,
//         ),
//       ),
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }
// }

// class NotificationTime {
//   final int hour;
//   final int minute;

//   NotificationTime({required this.hour, required this.minute});
// }