import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hundred_days/add_tasks.dart';
import 'package:sizer/sizer.dart';
import 'package:hundred_days/auth/signup.dart';
import 'package:iconly/iconly.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      // Handle successful login
      _showFloatingSnackbar('Successfully logged in!');
      // Navigate to the home screen after a delay
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
          style: TextStyle(
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
      content: Text(message),
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
          content: Text('Password reset link sent to your email'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
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
          style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                height: 100.h,
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
                      delay: const Duration(milliseconds: 800),
                      duration: const Duration(milliseconds: 900),
                      child: const Text(
                        'Let\'s Sign You In',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    FadeInDown(
                      delay: const Duration(milliseconds: 700),
                      duration: const Duration(milliseconds: 800),
                      child: const Text(
                        'Welcome Back.',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    FadeInDown(
                      delay: const Duration(milliseconds: 700),
                      duration: const Duration(milliseconds: 800),
                      child: const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FadeInDown(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 700),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 0.8.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: isFocusedEmail
                              ? Colors.white
                              : const Color(0xFFF1F0F5),
                          border: Border.all(
                              width: 1, color: const Color(0xFFD2D2D4)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (isFocusedEmail)
                              BoxShadow(
                                color: const Color(0xFF835DF1).withOpacity(0.3),
                                blurRadius: 4.0,
                                spreadRadius: 2.0,
                              ),
                          ],
                        ),
                        child: TextField(
                          controller: _emailController,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Your Email',
                          ),
                          focusNode: focusNodeEmail,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    FadeInDown(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 600),
                      child: const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FadeInDown(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 0.8.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: isFocusedPassword
                              ? Colors.white
                              : const Color(0xFFF1F0F5),
                          border: Border.all(
                              width: 1, color: const Color(0xFFD2D2D4)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (isFocusedPassword)
                              BoxShadow(
                                color: const Color(0xFF835DF1).withOpacity(0.3),
                                blurRadius: 4.0,
                                spreadRadius: 2.0,
                              ),
                          ],
                        ),
                        child: TextField(
                          controller: _passwordController,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                                size: 16.sp,
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            hintText: 'Password',
                          ),
                          focusNode: focusNodePassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 700),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loginWithEmailAndPassword,
                              child: const Text('Sign In',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Satoshi',
                                ),
                                backgroundColor: const Color(0xFF835DF1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      duration: const Duration(milliseconds: 900),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account?',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
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
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: Color(0xFF835DF1),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    FadeInUp(
                      delay: const Duration(milliseconds: 900),
                      duration: const Duration(milliseconds: 1000),
                      child: Center(
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF835DF1),
                              fontSize: 15,
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
          ),
        ],
      ),
    );
  }
}
