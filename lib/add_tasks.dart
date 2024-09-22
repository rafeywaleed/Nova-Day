import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTasks extends StatefulWidget {
  final int input;
  const AddTasks({super.key, required this.input});

  @override
  State<AddTasks> createState() => _AddTasksState();
}

class _AddTasksState extends State<AddTasks> {
  List<String> dailyTasks = [];
  final _controller = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<String?> retrieveEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    print('Email retrieved: $email');
    return email;
  }

  // Save tasks to Firestore
  Future<void> saveDailyTasksToFirestore(List<String> tasks) async {
    try {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // String? userEmail = prefs.getString('userEmail');

      String userEmail = 'a.rafeywaleeda5@gmail.com';

      if (userEmail != null) {
        DocumentReference userTasksDoc =
            firestore.collection('dailyTasks').doc(userEmail);

        // Replace existing tasks with the new list
        await userTasksDoc.set({'tasks': tasks});
        print('Tasks saved: $tasks'); // Debugging print
      }
    } catch (e) {
      print("Error saving tasks to Firestore: $e");
    }
  }

  // Fetch tasks from Firestore
  Future<void> fetchDailyTasksFromFirestore() async {
    try {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // String? userEmail = prefs.getString('userEmail');
      String userEmail = 'a.rafeywaleeda5@gmail.com';

      if (userEmail != null) {
        DocumentReference userTasksDoc =
            firestore.collection('dailyTasks').doc(userEmail);
        DocumentSnapshot snapshot = await userTasksDoc.get();

        if (snapshot.exists) {
          List<dynamic> fetchedTasks = snapshot['tasks'] ?? [];
          setState(() {
            dailyTasks = List<String>.from(fetchedTasks);
          });
          print('Tasks fetched: $dailyTasks'); // Debugging print
        } else {
          print('No tasks found for user: $userEmail');
        }
      }
    } catch (e) {
      print("Error fetching tasks from Firestore: $e");
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
                                        setState(() {
                                          dailyTasks.add(_controller.text);
                                          saveDailyTasksToFirestore(dailyTasks);
                                        });
                                        _controller.clear();
                                        Navigator.of(context).pop();
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
                itemCount: dailyTasks.length,
                itemBuilder: (context, index) {
                  return FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    child: Dismissible(
                      key: Key(dailyTasks[index]),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (direction) {
                        setState(() {
                          dailyTasks.removeAt(index);
                          saveDailyTasksToFirestore(
                              dailyTasks); // Update tasks when deleted
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
                            dailyTasks[index],
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
                  retrieveEmail();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(),
                    ),
                  );
                },
                child: const Text('Finish'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Click on the '+' icon to add new tasks, and swipe the tasks to the right to delete them.",
              style: TextStyle(
                  fontFamily: 'Manrope', fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
