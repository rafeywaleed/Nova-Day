import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';
import 'package:hundred_days/auth/signup.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/add_tasks.dart'; // Import Google Fonts

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String s_password = "";
  String s_email = "";
  var focusNodeEmail = FocusNode();
  var focusNodePassword = FocusNode();
  bool isFocusedEmail = false;
  bool isFocusedPassword = false;
  bool showPassword = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    focusNodeEmail.addListener(() {
      setState(() {
        isFocusedEmail = focusNodeEmail.hasFocus;
      });
    });
    focusNodePassword.addListener(() {
      setState(() {
        isFocusedPassword = focusNodePassword.hasFocus;
      });
    });
  }

  Future<void> _loginWithEmailAndPassword() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _showFloatingSnackbar('Successfully logged in!');
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddTasks(
              input: 0,
            ),
          ),
        );
      });
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Wrong password provided.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          default:
            errorMessage = 'Login failed: ${e.message}';
        }
      } else {
        errorMessage = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          errorMessage,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ));
    }
  }

  void _showFloatingSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.plusJakartaSans(),
      ),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isNotEmpty) {
      try {
        await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password reset link sent to your email',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Please enter your email.',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          // height: 100.h,
          decoration: const BoxDecoration(color: Colors.white),
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.h),
              FadeInDown(
                delay: const Duration(milliseconds: 900),
                duration: const Duration(milliseconds: 1000),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    IconlyBroken.arrow_left,
                    size: 3.6.h,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              FadeInDown(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'Let\'s Sign You In',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 25.sp, // dynamic font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              FadeInDown(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Welcome Back.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 25.sp, // dynamic font size
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              FadeInDown(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp, // dynamic font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 400),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 0.8.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color:
                        isFocusedEmail ? Colors.white : const Color(0xFFF1F0F5),
                    border:
                        Border.all(width: 1, color: const Color(0xFFD2D2D4)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (isFocusedEmail)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4.0,
                          spreadRadius: 2.0,
                        ),
                    ],
                  ),
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please Enter your Email';
                      } else {
                        return null;
                      }
                    },
                    onSaved: (value) {
                      setState(() {
                        s_email = value!;
                      });
                    },
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Your Email',
                      hintStyle: GoogleFonts.plusJakartaSans(),
                    ),
                    focusNode: focusNodeEmail,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Password',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp, // dynamic font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 200),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 0.8.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: isFocusedPassword
                        ? Colors.white
                        : const Color(0xFFF1F0F5),
                    border:
                        Border.all(width: 1, color: const Color(0xFFD2D2D4)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (isFocusedPassword)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4.0,
                          spreadRadius: 2.0,
                        ),
                    ],
                  ),
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please Enter your Password';
                      } else {
                        return null;
                      }
                    },
                    onSaved: (value) {
                      setState(() {
                        s_password = value!;
                      });
                    },
                    controller: _passwordController,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500),
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey,
                          size: 16.sp, // dynamic icon size
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
                    focusNode: focusNodePassword,
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 400),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loginWithEmailAndPassword,
                        child: const Text('Sign In',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Register',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.blue,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 700),
                child: Center(
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.blue,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
