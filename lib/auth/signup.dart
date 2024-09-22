import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hundred_days/add_tasks.dart';
import 'package:sizer/sizer.dart';
import 'package:iconly/iconly.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    if (password != confirmPassword) {
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
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
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
                decoration: BoxDecoration(color: Colors.white),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5.h ),
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
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInDown(
                            delay: const Duration(milliseconds: 800),
                            duration: const Duration(milliseconds: 900),
                            child: Text(
                              'Create an Account',
                              style: TextStyle(
                                fontSize: 25.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          FadeInDown(
                            delay: const Duration(milliseconds: 700),
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              'Welcome to our community!',
                              style: TextStyle(
                                fontSize: 25.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5.h),
                    FadeInDown(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 700),
                      child: Text(
                        'Name',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    FadeInDown(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 0.8.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: .3.h),
                        decoration: BoxDecoration(
                          color:
                              isFocusedName ? Colors.white : Color(0xFFF1F0F5),
                          border:
                              Border.all(width: 1, color: Color(0xFFD2D2D4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Your Name',
                          ),
                          focusNode: focusNodeName,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    FadeInDown(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 700),
                      child: Text(
                        'Email',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    FadeInDown(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 0.8.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: .3.h),
                        decoration: BoxDecoration(
                          color:
                              isFocusedEmail ? Colors.white : Color(0xFFF1F0F5),
                          border:
                              Border.all(width: 1, color: Color(0xFFD2D2D4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Your Email',
                          ),
                          focusNode: focusNodeEmail,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    FadeInDown(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        'Set Password',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    FadeInDown(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 0.8.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: .3.h),
                        decoration: BoxDecoration(
                          color: isFocusedPassword
                              ? Colors.white
                              : Color(0xFFF1F0F5),
                          border:
                              Border.all(width: 1, color: Color(0xFFD2D2D4)),
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
                          ),
                          focusNode: focusNodePassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        'Confirm Password',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
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
                          color: isFocusedConfirmPassword
                              ? Colors.white
                              : Color(0xFFF1F0F5),
                          border:
                              Border.all(width: 1, color: Color(0xFFD2D2D4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
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
                          ),
                          focusNode: focusNodeConfirmPassword,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: SizedBox(
                        height: 10,
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 700),
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
                                    style: TextStyle(color: Colors.white),
                                  )),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Satoshi',
                                ),
                                backgroundColor: Color(0xFF835DF1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}