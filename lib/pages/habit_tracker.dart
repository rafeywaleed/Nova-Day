import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/pages/record_view.dart';
import 'package:hundred_days/utils/fab_offset.dart';
import 'package:iconly/iconly.dart';
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
  List<Map<String, dynamic>> defaultTasks = [];
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
    List<String>? taskJsonList = prefs.getStringList('defaultTasks');

    if (taskJsonList != null) {
      List<Map<String, dynamic>> tasks = taskJsonList.map((taskJson) {
        return Map<String, dynamic>.from(jsonDecode(taskJson));
      }).toList();

      List<Map<String, dynamic>> updatedTasks = tasks.map((task) {
        return {
          'task': task['task'], // Use 'task' instead of 'name'
          'completed': false,
        };
      }).toList();

      // Convert the updated tasks back to JSON and save them
      List<String> updatedTaskJsonList = updatedTasks.map((task) {
        return jsonEncode(task);
      }).toList();

      await prefs.setStringList('defaultTasks', updatedTaskJsonList);
      ////print("All tasks marked as incomplete.");

      setState(() {
        defaultTasks = updatedTasks;
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

  Future<void> saveProgress() async {
    String? userId = auth.currentUser?.uid;
    String? userEmail = auth.currentUser?.email;
    ////print("inside saveProgress");
    if (userId != null && userEmail != null) {
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      List<Map<String, dynamic>> taskProgress = defaultTasks
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

  String? userEmail;
  Future<void> loadUserEmail() async {
    User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    }
  }

  Future<void> loadDailyTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? savedTasksJson = prefs.getStringList('defaultTasks') ?? [];
    List<Map<String, dynamic>> savedTasks = [];

    if (savedTasksJson.isNotEmpty) {
      savedTasks = savedTasksJson
          .map((taskJson) => jsonDecode(taskJson))
          .toList()
          .cast<Map<String, dynamic>>();
      ////print('Daily tasks fetched from shredPrefrnces');
    } else {
      // If no tasks are found in SharedPreferences, fetch from Firebase
      await fetchDailyTasksFromFirebase();
    }

    // Load the task names (task titles) for the day from SharedPreferences
    List<String>? dailyTasks = prefs.getStringList('dailyTasks') ?? [];

    // Check if dailyTasks is not empty
    if (dailyTasks.isNotEmpty) {
      // Prepare a new list for updated defaultTasks
      List<Map<String, dynamic>> newDefaultTasks = [];

      // Iterate through the dailyTasks and merge with savedTasks to retain their status
      for (String taskName in dailyTasks) {
        // Check if the task already exists in savedTasks
        Map<String, dynamic>? existingTask = savedTasks.firstWhere(
          (task) => task['task'] == taskName,
          orElse: () => {},
        );

        if (existingTask.isNotEmpty) {
          // If the task exists, retain its status
          newDefaultTasks.add(existingTask);
        } else {
          // If it's a new task, add it as incomplete
          newDefaultTasks.add({'task': taskName, 'completed': false});
        }
      }

      // Update the defaultTasks in the state
      setState(() {
        defaultTasks = newDefaultTasks;
      });

      // Save updated defaultTasks back to SharedPreferences
      await saveTasksToSharedPreferences(defaultTasks);
    }
  }

  Future<void> fetchDailyTasksFromFirebase() async {
    try {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentSnapshot userTasksSnapshot =
            await firestore.collection('dailyTasks').doc(userEmail).get();

        if (userTasksSnapshot.exists) {
          var data = userTasksSnapshot.data() as Map<String, dynamic>;
          List<dynamic> firebaseTasks = data['tasks'] ?? [];

          List<Map<String, dynamic>> fetchedTasks = firebaseTasks.map((task) {
            return {
              'task': task['task'],
              'completed': task['completed'],
            };
          }).toList();

          ////print('daily tasks fetched from firebase');
          // Save the tasks fetched from Firebase to SharedPreferences
          await saveTasksToSharedPreferences(fetchedTasks);

          // Update the defaultTasks with the fetched data
          setState(() {
            defaultTasks = fetchedTasks;
          });
        } else {
          ////print("No tasks found in Firebase.");
        }
      }
    } catch (e) {
      ////print("Error fetching tasks from Firebase: $e");
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

  // Future<void> updateTaskRecordOnFirebase() async {
  //   String? userEmail = auth.currentUser?.email;
  //   if (userEmail != null) {
  //     String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
  //     DocumentReference taskRecordDoc = firestore
  //         .collection('taskRecord')
  //         .doc(userEmail)
  //         .collection('records')
  //         .doc(today);

  //     List<Map<String, dynamic>> taskProgress = dailyTasks
  //         .map((task) => {
  //               'task': task['task'],
  //               'status': task['completed'] ? 'completed' : 'incomplete'
  //             })
  //         .toList();

  //     int totalTasks = taskProgress.length;
  //     int completedTasks =
  //         taskProgress.where((task) => task['status'] == 'completed').length;

  //     await taskRecordDoc.set({
  //       'tasks': taskProgress,
  //       'overallCompletion': '$completedTasks/$totalTasks',
  //       'date': today,
  //     });
  //   }
  // }

  Future<void> addDailyTask(String taskName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Add to defaultTasks (local and UI)
    setState(() {
      defaultTasks.add({'task': taskName, 'completed': false});
    });

    // 2. Save defaultTasks to SharedPreferences
    List<String> updatedDefaultTasksJson =
        defaultTasks.map((task) => jsonEncode(task)).toList();
    await prefs.setStringList('defaultTasks', updatedDefaultTasksJson);

    // 3. Update dailyTasks (names only) in SharedPreferences and Firestore
    List<String> taskNames =
        defaultTasks.map((task) => task['task'] as String).toList();
    await prefs.setStringList('dailyTasks', taskNames);
    if (userEmail != null) {
      await firestore
          .collection('dailyTasks')
          .doc(userEmail)
          .set({'tasks': taskNames});
    }

    // 4. Update today's taskRecord in Firestore
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
  }

  Future<void> deleteDailyTask(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String taskName = defaultTasks[index]['task'];

    // 1. Remove from defaultTasks (local and UI)
    setState(() {
      defaultTasks.removeAt(index);
    });

    // 2. Save defaultTasks to SharedPreferences
    List<String> updatedDefaultTasksJson =
        defaultTasks.map((task) => jsonEncode(task)).toList();
    await prefs.setStringList('defaultTasks', updatedDefaultTasksJson);

    // 3. Update dailyTasks (names only) in SharedPreferences and Firestore
    List<String> taskNames =
        defaultTasks.map((task) => task['task'] as String).toList();
    await prefs.setStringList('dailyTasks', taskNames);
    if (userEmail != null) {
      await firestore
          .collection('dailyTasks')
          .doc(userEmail)
          .set({'tasks': taskNames});
    }

    // 4. Remove from today's taskRecord in Firestore
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
  }

  // Future<void> updateTaskCompletion(int index, bool? value) async {
  //   setState(() {
  //     dailyTasks[index]['completed'] = value ?? false;
  //   });
  //   await saveTasksToSharedPreferences(dailyTasks);
  //   await saveTasksToFirebase(dailyTasks);
  //   await updateTaskRecordOnFirebase();
  // }

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
      defaultTasks.where((task) => task['completed'] == true).length;

  @override
  Widget build(BuildContext context) {
    int totalTasks = defaultTasks.length;
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
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDaysLeftHeader(daysLeft, taskCompletion),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      " Track Today:",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 5.w,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 95, 95, 95),
                      ),
                    ),
                    Tooltip(
                      exitDuration: const Duration(milliseconds: 1000),
                      textAlign: TextAlign.center,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10.sp,
                      ),
                      message:
                          'These are your daily habits \n(like gym, reading, or studying). \nThey reset every day. \nSwipe left to remove a habit.\nhold and drag to reorder.',
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 5.w,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                defaultTasks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            '\n\nNo habits added yet. \nTap the "+" button to add a new habit.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) async {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = defaultTasks.removeAt(oldIndex);
                            defaultTasks.insert(newIndex, item);
                          });
                          await saveTasksToSharedPreferences(defaultTasks);
                          await saveTasksToFirebase(defaultTasks);
                          await saveNormalProgress();
                          await saveProgress();
                        },
                        children: [
                          for (int index = 0;
                              index < defaultTasks.length;
                              index++)
                            Dismissible(
                              key: Key(defaultTasks[index]['task'] +
                                  defaultTasks[index]['completed'].toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(IconlyLight.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      'Remove Habit',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.sp,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to remove this habit from your daily routine? This action can’t be undone.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
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
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: defaultTasks[index]['completed'] ??
                                        false,
                                    onChanged: (value) {
                                      setState(() {
                                        defaultTasks[index]['completed'] =
                                            value!;
                                        saveTasksToSharedPreferences(
                                            defaultTasks);
                                        saveProgress();
                                        saveNormalProgress();
                                      });
                                    },
                                  ),
                                  title: Text(
                                    defaultTasks[index]['task'],
                                    style: GoogleFonts.plusJakartaSans(
                                      decoration: defaultTasks[index]
                                                  ['completed'] ==
                                              true
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: defaultTasks[index]['completed'] ==
                                              true
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.drag_indicator_rounded,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SizedBox(height: 10.h),
        floatingActionButtonLocation: CustomFABLocationWithSizer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            String? newTask = await showDialog<String>(
              context: context,
              builder: (context) {
                final controller = TextEditingController();
                return AlertDialog(
                  title: Text(
                    'Add a New Habit',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 5.w,
                      color: Colors.black,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        autofocus: true,
                        controller: controller,
                        decoration: const InputDecoration(
                          // labelText: 'new Habit',
                          hintText: 'e.g., Gym, Reading, Studying',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This will become a part of your daily routine.',
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
          tooltip: 'Add a new habit',
        ),
      ),
    );
  }
}

Widget _buildDaysLeftHeader(int daysLeft, double taskCompletion) {
  return Center(
    child: Container(
      width: 100.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
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
                    color: const Color.fromARGB(255, 87, 87, 87),
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
                    fontWeight: FontWeight.bold,
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
  );
}
