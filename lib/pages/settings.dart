import 'package:animate_do/animate_do.dart';
import 'package:hundred_days/cloud/admin_notifiy.dart';
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
import 'notification_settings.dart';
import 'set_notification.dart';

import 'package:in_app_update/in_app_update.dart';

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
    //_fetchJoinDate();
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await InAppUpdate.checkForUpdate();

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      // If an update is available, show the update dialog
      _showUpdateDialog(updateInfo);
    } else {
      // If no update is available, show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No updates available at the moment.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
          ),
          duration: Duration(seconds: 2),
          backgroundColor:
              Colors.blue, // Custom background color for the snackbar
        ),
      );
      print('No update available');
    }
  }

  Future<void> _showUpdateDialog(AppUpdateInfo updateInfo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Update Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A new version of the app is available. Please update to continue using the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Later'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _downloadUpdate(updateInfo);
                    },
                    child: const Text('Update'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadUpdate(AppUpdateInfo updateInfo) async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
      print('Update successful');
    } catch (e) {
      print('Update failed: $e');
    }
  }

  // Future<void> _fetchJoinDate() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     DocumentSnapshot doc = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .get();
  //     setState(() {
  //       joinDate = (doc.data() as Map<String, dynamic>)['createdAt']
  //               ?.toDate()
  //               .toString() ??
  //           'N/A';
  //     });
  //   }
  // }

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
      body: SingleChildScrollView(
        // Allows scrolling
        child: Padding(
          padding: EdgeInsets.all(4.w), // Responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.h), // Responsive height
              Text(
                'User  Settings',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 25.sp, // Responsive font size
                ),
              ),
              // Ensure each section is wrapped properly
              // _buildSection(
              //   'Edit Tasks',
              //   'Easily modify your daily tasks.',
              //   () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => const AddTasks(input: 1)),
              //     );
              //   },
              // ),
              _buildSection(
                'Notifications',
                'Schedule your Reminders',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettings(intro: 1)),
                  );
                },
              ),
              _buildSection(
                'Profile',
                'Update your name and password',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                },
              ),
              _buildSection(
                'Contact',
                'For requests, reports, or suggestions, feel free to contact me via email.',
                () {
                  _launchEmail();
                },
              ),
              _buildSection(
                'Guide',
                'View notes and instructions related to task lists.',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const IntroScreen(
                              input: 1,
                            )),
                  );
                },
              ),
              const SizedBox(height: 20), // Add spacing before buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // Use Expanded to take available space
                    child: ElevatedButton(
                      onPressed: () => logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                      ),
                      child: Text(
                        'Log Out',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10), // Add spacing between buttons
                  Expanded(
                    // Use Expanded to take available space
                    child: ElevatedButton(
                      onPressed: _checkForUpdate,
                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                      ),
                      child: Text(
                        'Update',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
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
      print("Shared preferences cleared");

      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logged out successfully (local data cleared)'),
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
