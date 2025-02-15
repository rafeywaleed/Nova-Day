import 'package:animate_do/animate_do.dart';
import 'package:hundred_days/cloud/admin_notifiy.dart';
import 'package:iconly/iconly.dart';
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
        'subject': 'Report Bug | Suggestions',
        'body':
            'Hi, \n\nI would like to report a bug or suggest a feature for the app(Nova Day). Here are the details: \n',
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
      bottomNavigationBar: SizedBox(
        height: 10.h,
      ),
      key: scaffoldKey,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w), // Responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.h), // Responsive spacing
              Text(
                'User Settings',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp, // Responsive font size
                ),
              ),
              SizedBox(height: 3.h), // Spacing after the title
              _buildSection(
                'Notifications',
                'Schedule your reminders.',
                Icons.notifications,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationSettings(intro: 1),
                    ),
                  );
                },
              ),
              _buildSection(
                'Profile',
                'Update your name and password.',
                IconlyBold.profile,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
              ),
              _buildSection(
                'Contact',
                'For requests, reports, or suggestions, feel free to contact me via email.',
                IconlyBold.message,
                () {
                  _launchEmail();
                },
              ),
              _buildSection(
                'Guide',
                'View notes and instructions related to task lists.',
                IconlyBold.discovery,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IntroScreen(input: 1),
                    ),
                  );
                },
              ),
              SizedBox(height: 3.5.h), // Spacing before the logout button
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => logout(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 1, // Flat design
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Logout  ',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.red,
                          // fontWeight: FontWeight.bold,
                          fontSize: 13.sp, // Responsive font size
                        ),
                      ),
                      Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 17.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: FadeInRight(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 1.h), // Responsive margin
          padding: EdgeInsets.all(4.w), // Responsive padding
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.blue,
                size: 20.sp,
              ),
              SizedBox(width: 4.w), // Spacing between icon and text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                        height: 0.5.h), // Spacing between title and subtitle
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 15.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void logout(BuildContext context) async {
    // Show an Android-style confirmation dialog before logging out
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Log Out"),
          content: Text("Are you sure you want to log out?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Log Out"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                try {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();
                  print("Shared preferences cleared");

                  await FirebaseAuth.instance.signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Logged out successfully (local data cleared)'),
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
                    MaterialPageRoute(
                        builder: (context) => const WelcomePage()),
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
              },
            ),
          ],
        );
      },
    );
  }
}
