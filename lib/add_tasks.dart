import 'package:animate_do/animate_do.dart'; // For animations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:firebase_auth/firebase_auth.dart';

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
      String? userEmail =
          auth.currentUser?.email; // Use the current user's email
      if (userEmail != null) {
        DocumentReference userTasksDoc =
            firestore.collection('dailyTasks').doc(userEmail);

        // Save currentDailyTasks in Firestore
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

        // Prepare task data
        List<Map<String, dynamic>> taskData = currentDailyTasks.map((task) {
          return {
            'task': task,
            'status':
                'incomplete' // You can update this later based on task completion
          };
        }).toList();

        // Calculate the overall completion percentage (dummy calculation here)
        int completedTasks =
            taskData.where((task) => task['status'] == 'completed').length;
        double overallCompletion =
            (completedTasks / currentDailyTasks.length) * 100;

        await taskRecordDoc.set({
          'tasks': taskData,
          'overallCompletion': '$completedTasks/${currentDailyTasks.length}',
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
    fetchDailyTasksFromFirestore(); // Load tasks from Firestore when the app starts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.input == 0
          ? null
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
                style: TextStyle(
                    fontFamily: 'Manrope', fontWeight: FontWeight.bold),
              ),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello User!',
              style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'These are your daily tasks which will be renewed every day at 12 AM. Your current day progress will be registered.',
              style: TextStyle(
                  fontFamily: 'Manrope', fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Daily Tasks:",
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
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
                                const Text(
                                  'Add New Task',
                                  style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
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
                                        textStyle: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
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
                                        textStyle: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
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
                    // Adding animation
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
                            style: const TextStyle(
                                fontFamily: 'Manrope', fontSize: 16),
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
                  textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  saveTaskRecordToFirestore(); // Save the task record for today
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                child: const Text('Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
