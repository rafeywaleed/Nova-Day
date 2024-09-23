import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:hundred_days/pages/intro_screens.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTasks extends StatefulWidget {
  final int input;
  const AddTasks({super.key, required this.input});

  @override
  State<AddTasks> createState() => _AddTasksState();
}

class _AddTasksState extends State<AddTasks> {
  List<String> currentDailyTasks = [];
  final _controller = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> saveDailyTasksToFirestore(List<String> tasks) async {
    try {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentReference userTasksDoc =
            firestore.collection('dailyTasks').doc(userEmail);
        await userTasksDoc.set({'tasks': tasks});
        print('Current daily tasks saved: $tasks');
      }
    } catch (e) {
      print("Error saving tasks to Firestore: $e");
    }
  }

  Future<void> fetchDailyTasksFromFirestore() async {
    try {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentReference userTasksDoc =
            firestore.collection('dailyTasks').doc(userEmail);
        DocumentSnapshot snapshot = await userTasksDoc.get();

        if (snapshot.exists) {
          List<dynamic> fetchedTasks = snapshot['tasks'] ?? [];
          setState(() {
            currentDailyTasks = List<String>.from(fetchedTasks);
          });
          print('Tasks fetched: $currentDailyTasks');
        } else {
          print('No tasks found for user: $userEmail');
        }
      }
    } catch (e) {
      print("Error fetching tasks from Firestore: $e");
    }
  }

  Future<void> saveTaskRecordToFirestore() async {
    try {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
        DocumentReference taskRecordDoc = firestore
            .collection('tasksRecord')
            .doc(userEmail)
            .collection('records')
            .doc(today);

        List<Map<String, dynamic>> taskData = currentDailyTasks.map((task) {
          return {'task': task, 'status': 'incomplete'};
        }).toList();

        await taskRecordDoc.set({
          'tasks': taskData,
          'overallCompletion':
              '${taskData.where((task) => task['status'] == 'completed').length}/${currentDailyTasks.length}',
          'date': today
        });
        print('Task record saved for $today');
      }
    } catch (e) {
      print("Error saving task record to Firestore: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDailyTasksFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    String username =
        auth.currentUser?.displayName ?? 'User'; // Get the username

    return Scaffold(
      appBar: widget.input == 0
          ? AppBar()
          : AppBar(
              leading: widget.input == 1
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  : null,
              title: const Text(
                'Add Daily Task',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello $username!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'These are your daily tasks which will be renewed every day at 12 AM. Your current day progress will be registered.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            // Text(
            //   "Note: The list you finish with will be your daily renewing tasks. Deleting daily tasks from the home screen will remove that task for the day only and will not affect your daily tasks, which will be renewed.",
            //   style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            // ),
            // widget.input == 0
            //     ? Text(
            //         "Note: These daily tasks will be renewed every day, and your progress will be recorded for daily tasks. Your additional tasks are simply your to-do tasks for the day and will not be tracked for progress. You can add additional tasks by tapping the [+] button on the home screen and delete additional tasks by swiping them to the right.",
            //         style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            //       )
            //     : Text(''),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Daily Tasks:",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Add New Task',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _controller,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter task here',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (_controller.text.isNotEmpty) {
                                          setState(() {
                                            currentDailyTasks
                                                .add(_controller.text);
                                            saveDailyTasksToFirestore(
                                                currentDailyTasks);
                                          });
                                          _controller.clear();
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
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
                          saveDailyTasksToFirestore(currentDailyTasks);
                        });
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            currentDailyTasks[index],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(100, 40),
                ),
                onPressed: () {
                  saveTaskRecordToFirestore();
                  //widget.input == 0 ? 
                  Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      // : Navigator.push(
                      //     context,
                      //     MaterialPageRoute(builder: (context) => IntroScreen(input: 1,)),
                      //   );
                },
                child: const Text('Finish'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Guide: Tap on + to add tasks, swipe right to delete a task, and click Finish to save your Daily Tasks.',
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
