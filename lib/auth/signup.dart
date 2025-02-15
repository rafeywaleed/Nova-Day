import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hundred_days/pages/intro_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String s_name = "";
  String s_email = "";
  String s_password = "";
  String s_Cpassword = "";

  var focusNodeName = FocusNode();
  var focusNodeEmail = FocusNode();
  var focusNodePassword = FocusNode();
  var focusNodeConfirmPassword = FocusNode();

  bool isFocusedName = false;
  bool isFocusedEmail = false;
  bool isFocusedPassword = false;
  bool isFocusedConfirmPassword = false;
  bool showPassword = false; // For toggling password visibility
  bool showConfirmPassword = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    focusNodeName.addListener(() {
      setState(() {
        isFocusedName = focusNodeName.hasFocus;
      });
    });
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
    focusNodeConfirmPassword.addListener(() {
      setState(() {
        isFocusedConfirmPassword = focusNodeConfirmPassword.hasFocus;
      });
    });
  }

  Future<void> _signUpWithEmailAndPassword() async {
    String email = _emailController.text.trim();
    String name = _nameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      _showErrorSnackbar('Please enter your name.');
      return;
    }
    if (email.isEmpty) {
      _showErrorSnackbar('Please enter your email.');
      return;
    }
    if (password.isEmpty) {
      _showErrorSnackbar('Please enter your password.');
      return;
    }
    if (confirmPassword.isEmpty) {
      _showErrorSnackbar('Please confirm your password.');
      return;
    }
    if (password != confirmPassword) {
      _showErrorSnackbar('Passwords do not match.');
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user details in Firestore
      await _firestore
          .collection('userDetails')
          .doc(_auth.currentUser?.uid)
          .set({
        'name': name,
        'email': email,
        'joinedDate': DateTime.now().toString(),
        'isPremium': false,
      });

      // Store user details in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', email);
      await prefs.setString('joinedDate', DateTime.now().toString());

      // Navigate to IntroScreen without delay
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IntroScreen(input: 0),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'The operation is not allowed.';
          break;
        case 'unknown':
          errorMessage = 'An unknown error occurred.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      _showErrorSnackbar(errorMessage);
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.plusJakartaSans(color: Colors.white),
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white),
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5.h),
                  FadeInDown(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 700),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        IconlyBroken.arrow_left,
                        size: 3.6.h, // dynamic icon size
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          delay: const Duration(milliseconds: 500),
                          duration: const Duration(milliseconds: 600),
                          child: Text(
                            'Create an Account',
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
                            'Welcome to our community!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 25.sp, // dynamic font size
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      'Name',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp, // dynamic font size
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 0.8.h),
                      padding:
                          EdgeInsets.symmetric(horizontal: 5.w, vertical: .3.h),
                      decoration: BoxDecoration(
                        color: isFocusedName ? Colors.white : Color(0xFFF1F0F5),
                        border: Border.all(width: 1, color: Color(0xFFD2D2D4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Your Name',
                          hintStyle: GoogleFonts.plusJakartaSans(),
                        ),
                        focusNode: focusNodeName,
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      'Email',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp, // dynamic font size
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 0.8.h),
                      padding:
                          EdgeInsets.symmetric(horizontal: 5.w, vertical: .3.h),
                      decoration: BoxDecoration(
                        color:
                            isFocusedEmail ? Colors.white : Color(0xFFF1F0F5),
                        border: Border.all(width: 1, color: Color(0xFFD2D2D4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
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
                        controller: _emailController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Your Email',
                          hintStyle:
                              GoogleFonts.plusJakartaSans(), // Hint style
                        ),
                        focusNode: focusNodeEmail,
                        style: GoogleFonts.plusJakartaSans(),
                        // Text style
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      'Set Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp, // dynamic font size
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 0.8.h),
                      padding:
                          EdgeInsets.symmetric(horizontal: 5.w, vertical: .3.h),
                      decoration: BoxDecoration(
                        color: isFocusedPassword
                            ? Colors.white
                            : Color(0xFFF1F0F5),
                        border: Border.all(width: 1, color: Color(0xFFD2D2D4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a password';
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
                          hintStyle:
                              GoogleFonts.plusJakartaSans(), // Hint style
                        ),
                        focusNode: focusNodePassword,
                        style: GoogleFonts.plusJakartaSans(), // Text style
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
                          EdgeInsets.symmetric(horizontal: 5.w, vertical: .3.h),
                      decoration: BoxDecoration(
                        color: isFocusedConfirmPassword
                            ? Colors.white
                            : Color(0xFFF1F0F5),
                        border: Border.all(width: 1, color: Color(0xFFD2D2D4)),
                        borderRadius: BorderRadius.circular(12),
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
                            s_Cpassword = value!;
                          });
                        },
                        controller: _confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                showConfirmPassword = !showConfirmPassword;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          hintText: 'Confirm Password',
                          hintStyle: GoogleFonts.plusJakartaSans(),
                        ),
                        focusNode: focusNodeConfirmPassword,
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 3.h,
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _signUpWithEmailAndPassword,
                            child: FadeInUp(
                              delay: const Duration(milliseconds: 0),
                              duration: const Duration(milliseconds: 0),
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              textStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 18.sp, // dynamic font size
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
                  SizedBox(
                    height: 5.h, // dynamic height
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
