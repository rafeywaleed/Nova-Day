// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:hundred_days/pages/every_6hour.dart';

// void scheduleNotification() async {
//   final now = DateTime.now();
//   DateTime scheduledTime = DateTime(now.year, now.month, now.day, 18, 0); // 6 PM

//   // If 6 PM has already passed today, schedule it for tomorrow
//   if (now.isAfter(scheduledTime)) {
//     scheduledTime = scheduledTime.add(Duration(days: 1));
//   }

//   // Schedule the alarm
//   await AndroidAlarmManager.oneShotAt(
//     scheduledTime,
//     0,
//     callback,
//     exact: true,
//     wakeup: true,
//   );
// }
