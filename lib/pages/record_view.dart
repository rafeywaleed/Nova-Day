import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressTracker extends StatefulWidget {
  const ProgressTracker({super.key});

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker> {
  Map<DateTime, int> dateMap = {}; // Task completion data from Firebase
  DateTime startDate = DateTime(2024, 1, 1);
  DateTime endDate = DateTime(2024, 12, 31);
  DateTime? selectedDate;
  String userEmail = '';
  
  double weeklyProgress = 0.7; // Placeholder, to be fetched from Firebase
  double allTimeProgress = 0.8; // Placeholder, to be fetched from Firebase

  @override
  void initState() {
    super.initState();
    loadUserEmail(); // Fetch user email for Firebase data
  }

  // Fetch user email for authenticated user
  Future<void> loadUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email!;
        fetchTaskDataFromFirebase(); // Load the task data from Firebase after fetching email
      });
    }
  }

  // Fetch user task completion data from Firebase
  void fetchTaskDataFromFirebase() async {
    if (userEmail.isEmpty) return;

    final taskRecords = await FirebaseFirestore.instance
        .collection('taskRecord')
        .doc(userEmail)
        .collection('records')
        .get();

    Map<DateTime, int> tempDateMap = {};
    for (var record in taskRecords.docs) {
      final dateStr = record.id; // Date in 'dd-MM-yyyy' format
      final taskCompletion = record.data()['completedTasks'] as int;

      DateTime recordDate = DateFormat('dd-MM-yyyy').parse(dateStr);
      tempDateMap[recordDate] = taskCompletion; // Map date to completion status
    }

    setState(() {
      dateMap = tempDateMap; // Update state with fetched data
    });
  }

  // Fetch tasks for the selected date
  Future<List<Map<String, dynamic>>> fetchTasksForDate(DateTime date) async {
    if (userEmail.isEmpty) return [];

    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    final taskSnapshot = await FirebaseFirestore.instance
        .collection('taskRecord')
        .doc(userEmail)
        .collection('records')
        .doc(formattedDate)
        .get();

    if (!taskSnapshot.exists) return [];

    final tasks = List<Map<String, dynamic>>.from(taskSnapshot.data()?['tasks'] ?? []);
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> tasks = [];

    return Scaffold(
      body: Column(
        children: [
          // Heatmap Calendar
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: HeatMap(
                  datasets: dateMap,
                  startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
                  endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
                  colorMode: ColorMode.color,
                  showText: true, // Show small date inside each box
                  scrollable: true, // Allow horizontal scrolling for months
                  size: 50, // Increase box size for better readability
                  onClick: (date) {
                    setState(() {
                      selectedDate = date;
                      fetchTasksForDate(selectedDate!).then((fetchedTasks) {
                        setState(() {
                          tasks = fetchedTasks;
                        });
                      });
                    });
                  },
                  colorsets: {
                    1: Colors.green[200]!,
                    2: Colors.green[400]!,
                    3: Colors.green[600]!,
                  },
                ),
              ),
            ),
          ),

          if (selectedDate == null) ...[
            // Circular Progress Indicators for Weekly and All-Time Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CircularPercentIndicator(
                  radius: 60,
                  lineWidth: 10.0,
                  percent: weeklyProgress,
                  center: Text("${(weeklyProgress * 100).toStringAsFixed(0)}%"),
                  progressColor: Colors.blue,
                  backgroundColor: Colors.grey[300]!,
                  header: Text("This Week"),
                ),
                CircularPercentIndicator(
                  radius: 60,
                  lineWidth: 10.0,
                  percent: allTimeProgress,
                  center: Text("${(allTimeProgress * 100).toStringAsFixed(0)}%"),
                  progressColor: Colors.green,
                  backgroundColor: Colors.grey[300]!,
                  header: Text("All Time"),
                ),
              ],
            ),
          ] else ...[
            // Display Tasks and Day Completion for the selected date
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tasks for ${DateFormat('dd-MM-yyyy').format(selectedDate!)}",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...tasks.map((task) => ListTile(
                          title: Text(task['task']),
                          trailing: Icon(task['status']
                              ? Icons.check_circle
                              : Icons.circle),
                        )),
                    const SizedBox(height: 16),
                    CircularPercentIndicator(
                      radius: 60,
                      lineWidth: 10.0,
                      percent: tasks.isNotEmpty
                          ? tasks.where((task) => task['status']).length / tasks.length
                          : 0.0,
                      center: Text(
                          "${(tasks.where((task) => task['status']).length / tasks.length * 100).toStringAsFixed(0)}%"),
                      progressColor: Colors.purple,
                      backgroundColor: Colors.grey[300]!,
                      header: Text("Task Completion"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
