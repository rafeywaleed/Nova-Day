import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/auth/firebase_fun.dart';
import 'package:hundred_days/homescreen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/utils/dialog_box.dart';
import 'package:iconly/iconly.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'notification_settings.dart';

class AddTasks extends StatefulWidget {
  final int input;
  const AddTasks({super.key, required this.input});

  @override
  State<AddTasks> createState() => _AddTasksState();
}

class _AddTasksState extends State<AddTasks> {
  final FirebaseService _firebaseService = FirebaseService();
  String userName = "";
  List<String> currentDailyTasks = [];
  bool isTaskListModified = false;
  final _controller = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  // bool notificationsEnabled = true;

  // void toggleNotifications(bool value) async {
  //   setState(() {
  //     notificationsEnabled = value;
  //   });
  //   await NotificationService.enableNotifications(value);

  //   // Save the state to SharedPreferences
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('notificationsEnabled', value);
  // }

  // Future<void> loadNotificationState() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
  //   });
  // }

  Future<void> showInfoBox() async {
    if (widget.input == 0) {
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Remember',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: Colors.black),
            ),
            content: Text(
              'You can modify the task and change notification settings anytime',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp, color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            NotificationSettings(intro: widget.input)),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserName = prefs.getString('userName');

    if (storedUserName != null) {
      setState(() {
        userName = storedUserName;
      });
    } else {
      try {
        final userData = await _firebaseService.fetchUserData();
        setState(() {
          userName = userData['name'];
        });
        await prefs.setString('userName', userName);
      } catch (e) {
        // print('Error fetching user data: ${e.toString()}');
        setState(() {
          userName = 'User';
        });
        // print('Error fetching user data: ${e.toString()}');
      }
    }
  }

  Future<void> saveDailyTasksToPreferences(List<String> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dailyTasks', tasks);
    // print('Tasks saved to SharedPreferences: $tasks');
  }

  Future<void> loadDailyTasksFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load tasks from SharedPreferences
    currentDailyTasks = prefs.getStringList('dailyTasks') ?? [];

    // If no tasks are found in SharedPreferences, load from Firestore
    if (currentDailyTasks.isEmpty) {
      // print('SharedPreferences are empty, fetching from Firebase.');
      await loadDailyTasksFromFirestore();
    } else {
      // print('Tasks loaded from SharedPreferences: $currentDailyTasks');
      setState(() {}); // Update UI with loaded tasks
    }
  }

  Future<void> loadDailyTasksFromFirestore() async {
    try {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentReference userTasksDoc =
            firestore.collection('dailyTasks').doc(userEmail);
        DocumentSnapshot snapshot = await userTasksDoc.get();

        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;
          var tasksData = List<String>.from(data['tasks'] ?? []);

          // Update currentDailyTasks
          setState(() {
            currentDailyTasks = tasksData;
          });

          // Save fetched tasks to SharedPreferences for future use
          await saveDailyTasksToPreferences(tasksData);
          // print('Tasks loaded from Firestore and saved to SharedPreferences: $currentDailyTasks');
        } else {
          // print('No tasks found in Firestore.');
        }
      }
    } catch (e) {
      // print("Error loading tasks from Firestore: $e");
    }
  }

  Future<void> saveDailyTasksToFirestore(List<String> tasks) async {
    try {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentReference userTasksDoc =
            firestore.collection('dailyTasks').doc(userEmail);
        await userTasksDoc.set({'tasks': tasks});
        // print('Current daily tasks saved: $tasks');

        await saveDailyTasksToPreferences(tasks);
      }
    } catch (e) {
      // print("Error saving tasks to Firestore: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadDailyTasksFromPreferences();
    _loadUsername();
    //loadNotificationState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show a dialog to confirm if the user wants to exit the app
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Exit'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: widget.input == 0
            ? AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                elevation: 0,
              )
            : AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'Add Daily Task',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Divider(
                color: Colors.grey,
              ),
              Text(
                'These are daily tasks (e.g., gym, reading, studying) that reset every day.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Daily Tasks:",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(0),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                        side: MaterialStateProperty.all(
                            BorderSide(color: Colors.grey.shade300, width: 2)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return DialogBox(
                              Controller: _controller,
                              isDailyTask: true,
                              onCancel: () {
                                Navigator.of(context).pop();
                              },
                              onSave: () {
                                if (_controller.text.isNotEmpty) {
                                  setState(() {
                                    currentDailyTasks.add(_controller.text);
                                    isTaskListModified = true;
                                  });
                                  _controller.clear();
                                  Navigator.of(context).pop();
                                }
                              },
                            );
                          },
                        );
                      },
                      child: Text(
                        "Add Task",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp, color: Colors.grey),
                      )),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: currentDailyTasks.length,
                  itemBuilder: (context, index) {
                    return FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Dismissible(
                        key: Key(currentDailyTasks[index]),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (direction) {
                          setState(() {
                            currentDailyTasks.removeAt(index);
                            isTaskListModified = true;
                          });
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(IconlyLight.delete,
                              color: Colors.white),
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              currentDailyTasks[index],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: () async {
                    if (isTaskListModified) {
                      saveDailyTasksToFirestore(currentDailyTasks);
                      saveDailyTasksToPreferences(currentDailyTasks);
                    }
                    if (widget.input == 0) {
                      await showInfoBox();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    }
                  },
                  child: Text(
                    'Save',
                  ),
                ),
              ),
              // const SizedBox(height: 16),
              // Text(
              //   'Guide: Tap on + to add tasks, swipe right to delete a task, and click Finish to save your Daily Tasks.',
              //   style: GoogleFonts.plusJakartaSans(
              //     fontSize: 8.sp,
              //     color: Colors.grey,
              //   ),
              // ),
              SizedBox(
                height: 10.h,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
