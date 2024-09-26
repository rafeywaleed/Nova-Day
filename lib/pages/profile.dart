import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/auth/firebase_fun.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
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
        print('Error fetching user data: ${e.toString()}');
        setState(() {
          userName = 'No Name';
          userEmail = 'No Email';
          joinDate = 'No Joined Date available';
        });
        print('Error fetching user data: ${e.toString()}');
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
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        print("Changing name to: ${_nameController.text}");
        await _firebaseService.changeName(_nameController.text);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _nameController.text);
        _loadUserData();
        _nameController.clear();
        _showSnackBar('Name changed successfully!', Colors.green);
      } catch (e) {
        print('Error changing name: ${e.toString()}');
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text == _confirmPasswordController.text) {
        setState(() => isLoading = true);
        try {
          print("Changing password");
          await _firebaseService.changePassword(_passwordController.text);
          _showSnackBar('Password changed successfully!', Colors.green);
          _passwordController.clear();
          _confirmPasswordController.clear();
        } catch (e) {
          print('Error changing password: ${e.toString()}');
          _showSnackBar('Error: ${e.toString()}', Colors.red);
        } finally {
          setState(() => isLoading = false);
        }
      } else {
        _showSnackBar('Passwords do not match', Colors.red);
      }
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
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(10.0.sp),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 43, 43, 43),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          userEmail,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        _buildChangeNameSection(),
                        SizedBox(height: 2.h),
                        _buildChangePasswordSection(),
                        SizedBox(height: 10),
                        Positioned(
                          bottom: 1.h,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 1.h), // Responsive padding
                            child: Text(
                              'Joined on: ${joinDate ?? "Loading..."}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 121, 121, 121),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildChangeNameSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey, width: 0.5.w),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10.sp, 20.sp, 10.sp, 20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 400),
              child: Text(
                'You can set a new Name',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 300),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 0.8.h),
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: .3.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 1, color: Color(0xFFD2D2D4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Change Name',
                    hintStyle: GoogleFonts.plusJakartaSans(),
                  ),
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            FadeIn(
              duration: const Duration(milliseconds: 500),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: _changeName,
                  child: const Text('Change Name'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey, width: 0.5.w),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10.sp, 20.sp, 10.sp, 20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Set Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 300),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 0.8.h),
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: .3.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 1, color: Color(0xFFD2D2D4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    hintText: 'Password',
                    hintStyle: GoogleFonts.plusJakartaSans(),
                  ),
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Confirm Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 200),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 0.8.h),
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: .3.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 1, color: Color(0xFFD2D2D4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Confirm Password',
                    hintStyle: GoogleFonts.plusJakartaSans(),
                  ),
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            FadeIn(
              duration: const Duration(milliseconds: 500),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: _changePassword,
                  child: const Text('Change Password'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
