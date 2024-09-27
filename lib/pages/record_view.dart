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

  void fetchTotalTaskDataFromFirebase() async {
    if (userEmail.isEmpty) return;

    final taskRecords = await FirebaseFirestore.instance
        .collection('taskRecord')
        .doc(userEmail)
        .collection('records')
        .get();

    Map<DateTime, int> tempDateMap = {};
    int totalTasksAllTime = 0;
    int completedTasksAllTime = 0;

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    int totalTasksThisWeek = 0;
    int completedTasksThisWeek = 0;

    for (var record in taskRecords.docs) {
      final dateStr = record.id;
      final taskCompletion = record.data()['overallCompletion'];
      final tasks =
          List<Map<String, dynamic>>.from(record.data()['tasks'] ?? []);

      DateTime recordDate = DateFormat('dd-MM-yyyy').parse(dateStr);
      tempDateMap[recordDate] = int.parse(taskCompletion.split('/')[0]);

      int totalTasks = tasks.length;
      int completedTasks =
          tasks.where((task) => task['status'] == 'completed').length;

      totalTasksAllTime += totalTasks;
      completedTasksAllTime += completedTasks;

      if (recordDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          recordDate.isBefore(endOfWeek.add(Duration(days: 1)))) {
        totalTasksThisWeek += totalTasks;
        completedTasksThisWeek += completedTasks;
      }
    }

    setState(() {
      dateMap = tempDateMap;
      isLoading = false;
      this.totalTasksAllTime = totalTasksAllTime;
      this.completedTasksAllTime = completedTasksAllTime;
      this.totalTasksThisWeek = totalTasksThisWeek;
      this.completedTasksThisWeek = completedTasksThisWeek;
    });
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

  void fetchTaskDataFromFirebase() async {
    if (userEmail.isEmpty) return;

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

  void nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isLoading = true;
    });
    fetchTaskDataFromFirebase();
    setState(() {
      isLoading = false;
    });
  }

  void previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: PLoader(),
      );
    }
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: RefreshIndicator(
          color: Colors.blue,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 1.h),
                // Month Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: previousMonth,
                    ),
                    Text(
                      DateFormat.yMMMM().format(currentMonth),
                      style: GoogleFonts.openSans(
                          fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios),
                      onPressed: nextMonth,
                    ),
                  ],
                ),
                // Heatmap Calendar
                Container(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: HeatMap(
                        datasets: dateMap,
                        startDate: currentMonth,
                        endDate: DateTime(
                            currentMonth.year, currentMonth.month + 1, 0),
                        colorMode: ColorMode.color,
                        showText: true,
                        scrollable: false,
                        size: 10.w,
                        onClick: (date) {
                          setState(() {
                            selectedDate = date;
                            fetchTasksForDate(selectedDate!)
                                .then((fetchedTasks) {
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
                          4: Colors.green[800]!,
                        },
                      ),
                    ),
                  ),
                ),

                if (selectedDate == null) ...[
                  // Display Circular Progress Indicators when no date is selected
                  Container(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildCircularProgressIndicator(
                            radius: 10.w,
                            percent: totalTasksThisWeek > 0
                                ? completedTasksThisWeek / totalTasksThisWeek
                                : 0.0,
                            progressColor: Colors.blue,
                            header: "This Week",
                          ),
                          buildCircularProgressIndicator(
                            radius: 10.w,
                            percent: totalTasksAllTime > 0
                                ? completedTasksAllTime / totalTasksAllTime
                                : 0.0,
                            progressColor: Colors.purple,
                            header: "All Time",
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bar Graph
                  // Bar Graph
                  Container(
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              "Task Completion Progress",
                              style: GoogleFonts.openSans(
                                  fontSize: 14.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 1.h),
                            Container(
                              height: 40.h,
                              child: FutureBuilder(
                                future: Future.wait(dateMap.keys
                                    .map((date) => fetchTasksForDate(date))),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return PLoader();
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Error: ${snapshot.error}'));
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                        child: Text('No data available.'));
                                  }

                                  List<List<Map<String, dynamic>>> tasksList =
                                      snapshot.data
                                          as List<List<Map<String, dynamic>>>;

                                  return ListView.builder(
                                    itemCount: dateMap.length,
                                    itemBuilder: (context, index) {
                                      final date = dateMap.keys.elementAt(
                                          dateMap.length - 1 - index);
                                      final completion = dateMap[date]!;
                                      final tasks =
                                          tasksList[dateMap.length - 1 - index];
                                      double completionRate = tasks.isEmpty
                                          ? 0
                                          : completion / tasks.length;

                                      return ListTile(
                                        title: Text(
                                          DateFormat('dd-MM-yyyy').format(date),
                                          style: GoogleFonts.openSans(
                                              fontSize: 12.sp),
                                        ),
                                        trailing: Container(
                                          width: 30.w,
                                          height: 2.h,
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: completionRate,
                                            child: Container(
                                              height: 2.h,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Display Tasks for the selected date
                  FadeOut(
                    child: Container(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 1.h, horizontal: 2.w),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tasks for ${DateFormat('dd-MM-yyyy').format(selectedDate!)} :",
                                style: GoogleFonts.openSans(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 1.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  buildCircularProgressIndicator(
                                    radius: 10.w,
                                    percent: tasks.isNotEmpty
                                        ? tasks
                                                .where((task) =>
                                                    task['status'] ==
                                                    'completed')
                                                .length /
                                            tasks.length
                                        : 0.0,
                                    progressColor: Colors.purple,
                                    header: "Task Completion",
                                  ),
                                  Text(
                                    "${tasks.where((task) => task['status'] == 'completed').length} / ${tasks.length}",
                                    style:
                                        GoogleFonts.openSans(fontSize: 25.sp),
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
                                        style: GoogleFonts.openSans(
                                            fontSize: 12.sp),
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
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCircularProgressIndicator({
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
        "${(percent * 100).toStringAsFixed(1)}%",
        style:
            GoogleFonts.openSans(fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
      footer: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Text(
          header,
          style: GoogleFonts.openSans(
              fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
