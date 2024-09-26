import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/auth/firebase_fun.dart';
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
  bool isLoading = false; // Loading state

  final FirebaseService _firebaseService = FirebaseService(); // Instantiate FirebaseService
  String userName = ""; // To hold username from SharedPreferences
  String userEmail = ""; // To hold user email from SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }


  Future<void> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Attempt to fetch user data from SharedPreferences
  String? storedUserName = prefs.getString('userName');
  String? storedUserEmail = prefs.getString('userEmail');
  
  if (storedUserName != null && storedUserEmail != null) {
    setState(() {
      userName = storedUserName;
      userEmail = storedUserEmail;
    });
  } else {
    // If not available, fetch from Firebase
    try {
      final userData = await _firebaseService.fetchUserData(); // Fetch data from Firebase
      setState(() {
        userName = userData['name']; 
        userEmail = userData['email'];
      });
      
      // Store the fetched data in SharedPreferences
      await prefs.setString('userName', userName);
      await prefs.setString('userEmail', userEmail);
    } catch (e) {
      // Handle errors here (e.g., show a message to the user)
      setState(() {
        userName = 'No Name';
        userEmail = 'No Email';
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
      setState(() {
        isLoading = true; // Start loading
      });

      try {
        await _firebaseService.changeName(_nameController.text);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _nameController.text);
        _loadUserData(); // Reload user data

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Name changed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      } finally {
        setState(() {
          isLoading = false; // End loading
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text == _confirmPasswordController.text) {
        setState(() {
          isLoading = true; // Start loading
        });

        try {
          await _firebaseService.changePassword(_passwordController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          );
        } finally {
          setState(() {
            isLoading = false; // End loading
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passwords do not match'),
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
                            color: const Color.fromARGB(255, 43, 43, 43)
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
                        Container(
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
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5.w, vertical: .3.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          width: 1, color: Color(0xFFD2D2D4)),
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
                        ),
                        SizedBox(height: 2.h),
                        Container(
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
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5.w, vertical: .3.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          width: 1, color: Color(0xFFD2D2D4)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: _passwordController,
                                      obscureText: !showPassword,
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            showPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
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
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5.w, vertical: .3.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          width: 1, color: Color(0xFFD2D2D4)),
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
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
