import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';
import 'navigation_rail.dart'; // Import the Navigation Rail widget

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? joinDate;
  int selectedIndex = 2; // Set to settings page index

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
      //backgroundColor: Colors.white,
      body: Row(
        children: [
          NavigationRailWidget(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              // Handle navigation
              if (index != 2) {
                Navigator.pop(
                    context); // Close settings if another item is selected
                // You might want to navigate to other screens based on index
                // For example:
                // Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Text('User Settings',
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Santoshi')),
                  _buildSection(
                      'Edit Tasks', 'Modify your daily tasks effortlessly.',
                      () {
                    // Navigate to AddTasks
                  }),
                  _buildSection(
                      'Profile', 'Update your name and password as needed.',
                      () {
                    // Navigate to Profile
                  }),
                  _buildSection('Contact',
                      'Reach out for suggestions or to report issues at a.rafeywaleeda5@gmail.com', () {
                    // Navigate to Contact
                  }),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _logout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child:
                        Text('Log Out', style: TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Joined on: ${joinDate ?? "Loading..."}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 121, 121, 121),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 65, 65, 65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // Logout logic here
  }
}
