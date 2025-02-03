import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hundred_days/auth/login.dart';
import 'package:hundred_days/auth/welcome.dart';
import 'package:hundred_days/cloud/firebase_api.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:hundred_days/pages/notification.dart';
import 'package:hundred_days/pages/notification_helper.dart';
import 'package:hundred_days/pages/notification_services.dart';
import 'package:hundred_days/pages/set_notification.dart';
import 'package:hundred_days/pages/splash_screen.dart';
import 'package:hundred_days/pages/work_manager_service.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await FirebaseApi().initNotification();
  await Firebase.initializeApp();

  tz.initializeTimeZones();
  await NotificationService.initialize();

  runApp(const HundredDays());
  //runApp(NotificationSettingsPage());
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
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
