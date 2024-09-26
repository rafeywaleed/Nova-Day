import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hundred_days/auth/login.dart';
import 'package:hundred_days/auth/welcome.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:sizer/sizer.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart'; // Generated Firebase options file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Hive with encryption
  final encryptionKey = Hive.generateSecureKey(); // Generate a secure key
  await Hive.initFlutter();
  await Hive.openBox('userBox', encryptionCipher: HiveAesCipher(encryptionKey));
  // Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(const HundredDays());
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
            secondary: Colors.blue, // Use secondary instead of accentColor
          ),
        ),
        // theme: ThemeData(fontFamily: 'Manrope'),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return HomeScreen();
              //BoxEx();
            } else {
              return const WelcomePage();
            }
          },
        ), // Adjust the home page as needed
      ),
    );
  }
}
