import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/auth/login.dart';
import 'package:hundred_days/auth/welcome.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is logged in, navigate to HomeScreen
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        // User is not logged in, navigate to WelcomePage
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => WelcomePage()));
      }
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
      body: Center(
        child: FadeIn(
          duration: Duration(seconds: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Roulette(
                // delay: Duration(milliseconds: 3000),
                duration: Duration(milliseconds: 3000),
                infinite: true,
                child: Image.asset(
                  'assets/images/app _icon.png',
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
      ),
    );
  }
}
