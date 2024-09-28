import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/homescreen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTasks extends StatefulWidget {
  final int input;
  const AddTasks({super.key, required this.input});

  @override
  State<AddTasks> createState() => _AddTasksState();
}

class _AddTasksState extends State<AddTasks> {
  List<String> currentDailyTasks = [];
  bool isTaskListModified = false; // Flag to track modifications
  final _controller = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> saveDailyTasksToPreferences(List<String> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dailyTasks', tasks);
    print('Tasks saved to SharedPreferences: $tasks');
  }

  Future<void> loadDailyTasksFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load tasks from SharedPreferences
    currentDailyTasks = prefs.getStringList('dailyTasks') ?? [];

    // If no tasks are found in SharedPreferences, load from Firestore
    if (currentDailyTasks.isEmpty) {
      print('SharedPreferences are empty, fetching from Firebase.');
      await loadDailyTasksFromFirestore();
    } else {
      print('Tasks loaded from SharedPreferences: $currentDailyTasks');
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
          print(
              'Tasks loaded from Firestore and saved to SharedPreferences: $currentDailyTasks');
        } else {
          print('No tasks found in Firestore.');
        }
      }
    } catch (e) {
      print("Error loading tasks from Firestore: $e");
    }
  }

  Future<void> saveDailyTasksToFirestore(List<String> tasks) async {
    try {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentReference userTasksDoc =
            firestore.collection('dailyTasks').doc(userEmail);
        await userTasksDoc.set({'tasks': tasks});
        print('Current daily tasks saved: $tasks');

        await saveDailyTasksToPreferences(tasks);
      }
    } catch (e) {
      print("Error saving tasks to Firestore: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadDailyTasksFromPreferences();
  }

  @override
  Widget build(BuildContext context) {
    String username = auth.currentUser?.displayName ?? 'User';

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
                                            isTaskListModified =
                                                true; // Mark as modified
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
                          isTaskListModified = true; // Mark as modified
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
                  if (isTaskListModified) {
                    saveDailyTasksToFirestore(currentDailyTasks);
                    saveDailyTasksToPreferences(currentDailyTasks);
                  } else {
                    print("No changes to task list, not saving.");
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
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
