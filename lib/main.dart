import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hundred_days/services/notification.dart';
import 'package:hundred_days/pages/splash_screen.dart';
import 'package:sizer/sizer.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await FirebaseApi().initNotification();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
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
