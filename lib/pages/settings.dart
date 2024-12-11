import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hundred_days/auth/welcome.dart';
import 'package:hundred_days/pages/intro_screens.dart';
import 'package:hundred_days/pages/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_tasks.dart';
import 'set_notification.dart'; // Import Google Fonts

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({Key? key}) : super(key: key);

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? joinDate;

  @override
  void initState() {
    super.initState();
    _fetchJoinDate();
  }

  Future<void> _fetchJoinDate() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        joinDate = (doc.data() as Map<String, dynamic>)['createdAt']
                ?.toDate()
                .toString() ??
            'N/A';
      });
    }
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'a.rafeywaleeda5@gmail.com',
      query: encodeQueryParameters({
        'subject': 'Your Subject Here',
        'body': 'Your message here',
      }),
    );

    // Launch the email client
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch $emailLaunchUri';
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: Padding(
        padding: EdgeInsets.all(4.w), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5.h), // Responsive height
            Text(
              'User Settings',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 25.sp, // Responsive font size
              ),
            ),
            _buildSection(
              'Edit Tasks',
              'Effortlessly modify your daily tasks.',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTasks(input: 1)),
                );
              },
            ),
             _buildSection(
              'Notifications',
              'You can change your notification settings here',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationSettingsPage()),
                );
              },
            ),
            _buildSection(
              'Profile',
              'Update your name and password as necessary.',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            _buildSection(
              'Contact',
              'For requests, reports, and suggestions, click here to contact a.rafeywaleeda5@gmail.com.',
              () {
                _launchEmail();
              },
            ),

            _buildSection(
              'Guide',
              'For user notes and details regarding task lists.',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => IntroScreen(
                            input: 1,
                          )),
                );
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: FadeInRight(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 1.h), // Responsive margin
          padding: EdgeInsets.all(4.w), // Responsive padding
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.sp, // Responsive font size
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 65, 65, 65),
                ),
              ),
              SizedBox(height: 0.5.h), // Responsive height
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp, // Responsive font size
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void logout(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("Shared prefences cleared");

      await FirebaseAuth.instance.signOut();

      // Show a SnackBar or any other form of feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully\n(local data cleared)'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    } catch (e) {
      print("Logout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }
  }
}
