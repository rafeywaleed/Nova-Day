import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/add_tasks.dart';
import 'package:hundred_days/pages/record_view.dart';
import 'package:hundred_days/pages/settings.dart';
import 'package:hundred_days/utils/dialog_box.dart';
import 'package:iconly/iconly.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workmanager/workmanager.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();

  Future<void> uploadTasksIfOffline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await saveTasksToSharedPreferences();
    } else {
      await saveProgress();
    }
  }
  
  Future<void> saveTasksToSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> defaultTasks = [
      {'task': 'Task 1', 'completed': false},
      {'task': 'Task 2', 'completed': true},
    ];

    List<String> taskList = defaultTasks.map((task) {
      return jsonEncode(task);
    }).toList();

    await prefs.setStringList('defaultTasks', taskList);
  }

  
  

  

  Future<void> saveProgress() async {
    final firestore = FirebaseFirestore.instance;
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      DocumentReference taskRecordDoc = firestore
          .collection('taskRecord')
          .doc(userEmail)
          .collection('records')
          .doc(today);

      List<Map<String, dynamic>> defaultTasks = [
        {'task': 'Task 1', 'completed': false},
        {'task': 'Task 2', 'completed': true},
      ];

      List<Map<String, dynamic>> taskProgress = defaultTasks
          .map((task) => {
                'task': task['task'],
                'status': task['completed'] ? 'completed' : 'incomplete'
              })
          .toList();

      int totalTasks = taskProgress.length;
      int completedTasks =
          taskProgress.where((task) => task['status'] == 'completed').length;
      double overallCompletion =
          totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

      await taskRecordDoc.set({
        'tasks': taskProgress,
        'overallCompletion': '$completedTasks/$totalTasks',
        'date': today,
      });
    }
  }
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> defaultTasks = [];
  List<Map<String, dynamic>> additionalTasks = [];
  String? userEmail;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;

  @override
  void initState() {
    super.initState();
    loadUserEmail();
    loadDailyTasksfromFireBase();
    checkForNewDay();
    startNetworkListener();
    scheduleTaskAtMidnight();
  }

  void checkForNewDay() {
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0);
    Duration timeUntilMidnight = tomorrow.difference(now);

    Future.delayed(timeUntilMidnight, () async {
      await widget.uploadTasksIfOffline();
      checkForNewDay(); // Re-schedule for next day
    });
  }

  void scheduleTaskAtMidnight() {
    Workmanager().registerPeriodicTask(
      'dailyTaskUpload',
      'uploadTasksAtMidnight',
      frequency: Duration(hours: 24),
      initialDelay: Duration(
        hours: 23 - DateTime.now().hour,
        minutes: 59 - DateTime.now().minute,
        seconds: 59 - DateTime.now().second,
      ),
    );
  }

void startNetworkListener() {
  Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    // Check if there is a valid connectivity result
    if (results.isNotEmpty && results.any((result) => result != ConnectivityResult.none)) {
      widget.uploadTasksIfOffline().then((_) {
        print('Tasks uploaded successfully.');
      }).catchError((error) {
        print('Error uploading tasks: $error');
      });
    }
  });
}


  Future<void> loadUserEmail() async {
    User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    }
  }
  

  Future<void> loadDailyTasksfromFireBase() async {
    String? userEmail = auth.currentUser?.email;
    if (userEmail != null) {
      DocumentReference userTasksDoc =
          firestore.collection('dailyTasks').doc(userEmail);
      DocumentSnapshot snapshot = await userTasksDoc.get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        var tasksData = data['tasks'];

        if (tasksData is List) {
          setState(() {
            defaultTasks = tasksData
                .map((task) => {
                      'task': task,
                      'completed': false,
                    })
                .toList();
          });
        }
      }
    }
  }



  // Future<void> loadDailyTasks() async {
  //   String? userEmail = auth.currentUser?.email;
  //   if (userEmail != null) {
  //     DocumentReference userTasksDoc =
  //         firestore.collection('dailyTasks').doc(userEmail);
  //     DocumentSnapshot snapshot = await userTasksDoc.get();

  //     if (snapshot.exists) {
  //       var data = snapshot.data() as Map<String, dynamic>;
  //       var tasksData = data['tasks'];

  //       if (tasksData is List) {
  //         setState(() {
  //           defaultTasks = tasksData
  //               .map((task) => {
  //                     'task': task,
  //                     'completed': false,
  //                   })
  //               .toList();
  //         });
  //       }
  //     }
  //   }
  // }

  Future<void> saveProgress() async {
    String? userId = auth.currentUser?.uid;
    if (userId != null) {
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      DocumentReference taskRecordDoc = firestore
          .collection('taskRecord')
          .doc(userEmail)
          .collection('records')
          .doc(today);

      List<Map<String, dynamic>> taskProgress = defaultTasks
          .map((task) => {
                'task': task['task'],
                'status': task['completed'] ? 'completed' : 'incomplete'
              })
          .toList();

      int totalTasks = taskProgress.length;
      int completedTasks =
          taskProgress.where((task) => task['status'] == 'completed').length;
      double overallCompletion =
          totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

      await taskRecordDoc.set({
        'tasks': taskProgress,
        'overallCompletion': '$completedTasks/$totalTasks',
        'date': today,
      });
    }
  }

  void checkIfNewDay() async {
    String? userId = auth.currentUser?.uid;
    if (userId != null) {
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      DocumentReference taskRecordDoc = firestore
          .collection('taskRecord')
          .doc(userEmail)
          .collection('records')
          .doc(today);

      DocumentSnapshot snapshot = await taskRecordDoc.get();
      if (!snapshot.exists) {
        await saveProgress(); // Save progress if new day
        await loadDailyTasksfromFireBase(); // Load new tasks
      }
    }
  }

  // void checkForNewDay() {
  //   DateTime now = DateTime.now();
  //   DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0);
  //   Duration timeUntilMidnight = tomorrow.difference(now);

  //   Future.delayed(timeUntilMidnight, () async {
  //     await saveProgress();
  //     await loadDailyTasks();
  //     checkForNewDay();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    int totalTasks = defaultTasks.length;
    int completedTasks =
        defaultTasks.where((task) => task['completed'] == true).length;
    double taskCompletion = totalTasks > 0 ? completedTasks / totalTasks : 0;
    int daysLeft = DateTime(2025, 1, 1).difference(DateTime.now()).inDays;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            labelType: labelType,
            useIndicator: false,
            indicatorShape: Border.all(width: 20),
            indicatorColor: Colors.transparent,
            minWidth: 15.w,
            groupAlignment: 0,
            backgroundColor:
                const Color.fromARGB(255, 127, 127, 127).withOpacity(0.1),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) {
              setState(() {
                _selectedIndex = value;
              });
            },
            destinations: [
              NavigationRailDestination(
                icon: _selectedIndex == 0
                    ? Icon(IconlyLight.home, color: Colors.blue, size: 12.w)
                    : Icon(IconlyBroken.home, size: 9.w),
                label: Text(
                  'Home',
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ),
              NavigationRailDestination(
                icon: _selectedIndex == 1
                    ? Icon(IconlyLight.graph, color: Colors.blue, size: 12.w)
                    : Icon(IconlyBroken.graph, size: 9.w),
                label: Text(
                  'Record',
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ),
              NavigationRailDestination(
                icon: _selectedIndex == 2
                    ? Icon(IconlyLight.setting, color: Colors.blue, size: 12.w)
                    : Icon(IconlyBroken.setting, size: 9.w),
                label: Text(
                  'Settings',
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: _buildContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex != 0
          ? null
          : FloatingActionButton(
              onPressed: () {
                final _controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) {
                    return DialogBox(
                      Controller: _controller,
                      onSave: () {
                        if (_controller.text.isNotEmpty) {
                          setState(() {
                            additionalTasks.add(
                                {'task': _controller.text, 'completed': false});
                          });
                          Navigator.of(context).pop();
                        }
                      },
                      onCancel: () {
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
              child: Icon(Icons.add),
            ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return ProgressTracker();
      case 2:
        return UserSettingsPage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    int totalTasks = defaultTasks.length;
    int completedTasks =
        defaultTasks.where((task) => task['completed'] == true).length;
    double taskCompletion = totalTasks > 0 ? completedTasks / totalTasks : 0;
    int daysLeft = DateTime(2025, 1, 1).difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.05),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: FadeInDown(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 1000),
            child: Container(
              height: 15.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    spreadRadius: 1,
                    color: Colors.grey,
                    offset: const Offset(0, 5),
                  ),
                ],
                color: Colors.white,
              ),
              child: Padding(
                padding: EdgeInsets.all(5.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$daysLeft',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 7.w,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'days left for new year',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 3.w,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    CircularPercentIndicator(
                      radius: 10.w,
                      lineWidth: 8.0,
                      percent: taskCompletion,
                      center: Text(
                        "${(taskCompletion * 100).toStringAsFixed(0)}%",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 5.w,
                          color: Colors.blue,
                        ),
                      ),
                      progressColor: Colors.blue,
                      backgroundColor: Colors.grey[300]!,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Daily Tasks:",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 5.w,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: defaultTasks.length,
            itemBuilder: (context, index) {
              return TaskCard(
                task: defaultTasks[index],
                onDismissed: () {
                  setState(() {
                    defaultTasks.removeAt(index);
                  });
                },
                onChanged: (value) {
                  setState(() {
                    defaultTasks[index]['completed'] = value!;
                    saveProgress();
                  });
                },
              );
            },
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          "Additional Tasks:",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 5.w,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: additionalTasks.length,
            itemBuilder: (context, index) {
              return TaskCard(
                task: additionalTasks[index],
                onDismissed: () {
                  setState(() {
                    additionalTasks.removeAt(index);
                  });
                },
                onChanged: (value) {
                  setState(() {
                    additionalTasks[index]['completed'] = value!;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onDismissed;
  final ValueChanged<bool?> onChanged;

  const TaskCard({
    required this.task,
    required this.onDismissed,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task['task']),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) => onDismissed(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: CheckboxListTile(
          title: Text(
            task['task'],
            style: GoogleFonts.plusJakartaSans(
              decoration: task['completed'] == true
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: task['completed'] == true ? Colors.grey : Colors.black,
            ),
          ),
          value: task['completed'] ?? false,
          onChanged: onChanged,
        ),
      ),
    );
  }
}


