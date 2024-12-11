import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/homescreen.dart';
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
              // Background image with opacity
              Container(
                height: 100.h,
                width: 100.w,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/pc.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.5), // Adjust opacity here
                ),
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
                bottom: 8.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30), // Rounded corners
                            ),
                            elevation: 5, // Add shadow
                          ),
                          child: Text(
                            'Previous',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                              if (widget.input == 0) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AddTasks(input: 0,)),
                                );
                              } else {
                                Navigator.pop(context); // Pop back
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30), // Rounded corners
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            _selectedPage == 0 ? 'Next' : 'Done',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              widget.input == 0
                  ? Positioned(
                      bottom: 1.h,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                        child: Text(
                          'Note: you can refer this points again \nas guide in settings screen',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : Text("")
            ],
          ),
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

          // Description
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
                  // Title
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
                      'Note: The list you finish with will be your daily renewing tasks. Deleting daily tasks from the home screen will remove that task for the day only and will not affect your daily tasks, which will be renewed. Logging out may result in the loss of progress for that day.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
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

          // Description
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
                  // Title
                  FadeIn(
                    duration: const Duration(milliseconds: 1500),
                    child: Text(
                      'Additional Tasks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Note: These daily tasks will be renewed every day, and your progress will be recorded for daily tasks. Your additional tasks are simply your to-do tasks for the day and will not be tracked for progress. You can add additional tasks by tapping the [+] button on the home screen and delete additional tasks by swiping them to the right.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      color: Colors.grey,
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
