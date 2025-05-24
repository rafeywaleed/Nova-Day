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
import 'package:focus_detector/focus_detector.dart';

class ProgressTracker extends StatefulWidget {
  const ProgressTracker();

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

    return FocusDetector(
      onFocusGained: () {
        fetchTaskDataFromFirebase();
        fetchTotalTaskDataFromFirebase();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'DashBoard',
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
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Tooltip(
                message:
                    'This page shows your overall progress.\nTap on any active date in the calendar\nto view task details for that day.',
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
                child: Icon(
                  Icons.info_outline,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: RefreshIndicator(
            color: Colors.blue,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeatmapCalendar(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: selectedDate == null
                        ? Column(
                            children: [
                              _buildProgressIndicators(),
                              _buildTaskCompletionProgress(),
                              SizedBox(height: 10.h),
                            ],
                          )
                        : _buildSelectedDateTasks(),
                  ),
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
          size: 11.w,
          colorTipSize: 3.w,
          monthFontSize: 20.sp,
          borderRadius: 12,
          colorTipCount: 4,
          defaultColor: const Color(0xFFF1F1F1),
          weekTextColor: Colors.black,
          fontSize: 10.sp,
          textColor: Colors.black,
          initDate: currentMonth,
          datasets: dateMap,
          colorMode: ColorMode.color,
          colorsets: {
            1: const Color(0xFFC8E6C9),
            2: const Color(0xFF81C784),
            3: const Color(0xFF4CAF50),
            4: const Color(0xFF388E3C),
          },
          onClick: (date) {
            setState(() {
              if (selectedDate != null &&
                  selectedDate!.year == date.year &&
                  selectedDate!.month == date.month &&
                  selectedDate!.day == date.day) {
                selectedDate = null;
                tasks = [];
              } else {
                selectedDate = date;
                fetchTasksForDate(date).then((fetchedTasks) {
                  setState(() {
                    tasks = fetchedTasks;
                  });
                });
              }
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
            progressColor: const Color(0xFF4A47A3),
            header: "All Time",
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCompletionProgress() {
    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          // boxShadow: const [
          //   BoxShadow(
          //     color: Colors.grey,
          //     spreadRadius: 1,
          //     blurRadius: 5,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Column(
          children: [
            Text(
              "Task Completion Progress",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              height: 40.h,
              decoration: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(12),

                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.grey.withOpacity(0.1),
                //     spreadRadius: 2,
                //     blurRadius: 8,
                //     offset: const Offset(0, 2),
                //   ),
                // ],
              ),
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
                    return Center(
                      child: Text(
                        'No data available.',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                    );
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

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 181, 225, 250),
                          // color: const Color.fromARGB(255, 185, 215, 255),  Nice Blue
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            DateFormat('dd-MM-yyyy').format(date),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Container(
                            width: 30.w,
                            height: 2.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: completionRate,
                              child: Container(
                                height: 2.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(5),
                                ),
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
      ),
    );
  }

  Widget _buildSelectedDateTasks() {
    return FadeIn(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16.sp, color: const Color(0xFF6C63FF)),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = null;
                        tasks = [];
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: Icon(Icons.close,
                          size: 14.sp, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
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
                    progressColor: Colors.black,
                    header: "",
                  ),
                  Text(
                    "${tasks.where((task) => task['status'] == 'completed').length} / ${tasks.length}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              height: 30.h,
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks for this date',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              task['task'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: task['status'] == 'completed'
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                              ),
                              child: Icon(
                                task['status'] == 'completed'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: task['status'] == 'completed'
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFEF5350),
                                size: 18.sp,
                              ),
                            ),
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
      backgroundColor: const Color(0xFFEEEEEE),
      center: Text(
        "${(percent * 100).toStringAsFixed(0)}%",
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      animationDuration: 500,
      footer: Padding(
        padding: EdgeInsets.only(bottom: 1.h),
        child: Text(
          header,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            color: Colors.black54,
          ),
        ),
      ),
      animation: true,
    );
  }
}
