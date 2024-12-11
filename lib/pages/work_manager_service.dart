// import 'package:hundred_days/pages/notification_helper.dart';
// import 'package:workmanager/workmanager.dart';

// class WorkManagerService {
//   void registerMyTask() async {
//     print("inside register task");
//     // Register my task
//     await Workmanager().registerPeriodicTask(
//       'id1',
//       'show daily notification',
//       frequency: const Duration(days: 1),
//     );
//   }

//   // Init work manager service
//   Future<void> init() async {
//     await Workmanager().initialize(actionTask, isInDebugMode: true);
//     registerMyTask();
//     print("Work Manager init");
//   }

//   void cancelTask(String id) {
//     Workmanager().cancelAll();
//   }
// }

// @pragma('vm-entry-point')
// void actionTask() {
//   // Show notification
//   Workmanager().executeTask((taskName, inputData) async {
//     await LocalNotificationService.scheduleDailyNotification();
//     return Future.value(true);
//   });
// }

