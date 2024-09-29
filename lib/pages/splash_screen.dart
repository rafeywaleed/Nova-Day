import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/auth/welcome.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hundred_days/pages/notification.dart';
import 'package:hundred_days/pages/notification_services.dart';
import 'package:sizer/sizer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // NotificationService.sendTestNotification(); // Send a test notification
    NotificationService.scheduleNotifications(); // Schedule daily notifications

    //   NotificationService.requestNotificationPermission();

    //   // Initialize Notification Service and schedule notifications
    //   // NotificationService.scheduleNotifications();
    //  NotificationService.requestNotificationPermission().then((_) {
    //   NotificationService.initialize().then((_) {
    //     NotificationService.sendTestNotification();
    //     NotificationService.scheduleNotifications();
    //     NotificationService.schedulePeriodicNotification();
    //   });
    // });

    _timer = Timer(Duration(milliseconds: 3500), () {
      _auth.authStateChanges().listen((User? user) {
        print("Checking auth state...");

        if (user != null) {
          print("Navigating to HomeScreen from Splash Screen");
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
        } else {
          print("Navigating to Welcome page from Splash Screen");
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => WelcomePage()));
        }
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 100.h,
        width: 100.w,
        child: Center(
          // child:
          // FadeIn(
          //   duration: Duration(seconds: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Roulette(
                // delay: Duration(milliseconds: 3000),
                duration: Duration(milliseconds: 3500),
                infinite: true,
                child: Image.asset(
                  'assets/images/app_icon.png',
                  scale: 1.w,
                ),
              ),
              SizedBox(height: 5.h), // Adjusted height for better spacing
              Flash(
                child: Text(
                  'Hundred Days',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.blue,
                    fontSize: 25.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 2.h), // Added a little more spacing
              Flash(
                infinite: true,
                // duration: Duration(milliseconds: 100),
                child: Text(
                  'Loading...',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.blueGrey,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ),
      ),
    );
  }
}
