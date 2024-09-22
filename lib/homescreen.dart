import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/add_tasks.dart';
import 'package:hundred_days/pages/settings.dart';
import 'package:hundred_days/utils/dialog_box.dart';
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

  @override
  void initState() {
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
    String? userEmail =
        auth.currentUser?.email; // Use userEmail instead of userId
    if (userEmail != null) {
      DocumentReference userTasksDoc =
          firestore.collection('dailyTasks').doc(userEmail);
      DocumentSnapshot snapshot = await userTasksDoc.get();

      if (snapshot.exists) {
        // Debugging: Print the snapshot data
        print("Snapshot data: ${snapshot.data()}");

        // Cast snapshot data to a Map<String, dynamic>
        var data = snapshot.data() as Map<String, dynamic>;
        var tasksData = data['tasks'];

        if (tasksData is List) {
          setState(() {
            // Create dailyTasks with task strings and set completed to false
            dailyTasks = tasksData
                .map((task) => {'task': task, 'completed': false})
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
          .doc(userEmail) // Use userEmail directly
          .collection('records')
          .doc(today);

      // Create a list of tasks with their statuses
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
      await saveProgress(); // Save progress at the end of the day
      await loadDailyTasks(); // Fetch new daily tasks
      checkForNewDay(); // Check again for the next day
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
      body: Row(
        children: [
          NavigationRail(
            minWidth: MediaQuery.of(context).size.width * 0.15,
            groupAlignment: 0,
            backgroundColor:
                const Color.fromARGB(255, 127, 127, 127).withOpacity(0.1),
            selectedIndex: 0,
            onDestinationSelected: (int index) {
              if (index == 1) {
                // Navigate to Record Screen
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserSettingsPage()),
                );
              }
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assessment),
                label: Text('Record'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  FadeInDown(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
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
                        padding: EdgeInsets.all(3.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: 2.h),
                  Text(
                    "Daily Tasks:\n",
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
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Text(
                    "Additional Tasks:\n",
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
