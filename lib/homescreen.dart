import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/add_tasks.dart';
import 'package:hundred_days/pages/settings.dart';
import 'package:hundred_days/utils/dialog_box.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sizer/sizer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> dailyTasks = [];
  List<Map<String, dynamic>> additionalTasks = [];

  @override
  Widget build(BuildContext context) {
    int totalTasks = dailyTasks.length;
    int completedTasks =
        dailyTasks.where((task) => task['completed'] == true).length;
    double taskCompletion = totalTasks > 0 ? completedTasks / totalTasks : 0;
    int daysLeft = DateTime(2025, 1, 1).difference(DateTime.now()).inDays;

    Future<List<Map<String, dynamic>>> loadDailyTasks() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? tasksString = prefs.getString('dailyTasks');
      if (tasksString != null) {
        List<dynamic> decodedList = jsonDecode(tasksString);
        return decodedList
            .map((task) => Map<String, dynamic>.from(task))
            .toList();
      }
      return [];
    }

    void checkForNewDay() {
      DateTime now = DateTime.now();
      DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0);
      Duration timeUntilMidnight = tomorrow.difference(now);

      Future.delayed(timeUntilMidnight, () {
        loadDailyTasks().then((tasks) {
          setState(() {
            dailyTasks = List<Map<String, dynamic>>.from(tasks);
          });
        });
        checkForNewDay();
      });
    }

    @override
    void initState() {
      super.initState();
      loadDailyTasks().then((tasks) {
        setState(() {
          dailyTasks = tasks;
        });
      });
      checkForNewDay();
    }

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
                    builder: (context) => const UserSettingsPage(),
                  ),
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
                  SizedBox(height: MediaQuery.of(context).size.height*0.05),
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
                              offset: const Offset(0, 5))
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
                  setState(() {
                    additionalTasks.add({'task': _controller.text, 'completed': false});
                  });
                  Navigator.of(context).pop();
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

  const TaskCard({required this.task, required this.onDismissed, required this.onChanged, Key? key}) : super(key: key);

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
              decoration: task['completed'] == true ? TextDecoration.lineThrough : TextDecoration.none,
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
