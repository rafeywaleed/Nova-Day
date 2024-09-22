import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hundred_days/add_tasks.dart';
import 'package:hundred_days/auth/firebase_fun.dart';
import 'package:hundred_days/auth/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseService _firebaseService = FirebaseService();
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('User Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Edit Tasks', 'Modify your daily tasks effortlessly.',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTasks(input: 1),
                ),
              );
            }),
            _buildSection('Profile', 'Update your name and password as needed.',
                () {
              Navigator.of(context).pushNamed('/profile');
            }),
            _buildSection(
                'Contact', 'Reach out for suggestions or to report issues.',
                () {
              Navigator.of(context).pushNamed('/contact');
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Log Out',
                style: TextStyle(color: Colors.white),
              ),
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
    );
  }

  Widget _buildSection(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        width: double.infinity, // Ensure full width
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
    try {
      await _firebaseService.signOut();
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } catch (e) {
      // Handle sign-out errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }
}
