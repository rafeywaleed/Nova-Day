import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class ProgressTracker extends StatefulWidget {
  const ProgressTracker({super.key});

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker> {
  Map<DateTime, int> dateMap = {};
  Random random = Random();
  // Define the start and end dates
  DateTime startDate = DateTime(2024, 1, 1);
  DateTime endDate = DateTime(2024, 12, 31);

  int selectedYear = DateTime.now().year; // Initialize with current year
  int selectedMonth = DateTime.now().month; // Initialize with current month

  void addDateMap() {
    for (DateTime date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      // Randomly decide whether to skip this date
      bool shouldAdd = random.nextBool(); // 50% chance to skip or add
      if (shouldAdd) {
        // Assign a random value between 1 and 3 (inclusive)
        int randomValue = random.nextInt(3) + 1;
        dateMap[date] = randomValue;
      }
    }
  }

  @override
  void initState() {
    addDateMap();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: const Color(0xff0F2027),
        title: Text('Progress Record'),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMonth--;
                      if (selectedMonth < 1) {
                        selectedMonth = 12;
                        selectedYear--;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_back_ios),
                ),
                Text(
                  '${getMonthName(selectedMonth)} $selectedYear',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMonth++;
                      if (selectedMonth > 12) {
                        selectedMonth = 1;
                        selectedYear++;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HeatMap(
                  datasets: dateMap,
                  startDate: DateTime(selectedYear, selectedMonth, 1),
                  endDate: DateTime(selectedYear, selectedMonth + 1, 0),
                  textColor: Colors.black,
                  defaultColor: const Color(0xff0F2027),
                  colorMode: ColorMode.opacity,
                  showText: false,
                  scrollable: false, // Disable scrolling
                  showColorTip: false,
                  colorsets: {
                    1: const Color(0xffFF375F),
                    2: const Color(0xffED1147).withOpacity(0.80),
                    3: const Color(0xffA8093A).withOpacity(0.70),
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}