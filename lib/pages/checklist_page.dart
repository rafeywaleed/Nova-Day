import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:hundred_days/utils/dialog_box.dart';
import 'package:hundred_days/utils/fab_offset.dart';
import 'package:hundred_days/utils/task_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class CheckListPage extends StatefulWidget {
  const CheckListPage({super.key});

  @override
  State<CheckListPage> createState() => _CheckListPageState();
}

class _CheckListPageState extends State<CheckListPage> {
  List<Map<String, dynamic>> additionalTasks = [];
  String? userEmail;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchAdditionalTasks();
  }

  Future<void> saveAdditionalTasksToSharedPreferences(
      List<Map<String, dynamic>> additionalTasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskList =
        additionalTasks.map((task) => jsonEncode(task)).toList();
    await prefs.setStringList('additionalTasks', taskList);
  }

  Future<void> saveAdditionalTasksToFirebase(
      List<Map<String, dynamic>> additionalTasks) async {
    String? userEmail = auth.currentUser?.email;
    if (userEmail != null) {
      DocumentReference taskRecordDoc = firestore
          .collection('taskRecord')
          .doc(userEmail)
          .collection('addTasks')
          .doc('tasks');

      await taskRecordDoc.set({
        'tasks': additionalTasks,
      });
    }
  }

  Future<void> createNewAdditionalTask(
      String taskName, String description) async {
    Map<String, dynamic> newTask = {
      'task': taskName,
      'description': description,
      'status': 'incomplete',
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('additionalTasks');
    List<Map<String, dynamic>> tasks = taskJsonList != null
        ? taskJsonList
            .map((taskJson) => jsonDecode(taskJson))
            .toList()
            .cast<Map<String, dynamic>>()
        : [];

    tasks.add(newTask);

    await saveAdditionalTasksToSharedPreferences(tasks);
    await saveAdditionalTasksToFirebase(tasks);
  }

  Future<void> deleteAdditionalTask(String taskName) async {
    // Fetch existing tasks
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('additionalTasks');
    if (taskJsonList != null) {
      List<Map<String, dynamic>> tasks = taskJsonList
          .map((taskJson) => jsonDecode(taskJson))
          .toList()
          .cast<Map<String, dynamic>>();

      // Remove task
      tasks.removeWhere((task) => task['task'] == taskName);
      //print('Additional tasks removed');

      await saveAdditionalTasksToSharedPreferences(tasks);
      await saveAdditionalTasksToFirebase(tasks);
    }
  }

  Future<void> updateAdditionalTask(String taskName, bool completed) async {
    // Fetch existing tasks
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('additionalTasks');
    if (taskJsonList != null) {
      List<Map<String, dynamic>> tasks = taskJsonList
          .map((taskJson) => jsonDecode(taskJson))
          .toList()
          .cast<Map<String, dynamic>>();

      // Update task status
      for (var task in tasks) {
        if (task['task'] == taskName) {
          task['status'] = completed ? 'complete' : 'incomplete';
          //print('Additional tasks updated \n ${tasks}');
        }
      }

      // Save updated tasks
      await saveAdditionalTasksToSharedPreferences(tasks);
      await saveAdditionalTasksToFirebase(tasks);
    }
  }

  Future<void> fetchAdditionalTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('additionalTasks');

    if (taskJsonList == null || taskJsonList.isEmpty) {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentReference taskRecordDoc = firestore
            .collection('taskRecord')
            .doc(userEmail)
            .collection('addTasks')
            .doc('tasks');

        DocumentSnapshot<Object?> querySnapshot = await taskRecordDoc.get();
        if (querySnapshot.exists) {
          List<Map<String, dynamic>> tasks =
              List<Map<String, dynamic>>.from(querySnapshot.get('tasks'));
          List<String> taskJsonList =
              tasks.map((task) => jsonEncode(task)).toList();
          await prefs.setStringList('additionalTasks', taskJsonList);
          setState(() {
            additionalTasks = tasks;
          });
        }
      }
    } else {
      setState(() {
        additionalTasks = taskJsonList
            .map((taskJson) => jsonDecode(taskJson))
            .toList()
            .cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _handleRefresh() async {
    await fetchAdditionalTasks();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'On The Go',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Tooltip(
                exitDuration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(5),
                textAlign: TextAlign.center,
                message:
                    'This is your personal to-do list.\nThese tasks won’t affect \nyour main progress tracking.\nSwipe left to delete a task.\nHold and Drag to reorder tasks.',
                child: Icon(
                  Icons.info_outline,
                  color: Colors.grey,
                  size: 5.w,
                ),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        bottomNavigationBar: SizedBox(height: 10.h),
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text(
                //       " On the way:",
                //       style: GoogleFonts.plusJakartaSans(
                //         fontSize: 5.w,
                //         fontWeight: FontWeight.bold,
                //         color: Colors.grey,
                //       ),
                //     ),
                //     Tooltip(
                //       exitDuration: const Duration(milliseconds: 500),
                //       padding: const EdgeInsets.all(5),
                //       textAlign: TextAlign.center,
                //       message:
                //           'Your to-do list \nwhich will not be in account \nof your progess',
                //       child: Icon(
                //         Icons.info_outline,
                //         color: Colors.grey,
                //         size: 5.w,
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 10),
                additionalTasks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            '\n\nNo additional tasks added yet.',
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
                            final item = additionalTasks.removeAt(oldIndex);
                            additionalTasks.insert(newIndex, item);
                          });
                          await saveAdditionalTasksToSharedPreferences(
                              additionalTasks);
                          await saveAdditionalTasksToFirebase(additionalTasks);
                        },
                        children: [
                          for (int index = 0;
                              index < additionalTasks.length;
                              index++)
                            TaskCard(
                              key: ValueKey(additionalTasks[index]['task']),
                              task: additionalTasks[index],
                              onDelete: () {
                                String taskName =
                                    additionalTasks[index]['task'];
                                setState(() {
                                  additionalTasks.removeWhere(
                                      (task) => task['task'] == taskName);
                                });
                                deleteAdditionalTask(taskName);
                              },
                              isDailyTask: false,
                              onChanged: (value) {
                                setState(() {
                                  additionalTasks[index]['completed'] = value!;
                                });
                                updateAdditionalTask(
                                    additionalTasks[index]['task'], value!);
                              },
                            ),
                        ],
                      ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: CustomFABLocationWithSizer(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromRGBO(0, 0, 0, 1),
          foregroundColor: Colors.white,
          onPressed: () async {
            final _controller = TextEditingController();
            final _descriptionController = TextEditingController();
            showDialog(
              context: context,
              builder: (context) {
                return DialogBox(
                  Controller: _controller,
                  descriptionController: _descriptionController,
                  onSave: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() {
                        additionalTasks.add({
                          'task': _controller.text,
                          'description': _descriptionController.text,
                          'completed': false
                        });
                      });
                      saveAdditionalTasksToSharedPreferences(additionalTasks);
                      saveAdditionalTasksToFirebase(additionalTasks);
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
          child: const Icon(Icons.add),
          tooltip: 'Add a new task',
        ),
      ),
    );
    ;
  }
}
