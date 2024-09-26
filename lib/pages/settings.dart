import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hundred_days/add_tasks.dart';
import 'package:hundred_days/auth/welcome.dart';
import 'package:hundred_days/pages/intro_screens.dart';
import 'package:hundred_days/pages/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

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
              'Modify your daily tasks effortlessly.',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTasks(input: 1)),
                );
              },
            ),
            _buildSection(
              'Profile',
              'Update your name and password as needed.',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            _buildSection(
              'Contact',
              'Reach out for suggestions or to report issues at a.rafeywaleeda5@gmail.com',
              () {
                // Navigate to Contact
              },
            ),
            _buildSection(
              'Guide',
              '',
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
                padding: EdgeInsets.symmetric(
                    horizontal: 8.w, vertical: 2.h), // Responsive padding
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(vertical: 1.h), // Responsive padding
              child: Text(
                'Joined on: ${joinDate ?? "Loading..."}',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 121, 121, 121),
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

  
      await FirebaseAuth.instance.signOut();

      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    } catch (e) {
      print("Logout error: $e");
    }
  }
}
