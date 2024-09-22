import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hundred_days/auth/login.dart';
import 'package:hundred_days/auth/welcome.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:sizer/sizer.dart';
import 'firebase_options.dart'; // Generated Firebase options file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Hive with encryption
  final encryptionKey = Hive.generateSecureKey(); // Generate a secure key
  await Hive.initFlutter();
  await Hive.openBox('userBox', encryptionCipher: HiveAesCipher(encryptionKey));

  runApp(const HundredDays());
}

class HundredDays extends StatelessWidget {
  const HundredDays({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) => MaterialApp(
        theme: ThemeData(fontFamily: 'Manrope'),
        home: const WelcomePage(), // Adjust the home page as needed
      ),
    );
  }
}
