import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:hundred_days/utils/loader.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressTracker extends StatefulWidget {
  const ProgressTracker({super.key});

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker> {
  Map<DateTime, int> dateMap = {};
  DateTime currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? selectedDate;
  String userEmail = '';
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  int totalTasksAllTime = 0;
  int completedTasksAllTime = 0;
  int totalTasksThisWeek = 0;
  int completedTasksThisWeek = 0;

  @override
  void initState() {
    super.initState();
    loadUserEmail();
  }

  Future<void> loadUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email!;
        fetchTaskDataFromFirebase();
        fetchTotalTaskDataFromFirebase();
      });
    }
  }

  Future<void> fetchTaskDataFromFirebase() async {
    if (userEmail.isEmpty) return;

    try {
      final taskRecords = await FirebaseFirestore.instance
          .collection('taskRecord')
          .doc(userEmail)
          .collection('records')
          .get();

      Map<DateTime, int> tempDateMap = {};
      for (var record in taskRecords.docs) {
        final dateStr = record.id;
        final taskCompletion = record.data()['overallCompletion'];

        DateTime recordDate = DateFormat('dd-MM-yyyy').parse(dateStr);
        tempDateMap[recordDate] = int.parse(taskCompletion.split('/')[0]);
      }

      setState(() {
        dateMap = tempDateMap;
        isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Error fetching task data: $e', Colors.red);
    }
  }

  Future<void> fetchTotalTaskDataFromFirebase() async {
    if (userEmail.isEmpty) return;

    try {
      final taskRecords = await FirebaseFirestore.instance
          .collection('taskRecord')
          .doc(userEmail)
          .collection('records')
          .get();

      int totalTasksAllTime = 0;
      int completedTasksAllTime = 0;

      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

      int totalTasksThisWeek = 0;
      int completedTasksThisWeek = 0;

      for (var record in taskRecords.docs) {
        final tasks =
            List<Map<String, dynamic>>.from(record.data()['tasks'] ?? []);
        int totalTasks = tasks.length;
        int completedTasks =
            tasks.where((task) => task['status'] == 'completed').length;

        totalTasksAllTime += totalTasks;
        completedTasksAllTime += completedTasks;

        DateTime recordDate = DateFormat('dd-MM-yyyy').parse(record.id);
        if (recordDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            recordDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          totalTasksThisWeek += totalTasks;
          completedTasksThisWeek += completedTasks;
        }
      }

      setState(() {
        this.totalTasksAllTime = totalTasksAllTime;
        this.completedTasksAllTime = completedTasksAllTime;
        this.totalTasksThisWeek = totalTasksThisWeek;
        this.completedTasksThisWeek = completedTasksThisWeek;
      });
    } catch (e) {
      _showSnackBar('Error fetching total task data: $e', Colors.red);
    }
  }

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

    final tasks =
        List<Map<String, dynamic>>.from(taskSnapshot.data()?['tasks'] ?? []);
    return tasks;
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isLoading = true;
    });
    await fetchTaskDataFromFirebase();
    await fetchTotalTaskDataFromFirebase();
    setState(() {
      isLoading = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
        ),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: PLoader());
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            selectedDate = null;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RefreshIndicator(
            color: Colors.blue,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 1.h),
                  // Heatmap Calendar
                  _buildHeatmapCalendar(),
                  Divider(color: Colors.grey.shade300),
                  if (selectedDate == null) ...[
                    _buildProgressIndicators(),
                    _buildTaskCompletionProgress(),
                  ] else ...[
                    _buildSelectedDateTasks(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapCalendar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: HeatMapCalendar(
          size: 9.5.w,
          colorTipSize: 2.w,
          monthFontSize: 15.sp,
          initDate: currentMonth,
          datasets: dateMap,
          colorMode: ColorMode.color,
          colorsets: {
            1: Colors.green[200]!,
            2: Colors.green[400]!,
            3: Colors.green[600]!,
            4: Colors.green[800]!,
          },
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
        ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircularProgressIndicator(
            radius: 10.w,
            percent: totalTasksThisWeek > 0
                ? completedTasksThisWeek / totalTasksThisWeek
                : 0.0,
            progressColor: Colors.blue,
            header: "This Week",
          ),
          _buildCircularProgressIndicator(
            radius: 10.w,
            percent: totalTasksAllTime > 0
                ? completedTasksAllTime / totalTasksAllTime
                : 0.0,
            progressColor: Colors.purple,
            header: "All Time",
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCompletionProgress() {
    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Column(
        children: [
          Text(
            "Task Completion Progress",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            height: 40.h,
            child: FutureBuilder(
              future: Future.wait(
                  dateMap.keys.map((date) => fetchTasksForDate(date))),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const PLoader();
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available.'));
                }

                List<List<Map<String, dynamic>>> tasksList = snapshot.data!;
                List<DateTime> sortedDates = dateMap.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final completion = dateMap[date]!;
                    final tasks =
                        tasksList[dateMap.keys.toList().indexOf(date)];
                    double completionRate =
                        tasks.isEmpty ? 0 : completion / tasks.length;

                    return ListTile(
                      title: Text(
                        DateFormat('dd-MM-yyyy').format(date),
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                      ),
                      trailing: Container(
                        width: 30.w,
                        height: 2.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: completionRate,
                          child: Container(
                            height: 2.h,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateTasks() {
    return FadeOut(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tasks for ${DateFormat('dd-MM-yyyy').format(selectedDate!)} :",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCircularProgressIndicator(
                  radius: 10.w,
                  percent: tasks.isNotEmpty
                      ? tasks
                              .where((task) => task['status'] == 'completed')
                              .length /
                          tasks.length
                      : 0.0,
                  progressColor: Colors.purple,
                  header: "Task Completion",
                ),
                Text(
                  "${tasks.where((task) => task['status'] == 'completed').length} / ${tasks.length}",
                  style: GoogleFonts.plusJakartaSans(fontSize: 25.sp),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              height: 30.h,
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(
                      task['task'],
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                    ),
                    trailing: Icon(
                      task['status'] == 'completed'
                          ? Icons.check_circle
                          : Icons.circle,
                      color: task['status'] == 'completed'
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgressIndicator({
    required double radius,
    required double percent,
    required Color progressColor,
    required String header,
  }) {
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: 8.0,
      percent: percent,
      progressColor: progressColor,
      backgroundColor: Colors.grey[300]!,
      center: Text(
        "${(percent * 100).toStringAsFixed(0)}%",
        style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
      ),
      header: Padding(
        padding: EdgeInsets.only(bottom: 1.h),
        child: Text(
          header,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
        ),
      ),
    );
  }
}
