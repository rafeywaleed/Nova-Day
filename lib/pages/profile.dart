import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/auth/firebase_fun.dart';
import 'package:hundred_days/utils/loader.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool showPassword = false;
  bool isLoading = false;

  final FirebaseService _firebaseService = FirebaseService();
  String userName = "";
  String userEmail = "";
  String? joinDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserName = prefs.getString('userName');
    String? storedUserEmail = prefs.getString('userEmail');
    String? storedJoinDate = prefs.getString('joinDate');

    if (storedUserName != null && storedUserEmail != null) {
      setState(() {
        userName = storedUserName;
        userEmail = storedUserEmail;
        joinDate = storedJoinDate;
      });
    } else {
      try {
        final userData = await _firebaseService.fetchUserData();
        setState(() {
          userName = userData['name'];
          userEmail = userData['email'];
          DateTime parsedDate = DateTime.parse(userData['joinedDate']);
          joinDate = DateFormat('dd-MM-yyyy').format(parsedDate);
        });
        await prefs.setString('userName', userName);
        await prefs.setString('userEmail', userEmail);
        await prefs.setString('joinDate', joinDate ?? '');
      } catch (e) {
        //print('Error fetching user data: ${e.toString()}');
        setState(() {
          userName = 'No Name';
          userEmail = 'No Email';
          joinDate = 'No Joined Date available';
        });
        //print('Error fetching user data: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changeName() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Name cannot be empty', Colors.red);
      return;
    }

    setState(() => isLoading = true);
    try {
      //print("Changing name to: ${_nameController.text}");
      await _firebaseService.changeName(_nameController.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text);
      _loadUserData();
      _nameController.clear();
      _showSnackBar('Name changed successfully!', Colors.green);
    } catch (e) {
      //print('Error changing name: ${e.toString()}');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Password fields cannot be empty', Colors.red);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match', Colors.red);
      return;
    }

    if (_passwordController.text == _confirmPasswordController.text) {
      setState(() => isLoading = true);
      try {
        //print("Changing password");
        await _firebaseService.changePassword(_passwordController.text);
        _showSnackBar('Password changed successfully!', Colors.green);
        _passwordController.clear();
        _confirmPasswordController.clear();
      } catch (e) {
        //print('Error changing password: ${e.toString()}');
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      } finally {
        setState(() => isLoading = false);
      }
    } else {
      _showSnackBar('Passwords do not match', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Settings',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black), // Back button color
      ),
      body: isLoading
          ? Center(child: PLoader())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0.sp),
                child: Column(
                  children: [
                    // User Info Section
                    Text(
                      userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      userEmail,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // Change Name Section
                    _buildSection(
                      title: 'Change Name',
                      description: 'You can set a new name.',
                      controller: _nameController,
                      hintText: 'Enter new name',
                      buttonText: 'Update Name',
                      buttonColor: Colors.blue,
                      onPressed: _changeName,
                    ),
                    SizedBox(height: 3.h),

                    // Change Password Section
                    _buildSection(
                      title: 'Change Password',
                      description: 'Set a new password.',
                      controller: _passwordController,
                      hintText: 'Enter new password',
                      isPassword: true,
                      showPassword: showPassword,
                      onTogglePassword: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                      confirmController: _confirmPasswordController,
                      confirmHintText: 'Confirm new password',
                      buttonText: 'Update Password',
                      buttonColor: Colors.red,
                      onPressed: _changePassword,
                    ),
                    SizedBox(height: 3.h),

                    // Joined Date Section
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      child: Text(
                        'Joined on: ${joinDate ?? "Loading..."}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

// Reusable Section Widget
  Widget _buildSection({
    required String title,
    required String description,
    required TextEditingController controller,
    required String hintText,
    String? buttonText,
    Color? buttonColor,
    VoidCallback? onPressed,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    TextEditingController? confirmController,
    String? confirmHintText,
  }) {
    return Container(
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
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 1.5.h),
          // Input Field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.sp),
            child: TextField(
              controller: controller,
              obscureText: isPassword && !showPassword,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: onTogglePassword,
                      )
                    : null,
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),
          ),
          if (confirmController != null) ...[
            SizedBox(height: 1.5.h),
            // Confirm Password Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.sp),
              child: TextField(
                controller: confirmController,
                obscureText: isPassword && !showPassword,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: confirmHintText,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  color: Colors.black,
                ),
              ),
            ),
          ],
          if (buttonText != null) ...[
            SizedBox(height: 2.h),
            Center(
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(120, 40),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
