 // void startNetworkListener() {
  //   Connectivity().onConnectivityChanged.listen((connectivityResult) async {
  //     if (connectivityResult != ConnectivityResult.none) {
  //       await uploadTasksIfOffline().then((_) {
  //         print('Tasks uploaded successfully.');
  //       }).catchError((error) {
  //         print('Error uploading tasks: $error');
  //       });
  //     }
  //   });
  // }

  // void scheduleTaskAtTime(int targetHour, int targetMinute) {
  //   DateTime now = DateTime.now();

  //   // Calculate how many hours and minutes are left until the target time
  //   Duration delay;
  //   if (now.hour < targetHour ||
  //       (now.hour == targetHour && now.minute < targetMinute)) {
  //     delay = Duration(
  //       hours: targetHour - now.hour,
  //       minutes: targetMinute - now.minute,
  //       seconds: 00 - now.second,
  //     );
  //   } else {
  //     // If the current time is past the target time, schedule it for the next day
  //     delay = Duration(
  //       hours: (24 - now.hour) + targetHour,
  //       minutes: targetMinute - now.minute,
  //       seconds: 00 - now.second,
  //     );
  //   }

  //   // Register the periodic task
  //   Workmanager().registerPeriodicTask(
  //     'dailyTaskUpload',
  //     'uploadTasksAtFixedTime',
  //     frequency: Duration(hours: 24), // Repeat every 24 hours
  //     initialDelay: delay, // Delay until the specified time
  //   );

  //   // Add a BroadcastReceiver to listen for network connectivity changes
  //   Connectivity().onConnectivityChanged.listen((connectivityResult) {
  //     if (connectivityResult != ConnectivityResult.none) {
  //       // Device is online, trigger the task
  //       uploadTasksIfOffline();
  //     }
  //   });
  // }

  // void checkForNewDay() {
  //   DateTime now = DateTime.now();
  //   DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0);
  //   Duration timeUntilMidnight = tomorrow.difference(now);

  //   Future.delayed(timeUntilMidnight, () async {
  //     await widget.uploadTasksIfOffline();
  //     checkForNewDay(); // Re-schedule for next day
  //   });
  // }

  // void scheduleTaskAtMidnight() {
  //   Workmanager().registerPeriodicTask(
  //     'dailyTaskUpload',
  //     'uploadTasksAtMidnight',
  //     frequency: Duration(hours: 24),
  //     initialDelay: Duration(
  //       hours: 23 - DateTime.now().hour,
  //       minutes: 59 - DateTime.now().minute,
  //       seconds: 59 - DateTime.now().second,
  //     ),
  //   );
  // }

  // void startNetworkListener() {
  //   Connectivity()
  //       .onConnectivityChanged
  //       .listen((List<ConnectivityResult> results) {
  //     // Check if there is a valid connectivity result
  //     if (results.isNotEmpty &&
  //         results.any((result) => result != ConnectivityResult.none)) {
  //       widget.uploadTasksIfOffline().then((_) {
  //         print('Tasks uploaded successfully.');
  //       }).catchError((error) {
  //         print('Error uploading tasks: $error');
  //       });
  //     }
  //   });
  // }


