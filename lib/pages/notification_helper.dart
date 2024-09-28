// import 'dart:async';
// import 'dart:developer';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart';
// import 'package:timezone/timezone.dart' as tz;

// class LocalNotificationService {
//   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   static final StreamController<NotificationResponse> streamController =
//       StreamController();

//   static void onTap(NotificationResponse notificationResponse) {
//     streamController.add(notificationResponse);
//     // Handle the tap event
//   }

//   static Future<void> init(BuildContext context) async {
//     const InitializationSettings settings = InitializationSettings(
//       android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       iOS: DarwinInitializationSettings(),
//     );

//     await flutterLocalNotificationsPlugin.initialize(
//       settings,
//       onDidReceiveNotificationResponse: onTap,
//     );

//     // Request permission for iOS
//     if (Theme.of(context).platform == TargetPlatform.iOS) {
//       final permissionStatus = await flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//               IOSFlutterLocalNotificationsPlugin>()
//           ?.requestPermissions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );
//       // Check if permission is granted
//       if (permissionStatus != null && !permissionStatus) {
//         // Handle permission not granted
//         log("Notification permissions not granted.");
//       }
//     }
//   }

//   static Future<void> scheduleDailyNotification() async {
//     print("inside scheduleDailyNotifications ");
//     const AndroidNotificationDetails android = AndroidNotificationDetails(
//       'daily_notification',
//       'Daily Notification',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
//     const NotificationDetails details = NotificationDetails(android: android);

//     var currentTime = DateTime.now();
//     var scheduleTime = DateTime(currentTime.year, currentTime.month,
//         currentTime.day, 3, 06); // Example: 2:52 AM

//     if (scheduleTime.isBefore(currentTime)) {
//       scheduleTime = scheduleTime.add(Duration(days: 1)); // Schedule for the next day
//     }

//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       0,
//       'Daily Notification',
//       'Have you done your tasks for today?',
//       tz.TZDateTime.from(scheduleTime, tz.local), // Convert to TZDateTime
//       details,
//       androidAllowWhileIdle: true,
//       payload: 'scheduledNotification',
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );

//     log("Notification scheduled for: $scheduleTime");
//   }
// }
