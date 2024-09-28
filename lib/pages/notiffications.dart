// // import 'package:flutter/material.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import 'package:timezone/data/latest.dart' as tz;
// // import 'package:timezone/timezone.dart' as tz;
// // import 'package:permission_handler/permission_handler.dart';

// // class NotificationHome extends StatefulWidget {
// //   @override
// //   _NotificationHomeState createState() => _NotificationHomeState();
// // }

// // class _NotificationHomeState extends State<NotificationHome> {
// //   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
// //       FlutterLocalNotificationsPlugin();

// //   @override
// //   void initState() {
// //     super.initState();
// //     _initializeNotifications();
// //   }

// //   Future<void> _initializeNotifications() async {
// //     // Request notification permissions
// //     if (await Permission.notification.request().isGranted) {
// //       // Permission granted, initialize notifications
// //       const AndroidInitializationSettings initializationSettingsAndroid =
// //           AndroidInitializationSettings('@mipmap/ic_launcher');

// //       const InitializationSettings initializationSettings =
// //           InitializationSettings(android: initializationSettingsAndroid);

// //       await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
// //     } else {
// //       // Handle the case when permission is not granted
// //       print('Notification permission denied');
// //     }
// //   }

// //   Future<void> _scheduleDailyNotifications() async {
// //     List<NotificationTime> notificationTimes = [
// //       NotificationTime(hour: 3, minute: 45),
// //       NotificationTime(hour: 18, minute: 0),
// //       NotificationTime(hour: 22, minute: 0),
// //     ];

// //     for (var notificationTime in notificationTimes) {
// //       await NotificationScheduler.scheduleDailyNotifications(
// //         _flutterLocalNotificationsPlugin,
// //         notificationTime,
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Schedule Notifications'),
// //       ),
// //       body: Center(
// //         child: ElevatedButton(
// //           onPressed: _scheduleDailyNotifications,
// //           child: Text('Schedule Notifications'),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class NotificationTime {
// //   int hour;
// //   int minute;

// //   NotificationTime({required this.hour, required this.minute});
// // }

// // class NotificationScheduler {
// //   static Future<void> scheduleDailyNotifications(
// //       FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
// //       NotificationTime notificationTime) async {
// //     const AndroidNotificationDetails androidPlatformChannelSpecifics =
// //         AndroidNotificationDetails(
// //       'daily_notifications',
// //       'Daily Notifications',
// //       channelDescription:
// //           'Notifications that are scheduled daily at specific times.',
// //       importance: Importance.max,
// //       priority: Priority.high,
// //       showWhen: false,
// //     );

// //     const NotificationDetails platformChannelSpecifics =
// //         NotificationDetails(android: androidPlatformChannelSpecifics);

// //     int notificationId =
// //         notificationTime.hour * 100 + notificationTime.minute; // Unique ID

// //     print(
// //         'Scheduling notification at ${notificationTime.hour}:${notificationTime.minute}');

// //     await flutterLocalNotificationsPlugin.zonedSchedule(
// //       notificationId,
// //       'Scheduled Notification',
// //       'This is your notification at ${notificationTime.hour}:${notificationTime.minute}!',
// //       _getScheduledTime(notificationTime.hour, notificationTime.minute),
// //       platformChannelSpecifics,
// //       androidAllowWhileIdle: true,
// //       uiLocalNotificationDateInterpretation:
// //           UILocalNotificationDateInterpretation.absoluteTime,
// //     );
// //     print('Notification scheduled with ID: $notificationId');
// //   }

// //   static tz.TZDateTime _getScheduledTime(int hour, int minute) {
// //     final now = tz.TZDateTime.now(tz.local);
// //     final scheduledDate = tz.TZDateTime(
// //       tz.local,
// //       now.year,
// //       now.month,
// //       now.day,
// //       hour,
// //       minute,
// //     );

// //     return scheduledDate.isBefore(now)
// //         ? scheduledDate.add(const Duration(days: 1))
// //         : scheduledDate;
// //   }
// // }

// import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart';

// class NotificationHelper {
//   static final fln.FlutterLocalNotificationsPlugin _notification = fln.FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     // Initialize timezone data
//     tz.initializeDatabase(List.empty());

//     // Initialize notification settings
//     const fln.AndroidInitializationSettings initializationSettingsAndroid =
//         fln.AndroidInitializationSettings('@mipmap/ic_launcher');
//     const fln.DarwinInitializationSettings initializationSettingsIOS = fln.DarwinInitializationSettings();

//     const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );

//     await _notification.initialize(initializationSettings);
//   }

//   static Future<void> scheduleNotification(String title, String body) async {
//     const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
//       'important_notifications',
//       'My Channel',
//       channelDescription: 'Channel for important notifications',
//       importance: fln.Importance.max,
//       priority: fln.Priority.high,
//       showWhen: false,
//     );

//     // fln.IOSNotificationDetails iosDetails = fln.IOSNotificationDetails(
//     //   presentAlert: true,
//     //   presentBadge: true,
//     //   presentSound: true,
//     // );

//     const fln.NotificationDetails notificationDetails = fln.NotificationDetails(
//       android: androidDetails,
//     //  iOS: iosDetails,
//     );

//     await _notification.zonedSchedule(
//       0,
//       title,
//       body,
//       tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3)), // Scheduled time
//       notificationDetails,
//       uiLocalNotificationDateInterpretation: fln.UILocalNotificationDateInterpretation.absoluteTime,
//       androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
//     );
//   }
// }
