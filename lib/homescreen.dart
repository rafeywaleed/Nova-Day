import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/add_tasks.dart';
import 'package:hundred_days/pages/settings.dart';
import 'package:hundred_days/utils/dialog_box.dart';
import 'package:iconly/iconly.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> dailyTasks = [];
  List<Map<String, dynamic>> additionalTasks = [];
  String? userEmail;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  int selectedIndex = 0; // Track selected index for NavigationRail

  @override
  void initState() {
    selectedIndex = 0;
    super.initState();
    loadUserEmail();
    loadDailyTasks();
    checkForNewDay();
  }

  Future<void> loadUserEmail() async {
    User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    }
  }

  Future<void> loadDailyTasks() async {
    String? userEmail = auth.currentUser?.email;
    if (userEmail != null) {
      DocumentReference userTasksDoc =
          firestore.collection('dailyTasks').doc(userEmail);
      DocumentSnapshot snapshot = await userTasksDoc.get();

      if (snapshot.exists) {
        print("Snapshot data: ${snapshot.data()}");
        var data = snapshot.data() as Map<String, dynamic>;
        var tasksData = data['tasks'];

        if (tasksData is List) {
          setState(() {
            dailyTasks = tasksData
                .map((task) => {
                      'task': task['task'],
                      'completed':
                          task['status'] == 'completed', // Update this line
                    })
                .toList();
          });
        } else {
          print("Tasks field is not a List");
        }
      } else {
        print("No document found for user $userEmail");
      }
    } else {
      print("No user email found");
    }
  }

  Future<void> saveProgress() async {
    String? userId = auth.currentUser?.uid;
    if (userId != null) {
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      DocumentReference taskRecordDoc = firestore
          .collection('taskRecord')
          .doc(userEmail)
          .collection('records')
          .doc(today);

      List<Map<String, dynamic>> taskProgress = dailyTasks
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

      print('Progress saved for $today');
    }
  }

  void checkForNewDay() {
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0);
    Duration timeUntilMidnight = tomorrow.difference(now);

    Future.delayed(timeUntilMidnight, () async {
      await saveProgress();
      await loadDailyTasks();
      checkForNewDay();
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalTasks = dailyTasks.length;
    int completedTasks =
        dailyTasks.where((task) => task['completed'] == true).length;
    double taskCompletion = totalTasks > 0 ? completedTasks / totalTasks : 0;
    int daysLeft = DateTime(2025, 1, 1).difference(DateTime.now()).inDays;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              NavigationRail(
                useIndicator: false,
                indicatorShape: Border.all(width: 20),
                indicatorColor: Colors.transparent,
                //  minWidth: MediaQuery.of(context).size.width * 0.15,
                minWidth: 15.w,
                groupAlignment: 0,
                backgroundColor:
                    const Color.fromARGB(255, 127, 127, 127).withOpacity(0.1),
                selectedIndex: selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    selectedIndex =
                        index; // Update selectedIndex based on user selection
                  });
                  // Navigate based on the selected index
                  if (index == 2) {
                    // If settings is selected
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserSettingsPage(),
                      ),
                    ).then((_) {
                      // After returning from settings, set selectedIndex back to home (0)
                      setState(() {
                        selectedIndex = 0;
                      });
                    });
                  }
                },
                destinations: [
                  NavigationRailDestination(
                    icon: selectedIndex == 0
                        ? Icon(IconlyLight.home, color: Colors.blue, size: 12.w)
                        : Icon(IconlyBroken.home, size: 9.w),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: selectedIndex == 1
                        ? Icon(IconlyLight.graph,
                            color: Colors.blue, size: 12.w)
                        : Icon(IconlyBroken.graph, size: 9.w),
                    label: Text('Record'),
                  ),
                  NavigationRailDestination(
                    icon: selectedIndex == 2
                        ? Icon(IconlyLight.setting,
                            color: Colors.blue, size: 12.w)
                        : Icon(IconlyBroken.setting, size: 9.w),
                    label: Text('Settings'),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(2.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8.0), // Decreased space below
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$daysLeft',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 7.w,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        'days left for new year',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
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
                                      style: TextStyle(
                                        fontSize: 5.w,
                                        color: Colors.blue,
                                        fontFamily: 'Manrope',
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
                      SizedBox(height: 10), // Added space for SizedBox
                      Text(
                        "Daily Tasks:",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 5.w,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: dailyTasks.length,
                          itemBuilder: (context, index) {
                            return TaskCard(
                              task: dailyTasks[index],
                              onDismissed: () {
                                setState(() {
                                  dailyTasks.removeAt(index);
                                });
                              },
                              onChanged: (value) {
                                setState(() {
                                  dailyTasks[index]['completed'] = value!;
                                  saveProgress();
                                });
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 2.h), // Decreased space below
                      Text(
                        "Additional Tasks:",
                        style: TextStyle(
                          fontFamily: 'Manrope',
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
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
                      additionalTasks
                          .add({'task': _controller.text, 'completed': false});
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
            style: TextStyle(
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
