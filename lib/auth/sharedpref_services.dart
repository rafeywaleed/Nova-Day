// import 'dart:convert';

// import 'package:shared_preferences/shared_preferences.dart';

// Future<void> saveTasksToSharedPreferences() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   List<String> tasks = defaultTasks.map((task) => jsonEncode(task)).toList();
//   prefs.setStringList('defaultTasks', tasks);
// }

// Future<void> loadTasksFromSharedPreferences() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   List<String>? tasks = prefs.getStringList('defaultTasks');
//   if (tasks != null) {
//     setState(() {
//       defaultTasks = tasks
//           .map((taskString) => jsonDecode(taskString))
//           .map((taskMap) => {
//                 'task': taskMap['task'],
//                 'completed': taskMap['completed'],
//               })
//           .toList();
//     });
//   }
// }
