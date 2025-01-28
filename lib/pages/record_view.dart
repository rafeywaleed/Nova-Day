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

    try {
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
    } catch (e) {
      print("Error fetching total task data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching task data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      dateMap = tempDateMap; // Keep all data without filtering
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
      fetchTotalTaskDataFromFirebase(); // Fetch data for the new month
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
      fetchTotalTaskDataFromFirebase(); 
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
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     IconButton(
                //       icon: Icon(Icons.arrow_back_ios),
                //       onPressed: previousMonth,
                //     ),
                //     Text(
                //       DateFormat.yMMMM().format(currentMonth),
                //       style: GoogleFonts.plusJakartaSans(
                //           fontSize: 14.sp, fontWeight: FontWeight.bold),
                //     ),
                //     IconButton(
                //       icon: Icon(Icons.arrow_forward_ios),
                //       onPressed: nextMonth,
                //     ),
                //   ],
                // ),
                // Heatmap Calendar
                Container(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: HeatMapCalendar(
                        size: 9.w,
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
                            fetchTasksForDate(selectedDate!)
                                .then((fetchedTasks) {
                              setState(() {
                                tasks = fetchedTasks;
                              });
                            });
                          });
                        },
                      ),
                    ),
                  ),
                ),

                if (selectedDate == null) ...[
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
                  // Bar ```dart
                  // Graph
                  Container(
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              "Task Completion Progress",
                              style: GoogleFonts.plusJakartaSans(
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
                                  List<DateTime> sortedDates = dateMap.keys
                                      .toList()
                                    ..sort((a, b) => b.compareTo(a));

                                  return ListView.builder(
                                    itemCount: sortedDates.length,
                                    itemBuilder: (context, index) {
                                      final date = sortedDates[index];
                                      final completion = dateMap[date]!;
                                      final tasks = tasksList[
                                          dateMap.keys.toList().indexOf(date)];
                                      double completionRate = tasks.isEmpty
                                          ? 0
                                          : completion / tasks.length;

                                      return ListTile(
                                        title: Text(
                                          DateFormat('dd-MM-yyyy').format(date),
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.sp),
                                        ),
                                        trailing: Container(
                                          width: 30.w,
                                          height: 2.h,
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                255, 202, 202, 202),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: completionRate,
                                            child: Container(
                                              height: 2.h,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(1),
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
                  )
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
                                style: GoogleFonts.plusJakartaSans(
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
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 25.sp),
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
                                        style: GoogleFonts.plusJakartaSans(
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
