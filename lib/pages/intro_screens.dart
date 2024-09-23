import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class IntroScreen extends StatefulWidget {
  final int input;
  const IntroScreen({super.key, required this.input});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int _selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: 100.h,
        width: 100.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background image
            Image.asset(
              'assets/images/pc.png',
              fit: BoxFit.cover,
              height: 100.h,
              width: 100.w,
            ),
            // Intro screen content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _selectedPage == 0 ? IntroPage1() : IntroPage2(),
            ),
            // Buttons at the bottom
            Positioned(
              bottom: 10.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_selectedPage != 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPage = 0;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                  // Next or Done button
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedPage == 0) {
                        setState(() {
                          _selectedPage = 1;
                        });
                      } else {
                        // Navigate to AddTask page
                        Navigator.pushNamed(context, '/addTask');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    child: _selectedPage == 0
                        ? const Text('Next')
                        : const Text('Done'),
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

class IntroPage1 extends StatelessWidget {
  const IntroPage1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or Icon
          FadeIn(
            duration: const Duration(milliseconds: 1000),
            child: Icon(
              Icons.checklist,
              size: 80.sp,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 4.h),
          // Title
          FadeIn(
            duration: const Duration(milliseconds: 1500),
            child: Text(
              'Daily Tasks',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Description
          FadeIn(
            duration: const Duration(milliseconds: 2000),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Text(
                'Note: The list you finish with will be your daily renewing tasks. Deleting daily tasks from the home screen will remove that task for the day only and will not affect your daily tasks, which will be renewed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntroPage2 extends StatelessWidget {
  const IntroPage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or Icon
          FadeIn(
            duration: const Duration(milliseconds: 1000),
            child: Icon(
              Icons.add_circle_outline,
              size: 80.sp,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 4.h),
          // Title
          FadeIn(
            duration: const Duration(milliseconds: 1500),
            child: Text(
              'Additional Tasks',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Description
          FadeIn(
            duration: const Duration(milliseconds: 2000),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Text(
                'Note: These daily tasks will be renewed every day, and your progress will be recorded for daily tasks. Your additional tasks are simply your to-do tasks for the day and will not be tracked for progress. You can add additional tasks by tapping the [+] button on the home screen and delete additional tasks by swiping them to the right.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
