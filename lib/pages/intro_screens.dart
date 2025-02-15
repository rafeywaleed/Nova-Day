import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'add_tasks.dart';

class IntroScreen extends StatefulWidget {
  final int input;
  const IntroScreen({super.key, required this.input});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPage = 0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward(); // Start animation when the screen opens
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1), // Start from bottom
          end: Offset.zero, // Move to original position
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        )),
        child: SizedBox(
          height: 100.h,
          width: 100.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildBackgroundImage(),
              _buildPageContent(),
              _buildNavigationButtons(),
              widget.input == 0 ? _buildNoteText() : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  // Background image with a slight dark overlay for better text readability
  Widget _buildBackgroundImage() {
    return Container(
      height: 100.h,
      width: 100.w,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/pc.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5), // Adjust opacity
      ),
    );
  }

  // Page content switching with fade transition
  Widget _buildPageContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _selectedPage == 0 ? const IntroPage1() : const IntroPage2(),
    );
  }

  // Navigation buttons (Previous, Next / Done)
  Widget _buildNavigationButtons() {
    return Positioned(
      bottom: 8.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_selectedPage != 0)
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPage = 0;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedPage == 0) {
                    setState(() {
                      _selectedPage = 1;
                    });
                  } else {
                    _navigateNextPage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: Text(
                  _selectedPage == 0 ? 'Next' : 'Done',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Small note at the bottom of the screen
  Widget _buildNoteText() {
    return Positioned(
      bottom: 1.h,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
        child: Text(
          'Note: You can refer to these points again as a guide in the settings screen.',
          textAlign: TextAlign.center,
          style:
              GoogleFonts.plusJakartaSans(fontSize: 10.sp, color: Colors.grey),
        ),
      ),
    );
  }

  // Navigate to the next page
  void _navigateNextPage() {
    if (widget.input == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddTasks(input: 0)),
      );
    } else {
      Navigator.pop(context); // Pop back
    }
  }
}

// Intro page with information about Daily Tasks
class IntroPage1 extends StatelessWidget {
  const IntroPage1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeIn(
            duration: const Duration(milliseconds: 2000),
            child: Container(
              width: 80.w,
              padding: const EdgeInsets.fromLTRB(15, 25, 15, 25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  FadeIn(
                    duration: const Duration(milliseconds: 1000),
                    child: Icon(
                      Icons.checklist,
                      size: 80.sp,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  FadeIn(
                    duration: const Duration(milliseconds: 1500),
                    child: Text(
                      'Daily Tasks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Daily tasks are the ones you do every day, like gym, reading, or studying. Your daily task list resets every day and tracks your growth.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp, color: Colors.grey),
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
}

// Intro page with information about Additional Tasks
class IntroPage2 extends StatelessWidget {
  const IntroPage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeIn(
            duration: const Duration(milliseconds: 2000),
            child: Container(
              width: 80.w,
              padding: const EdgeInsets.fromLTRB(15, 25, 15, 25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  FadeIn(
                    duration: const Duration(milliseconds: 1000),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 80.sp,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  FadeIn(
                    duration: const Duration(milliseconds: 1500),
                    child: Text(
                      'To-Do List',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'To-Do tasks are occasional tasks with brief description, like completing assignments or doing laundry. These tasks aren’t tracked for growth but need to be completed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
