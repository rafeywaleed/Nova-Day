import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../homescreen.dart';

class HabitTracker extends StatefulWidget {
  const HabitTracker({super.key});

  @override
  State<HabitTracker> createState() => _HabitTrackerState();
}

class _HabitTrackerState extends State<HabitTracker> {
  List<Map<String, dynamic>> dailyTasks = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadUserEmail();
    loadDailyTasks();
    resetTaskAnyway();
    checkAndUpdateTasks();
    startNetworkListener();
  }

  Future<void> checkAndUpdateTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    String? storedDate = prefs.getString('tDate');
    ////print("inside check and Update");

    if (storedDate == null || storedDate != currentDate) {
      ////print("entered if condition");
      await saveProgress();
      ////print("save progress complete");
      await resetTasks();
      ////print("task's reset");
      await prefs.setString('tDate', currentDate);
      ////print(prefs.getString('tDate'));
    } else {
      ////print("date matched");
      loadDailyTasks();
    }
  }

  Future<void> resetTaskAnyway() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? storedData = prefs.getString('tDate');
    ////print('Currently stored date: $storedData'); // Debugging output

    String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    if (storedData == null || storedData != todayDate) {
      await resetTasks();
      await prefs.setString('tDate', todayDate);
      ////print('Saved new date: $todayDate'); // Debugging output
    }
  }

  Future<void> resetTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('dailyTasks');

    if (taskJsonList != null) {
      List<Map<String, dynamic>> tasks = taskJsonList.map((taskJson) {
        return Map<String, dynamic>.from(jsonDecode(taskJson));
      }).toList();

      List<Map<String, dynamic>> updatedTasks = tasks.map((task) {
        return {
          'task': task['task'],
          'completed': false,
        };
      }).toList();

      // Convert the updated tasks back to JSON and save them
      List<String> updatedTaskJsonList = updatedTasks.map((task) {
        return jsonEncode(task);
      }).toList();

      await prefs.setStringList('dailyTasks', updatedTaskJsonList);
      ////print("All tasks marked as incomplete.");

      setState(() {
        dailyTasks = updatedTasks;
      });
    } else {
      ////print("No tasks found to reset.");
    }
  }

  Future<void> saveNormalProgress() async {
    String? userId = auth.currentUser?.uid;
    String? userEmail = auth.currentUser?.email;
    if (userId != null && userEmail != null) {
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
    }
  }

  Future<void> saveProgress() async {
    String? userId = auth.currentUser?.uid;
    String? userEmail = auth.currentUser?.email;
    ////print("inside saveProgress");
    if (userId != null && userEmail != null) {
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      List<Map<String, dynamic>> taskProgress = dailyTasks
          .map((task) => {
                'task': task['task'],
                'status': task['completed'] ? 'completed' : 'incomplete'
              })
          .toList();

      int totalTasks = taskProgress.length;
      int completedTasks =
          taskProgress.where((task) => task['status'] == 'completed').length;

      ConnectivityResult connectivityResult =
          (await Connectivity().checkConnectivity()) as ConnectivityResult;

      if (connectivityResult == ConnectivityResult.none) {
        // Device is offline, save data to be uploaded later
        await saveToBeUploaded(today, taskProgress, completedTasks, totalTasks);
      } else {
        // Device is online, save data directly to Firebase
        await uploadToFirebase(today, taskProgress, completedTasks, totalTasks);
      }
    }
  }

// Function to save data locally when offline
  Future<void> saveToBeUploaded(String date, List<Map<String, dynamic>> tasks,
      int completedTasks, int totalTasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> toBeUploaded =
        prefs.getStringList('toBeUploaded') ?? []; // Existing data

    Map<String, dynamic> data = {
      'date': date,
      'tasks': tasks,
      'overallCompletion': '$completedTasks /$totalTasks',
    };

    toBeUploaded.add(jsonEncode(data));
    await prefs.setStringList('toBeUploaded', toBeUploaded);
  }

  String? userEmail;
  Future<void> loadUserEmail() async {
    User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    }
  }

// Function to upload data directly to Firebase
  Future<void> uploadToFirebase(String date, List<Map<String, dynamic>> tasks,
      int completedTasks, int totalTasks) async {
    DocumentReference taskRecordDoc = firestore
        .collection('taskRecord')
        .doc(userEmail)
        .collection('records')
        .doc(date);

    await taskRecordDoc.set({
      'tasks': tasks,
      'overallCompletion': '$completedTasks/$totalTasks',
      'date': date,
    });
  }

// Function to upload saved tasks when back online
  Future<void> uploadTasksIfOffline() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> toBeUploaded = prefs.getStringList('toBeUploaded') ?? [];

    for (String record in toBeUploaded) {
      Map<String, dynamic> data = jsonDecode(record);
      await uploadToFirebase(
        data['date'],
        List<Map<String, dynamic>>.from(data['tasks']),
        int.parse(data['overallCompletion'].split('/')[0]),
        int.parse(data['overallCompletion'].split('/')[1]),
      );
    }

    await prefs.remove('toBeUploaded');
  }

// Start network listener to handle offline data upload
  void startNetworkListener() {
    Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      if (connectivityResult != ConnectivityResult.none) {
        await uploadTasksIfOffline().then((_) {
          ////print('Tasks uploaded successfully.');
        }).catchError((error) {
          ////print('Error uploading tasks: $error');
        });
      }
    });
  }

  Future<void> loadDailyTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskNames = prefs.getStringList('dailyTasks') ?? [];
    List<String>? savedTasksJson = prefs.getStringList('defaultTasks') ?? [];
    List<Map<String, dynamic>> savedTasks = [];
    if (taskNames.isNotEmpty) {
      savedTasks = savedTasksJson
          .map((taskJson) => jsonDecode(taskJson))
          .toList()
          .cast<Map<String, dynamic>>();
      ////print('Daily tasks fetched from shredPrefrnces');
    } else {
      await fetchDailyTasksFromFirebase();
    }
  }

  Future<void> fetchDailyTasksFromFirebase() async {
    String? userEmail = auth.currentUser?.email;
    if (userEmail != null) {
      DocumentSnapshot userTasksSnapshot =
          await firestore.collection('dailyTasks').doc(userEmail).get();

      if (userTasksSnapshot.exists) {
        var data = userTasksSnapshot.data() as Map<String, dynamic>;
        List<String> taskNames = List<String>.from(data['tasks'] ?? []);
        setState(() {
          dailyTasks = taskNames
              .map((name) => {'task': name, 'completed': false})
              .toList();
        });
        await saveTasksToSharedPreferences(dailyTasks);
      }
    }
  }

  Future<void> saveTasksToSharedPreferences(
      List<Map<String, dynamic>> defaultTasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      List<String> updatedDefaultTasksJson =
          defaultTasks.map((task) => jsonEncode(task)).toList();

      await prefs.setStringList('defaultTasks', updatedDefaultTasksJson);
    } catch (e) {
      //print('Error saving tasks to SharedPreferences: $e');
    }
  }

  Future<void> saveTasksToFirebase(List<Map<String, dynamic>> tasks) async {
    String? userEmail = auth.currentUser?.email;
    if (userEmail != null) {
      List<String> taskNames =
          tasks.map((task) => task['task'] as String).toList();
      await firestore.collection('dailyTasks').doc(userEmail).set({
        'tasks': taskNames,
      });
    }
  }

  Future<void> updateTaskRecordOnFirebase() async {
    String? userEmail = auth.currentUser?.email;
    if (userEmail != null) {
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

      await taskRecordDoc.set({
        'tasks': taskProgress,
        'overallCompletion': '$completedTasks/$totalTasks',
        'date': today,
      });
    }
  }

  Future<void> addDailyTask(String taskName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Update the names list in SharedPreferences and Firestore
    List<String> taskNames = prefs.getStringList('dailyTasks') ?? [];
    if (!taskNames.contains(taskName)) {
      taskNames.add(taskName);
      await prefs.setStringList('dailyTasks', taskNames);
      if (userEmail != null) {
        await firestore
            .collection('dailyTasks')
            .doc(userEmail)
            .set({'tasks': taskNames});
      }
    }

    // 2. Update today's taskRecord in Firestore (with status)
    String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    DocumentReference taskRecordDoc = firestore
        .collection('taskRecord')
        .doc(userEmail)
        .collection('records')
        .doc(today);

    DocumentSnapshot recordSnapshot = await taskRecordDoc.get();
    List<Map<String, dynamic>> recordTasks = [];
    if (recordSnapshot.exists) {
      var data = recordSnapshot.data() as Map<String, dynamic>;
      recordTasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
    }
    if (!recordTasks.any((t) => t['task'] == taskName)) {
      recordTasks.add({'task': taskName, 'status': 'incomplete'});
    }
    int completedTasks =
        recordTasks.where((t) => t['status'] == 'completed').length;
    int totalTasks = recordTasks.length;
    await taskRecordDoc.set({
      'tasks': recordTasks,
      'overallCompletion': '$completedTasks/$totalTasks',
      'date': today,
    });

    // 3. Update local UI list
    setState(() {
      dailyTasks =
          taskNames.map((name) => {'task': name, 'completed': false}).toList();
    });
  }

  Future<void> deleteDailyTask(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String taskName = dailyTasks[index]['task'];

    // 1. Remove from names list in SharedPreferences and Firestore
    List<String> taskNames = prefs.getStringList('dailyTasks') ?? [];
    taskNames.remove(taskName);
    await prefs.setStringList('dailyTasks', taskNames);
    if (userEmail != null) {
      await firestore
          .collection('dailyTasks')
          .doc(userEmail)
          .set({'tasks': taskNames});
    }

    // 2. Remove from today's taskRecord in Firestore
    String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    DocumentReference taskRecordDoc = firestore
        .collection('taskRecord')
        .doc(userEmail)
        .collection('records')
        .doc(today);

    DocumentSnapshot recordSnapshot = await taskRecordDoc.get();
    List<Map<String, dynamic>> recordTasks = [];
    if (recordSnapshot.exists) {
      var data = recordSnapshot.data() as Map<String, dynamic>;
      recordTasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
      recordTasks.removeWhere((t) => t['task'] == taskName);
      int completedTasks =
          recordTasks.where((t) => t['status'] == 'completed').length;
      int totalTasks = recordTasks.length;
      await taskRecordDoc.set({
        'tasks': recordTasks,
        'overallCompletion': '$completedTasks/$totalTasks',
        'date': today,
      });
    }

    // 3. Update local UI list
    setState(() {
      dailyTasks.removeAt(index);
    });

    // can delete these 3 lines
    await saveTasksToSharedPreferences(dailyTasks);
    await saveTasksToFirebase(dailyTasks);
    await updateTaskRecordOnFirebase();
  }

  Future<void> updateTaskCompletion(int index, bool? value) async {
    setState(() {
      dailyTasks[index]['completed'] = value ?? false;
    });
    await saveTasksToSharedPreferences(dailyTasks);
    await saveTasksToFirebase(dailyTasks);
    await updateTaskRecordOnFirebase();
  }

  bool isLoading = true;

  Future<void> _handleRefresh() async {
    setState(() {
      isLoading = true;
    });
    loadUserEmail();
    loadDailyTasks();
    resetTaskAnyway();
    checkAndUpdateTasks();
    // loadDailyTasks();
    saveNormalProgress();
    setState(() {
      isLoading = false;
    });
  }

  int get completedCount =>
      dailyTasks.where((task) => task['completed'] == true).length;

  @override
  Widget build(BuildContext context) {
    int totalTasks = dailyTasks.length;
    double taskCompletion = totalTasks > 0 ? completedCount / totalTasks : 0;
    int daysLeft = DateTime(DateTime.now().year + 1, 1, 1)
        .difference(DateTime.now())
        .inDays;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Habit Tracker',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        body: RefreshIndicator(
          color: Colors.blue,
          onRefresh: loadDailyTasks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 100.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.grey.shade200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            spreadRadius: 1,
                            color: Colors.grey.withOpacity(0.2),
                            offset: Offset(0, 5),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Today\'s overview',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 4.w,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '$daysLeft',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.w,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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
                            Flexible(
                              child: CircularPercentIndicator(
                                radius: 13.w,
                                animation: true,
                                lineWidth: 12.0,
                                percent: taskCompletion,
                                center: Text(
                                  "${(taskCompletion * 100).toStringAsFixed(0)}%",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 5.w,
                                    color: Colors.blue,
                                  ),
                                ),
                                progressColor: Colors.green,
                                backgroundColor: Colors.grey[300]!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Daily Tasks:",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 5.w,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
                  dailyTasks.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No Daily task.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 4.w,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dailyTasks.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> task = dailyTasks[index];
                            return Dismissible(
                              key: Key(
                                  task['task'] + task['completed'].toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Task'),
                                    content: const Text(
                                        'Are you sure you want to delete this daily task? This change is permanent.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                return confirm == true;
                              },
                              onDismissed: (direction) async {
                                await deleteDailyTask(index);
                              },
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: task['completed'] ?? false,
                                    onChanged: (value) {
                                      setState(() {
                                        dailyTasks[index]['completed'] = value!;
                                        saveTasksToSharedPreferences(
                                            dailyTasks);
                                        saveProgress();
                                        saveNormalProgress();
                                      });
                                    },
                                  ),
                                  title: Text(
                                    task['task'],
                                    style: GoogleFonts.plusJakartaSans(
                                      decoration: task['completed'] == true
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: task['completed'] == true
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            String? newTask = await showDialog<String>(
              context: context,
              builder: (context) {
                final controller = TextEditingController();
                return AlertDialog(
                  title: const Text('Add Daily Task'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Task Name',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This change is permanent and will be reflected everywhere.',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          Navigator.of(context).pop(controller.text.trim());
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                );
              },
            );
            if (newTask != null && newTask.isNotEmpty) {
              print("new task is $newTask");
              await addDailyTask(newTask);
            }
          },
          child: const Icon(Icons.add),
          tooltip: 'Add Daily Task',
        ),
      ),
    );
  }
}
