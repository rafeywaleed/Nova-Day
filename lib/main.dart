import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hundred_days/auth/login.dart';
import 'package:hundred_days/auth/welcome.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:hundred_days/pages/notiffications.dart';
import 'package:sizer/sizer.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

void main() async {
  tz.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  NotificationHelper.init();
  await Firebase.initializeApp();

  await Hive.initFlutter();
  await Hive.openBox('userBox');

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    'dailyNotifications',
    'dailyNotificationsTask',
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 1),
  );

  runApp(const HundredDays());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background task executed: $task");

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permissions
    if (await Permission.notification.request().isGranted) {
      // Schedule notifications
      List<NotificationTime> notificationTimes = [
        NotificationTime(hour: 3, minute: 45),
        NotificationTime(hour: 18, minute: 0),
        NotificationTime(hour: 22, minute: 0),
      ];

      for (var notificationTime in notificationTimes) {
        await NotificationScheduler.scheduleDailyNotifications(
          flutterLocalNotificationsPlugin,
          notificationTime,
        );
      }
    } else {
      print('Notification permission denied');
    }

    return Future.value(true);
  });
}

class HundredDays extends StatelessWidget {
  const HundredDays({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) => MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Colors.blue,
          ),
        ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return HomeScreen();
            } else {
              return const WelcomePage();
            }
          },
        ),
      ),
    );
  }
}
