import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hundred_days/cloud/admin_notifiy.dart';
import 'package:hundred_days/pages/add_notes.dart';
import 'package:hundred_days/pages/add_tasks.dart';
import 'package:hundred_days/pages/ads_page.dart';
import 'package:hundred_days/pages/notes_page.dart';
import 'package:hundred_days/pages/notification_settings.dart';
import 'package:hundred_days/pages/record_view.dart';
import 'package:hundred_days/pages/settings.dart';
import 'package:hundred_days/pages/splash_screen.dart';
import 'package:hundred_days/utils/dialog_box.dart';
import 'package:hundred_days/utils/loader.dart';
import 'package:iconly/iconly.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth/firebase_fun.dart';
import 'cloud/firebase_api.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _logoAnimationController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 8000),
  );
  List<Map<String, dynamic>> defaultTasks = [];
  List<Map<String, dynamic>> additionalTasks = [];
  String? userEmail;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;

  void _initAnimationController() {
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 5000),
    );
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await InAppUpdate.checkForUpdate();

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      _showUpdateDialog(updateInfo);
    }
  }

  Future<void> _showUpdateDialog(AppUpdateInfo updateInfo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Update Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A new version of the app is available. Please update to continue using the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Later'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _downloadUpdate(updateInfo);
                    },
                    child: const Text('Update'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadUpdate(AppUpdateInfo updateInfo) async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
      print('Update successful');
    } catch (e) {
      print('Update failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    loadUserEmail();
    loadDailyTasks();
    fetchAdditionalTasks();
    printSt();
    resetTaskAnyway();
    checkAndUpdateTasks();
    startNetworkListener();
    WidgetsBinding.instance.addObserver(this);
    _initAnimationController();
    _animate();
    _fetchAdData();
    _checkPremium();
    FirebaseApi().initNotification();
  }

  final FirebaseService _firebaseService = FirebaseService();
  bool _isPremium = false;
  Future<void> _checkPremium() async {
    final userData = await _firebaseService.fetchUserData();
    print(userData['isPremium']);
    setState(() {
      _isPremium = userData['isPremium'];
    });
  }

  void _animate() async {
    await _logoAnimationController.forward();
    await Future.delayed(Duration(seconds: 3));
    _logoAnimationController.reset();
    _animate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoAnimationController.dispose();

    super.dispose();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isBannerAdshown = true;
  Future<void> _fetchAdData() async {
    final bannerAds =
        await _firestore.collection('adminPanel').doc('bannerAds').get();
    final dialogAds =
        await _firestore.collection('adminPanel').doc('dialogAds').get();
    final notificationAds =
        await _firestore.collection('adminPanel').doc('notificationAds').get();

    if (bannerAds.exists) {
      final showBannerAds = bannerAds.get('showBannerAds');
      final bannerAdName = bannerAds.get('bannerAdName');
      final bannerAdLine = bannerAds.get('bannerAdLine');
      final bannerAdURL = bannerAds.get('bannerAdURL');
      final bannerImgURL = bannerAds.get('bannerImgURL');

      if (showBannerAds) {
        setState(() {
          _showBannerAd = true;
          _bannerAdName = bannerAdName;
          _bannerAdLine = bannerAdLine;
          _bannerAdURL = bannerAdURL;
          _bannerImgURL = bannerImgURL;
        });
      } else {
        _showBannerAd = false;
      }
    }

    if (dialogAds.exists) {
      final showDialogAds = dialogAds.get('showDialogAds');
      final dialogAdName = dialogAds.get('dialogAdName');
      final dialogAdLine = dialogAds.get('dialogAdLine');
      final dialogAdURL = dialogAds.get('dialogAdURL');
      final dialogImgURL = dialogAds.get('dialogImgURL');

      if (showDialogAds) {
        _showDialogAd(
            context, dialogAdName, dialogAdLine, dialogAdURL, dialogImgURL);
      }
    }
  }

  bool _showBannerAd = false;
  String _bannerAdName = '';
  String _bannerAdLine = '';
  String _bannerAdURL = '';
  String _bannerImgURL = '';

  void _showDialogAd(BuildContext context, String dialogAdName,
      String dialogAdLine, String dialogAdURL, String dialogImgURL) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          //insetPadding: EdgeInsets.all(20),
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    dialogImgURL,
                    fit: BoxFit.cover,
                    // width: 200,
                    // height: 120,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return Center(child: PLoader());
                      }
                    },
                  ),
                ),
                // SizedBox(height: 16),
                Text(
                  dialogAdName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                // Dialog Description (Ad Line)
                Text(
                  dialogAdLine,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _launchURL(dialogAdURL);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                        child: Text('Visit',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),

                      SizedBox(height: 16),
                      // Close Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                        child: Text('Close',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchURL(String url) async {
    await launch(url);
  }

  Widget showBannerAd(BuildContext context, String bannerAdName,
      String bannerAdline, String bannerAdURL, String bannerImgURL) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width * 0.85, // Slightly larger width
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () {
          _launchURL(bannerAdURL);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ad image with loading indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // Fallback Image or Placeholder when the image can't be loaded
                  Image.network(
                    bannerImgURL,
                    fit: BoxFit.cover,
                    width: 100, // Fixed width for image
                    height: 60, // Fixed height for image
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return PLoader();
                      }
                    },
                    errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) {
                      // Placeholder image in case of an error (could be a default image)
                      return PLoader();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Name
                  Text(
                    bannerAdName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Banner description/line with overflow handling
                  Text(
                    bannerAdline,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.grey[700]),
                onPressed: () {
                  setState(() {
                    _showBannerAd = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> checkAndUpdateTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    String? storedDate = prefs.getString('tDate');
    print("inside check and Update");

    if (storedDate == null || storedDate != currentDate) {
      print("entered if condition");
      await saveProgress();
      print("save progress complete");
      await resetTasks();
      print("task's reset");
      await prefs.setString('tDate', currentDate);
      print(prefs.getString('tDate'));
    } else {
      print("date matched");
      loadDailyTasks();
    }
  }

  Future<void> resetTaskAnyway() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? storedData = prefs.getString('tDate');
    print('Currently stored date: $storedData'); // Debugging output

    String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    if (storedData == null || storedData != todayDate) {
      await resetTasks();
      await prefs.setString('tDate', todayDate);
      print('Saved new date: $todayDate'); // Debugging output
    }
  }

  Future<void> resetTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('defaultTasks');

    if (taskJsonList != null) {
      List<Map<String, dynamic>> tasks = taskJsonList.map((taskJson) {
        return Map<String, dynamic>.from(jsonDecode(taskJson));
      }).toList();

      List<Map<String, dynamic>> updatedTasks = tasks.map((task) {
        return {
          'task': task['task'], // Use 'task' instead of 'name'
          'completed': false,
        };
      }).toList();

      // Convert the updated tasks back to JSON and save them
      List<String> updatedTaskJsonList = updatedTasks.map((task) {
        return jsonEncode(task);
      }).toList();

      await prefs.setStringList('defaultTasks', updatedTaskJsonList);
      print("All tasks marked as incomplete.");

      setState(() {
        defaultTasks = updatedTasks;
      });
    } else {
      print("No tasks found to reset.");
    }
  }

  Future<void> saveNormalProgress() async {
    String? userId = auth.currentUser?.uid;
    String? userEmail = auth.currentUser?.email;
    if (userId != null && userEmail != null) {
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      DocumentReference taskRecordDoc = firestore
          .collection('taskRecord')
          .doc(userEmail)
          .collection('records')
          .doc(today);

      List<Map<String, dynamic>> taskProgress = defaultTasks
          .map((task) => {
                'task': task['task'],
                'status': task['completed'] ? 'completed' : 'incomplete'
              })
          .toList();

      int totalTasks = taskProgress.length;
      int completedTasks =
          taskProgress.where((task) => task['status'] == 'completed').length;
      double overallCompletion =
          totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

      await taskRecordDoc.set({
        'tasks': taskProgress,
        'overallCompletion': '$completedTasks/$totalTasks',
        'date': today,
      });
    }
  }

  Future<void> saveProgress() async {
    String? userId = auth.currentUser?.uid;
    String? userEmail = auth.currentUser?.email;
    print("inside saveProgress");
    if (userId != null && userEmail != null) {
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      List<Map<String, dynamic>> taskProgress = defaultTasks
          .map((task) => {
                'task': task['task'],
                'status': task['completed'] ? 'completed' : 'incomplete'
              })
          .toList();

      int totalTasks = taskProgress.length;
      int completedTasks =
          taskProgress.where((task) => task['status'] == 'completed').length;

      ConnectivityResult connectivityResult =
          (await Connectivity().checkConnectivity()) as ConnectivityResult;

      if (connectivityResult == ConnectivityResult.none) {
        // Device is offline, save data to be uploaded later
        await saveToBeUploaded(today, taskProgress, completedTasks, totalTasks);
      } else {
        // Device is online, save data directly to Firebase
        await uploadToFirebase(today, taskProgress, completedTasks, totalTasks);
      }
    }
  }

// Function to save data locally when offline
  Future<void> saveToBeUploaded(String date, List<Map<String, dynamic>> tasks,
      int completedTasks, int totalTasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> toBeUploaded =
        prefs.getStringList('toBeUploaded') ?? []; // Existing data

    Map<String, dynamic> data = {
      'date': date,
      'tasks': tasks,
      'overallCompletion': '$completedTasks /$totalTasks',
    };

    toBeUploaded.add(jsonEncode(data));
    await prefs.setStringList('toBeUploaded', toBeUploaded);
  }

// Function to upload data directly to Firebase
  Future<void> uploadToFirebase(String date, List<Map<String, dynamic>> tasks,
      int completedTasks, int totalTasks) async {
    DocumentReference taskRecordDoc = firestore
        .collection('taskRecord')
        .doc(userEmail)
        .collection('records')
        .doc(date);

    await taskRecordDoc.set({
      'tasks': tasks,
      'overallCompletion': '$completedTasks/$totalTasks',
      'date': date,
    });
  }

// Function to upload saved tasks when back online
  Future<void> uploadTasksIfOffline() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> toBeUploaded = prefs.getStringList('toBeUploaded') ?? [];

    for (String record in toBeUploaded) {
      Map<String, dynamic> data = jsonDecode(record);
      await uploadToFirebase(
        data['date'],
        List<Map<String, dynamic>>.from(data['tasks']),
        int.parse(data['overallCompletion'].split('/')[0]),
        int.parse(data['overallCompletion'].split('/')[1]),
      );
    }

    await prefs.remove('toBeUploaded');
  }

// Start network listener to handle offline data upload
  void startNetworkListener() {
    Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      if (connectivityResult != ConnectivityResult.none) {
        await uploadTasksIfOffline().then((_) {
          print('Tasks uploaded successfully.');
        }).catchError((error) {
          print('Error uploading tasks: $error');
        });
      }
    });
  }

  Future<void> loadUserEmail() async {
    User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    }
  }

  Future<void> printSt() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs.getStringList('dailyTasks'));

    print(prefs.getString('tDate'));
  }

  Future<void> loadDailyTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? savedTasksJson = prefs.getStringList('defaultTasks') ?? [];
    List<Map<String, dynamic>> savedTasks = [];

    if (savedTasksJson.isNotEmpty) {
      savedTasks = savedTasksJson
          .map((taskJson) => jsonDecode(taskJson))
          .toList()
          .cast<Map<String, dynamic>>();
      print('Daily tasks fetched from shredPrefrnces');
    } else {
      // If no tasks are found in SharedPreferences, fetch from Firebase
      await fetchDailyTasksFromFirebase();
    }

    // Load the task names (task titles) for the day from SharedPreferences
    List<String>? dailyTasks = prefs.getStringList('dailyTasks') ?? [];

    // Check if dailyTasks is not empty
    if (dailyTasks.isNotEmpty) {
      // Prepare a new list for updated defaultTasks
      List<Map<String, dynamic>> newDefaultTasks = [];

      // Iterate through the dailyTasks and merge with savedTasks to retain their status
      for (String taskName in dailyTasks) {
        // Check if the task already exists in savedTasks
        Map<String, dynamic>? existingTask = savedTasks.firstWhere(
          (task) => task['task'] == taskName,
          orElse: () => {},
        );

        if (existingTask.isNotEmpty) {
          // If the task exists, retain its status
          newDefaultTasks.add(existingTask);
        } else {
          // If it's a new task, add it as incomplete
          newDefaultTasks.add({'task': taskName, 'completed': false});
        }
      }

      // Update the defaultTasks in the state
      setState(() {
        defaultTasks = newDefaultTasks;
      });

      // Save updated defaultTasks back to SharedPreferences
      await saveTasksToSharedPreferences(defaultTasks);
    }
  }

  Future<void> fetchDailyTasksFromFirebase() async {
    try {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentSnapshot userTasksSnapshot =
            await firestore.collection('dailyTasks').doc(userEmail).get();

        if (userTasksSnapshot.exists) {
          var data = userTasksSnapshot.data() as Map<String, dynamic>;
          List<dynamic> firebaseTasks = data['tasks'] ?? [];

          List<Map<String, dynamic>> fetchedTasks = firebaseTasks.map((task) {
            return {
              'task': task['task'],
              'completed': task['completed'],
            };
          }).toList();

          print('daily tasks fetched from firebase');
          // Save the tasks fetched from Firebase to SharedPreferences
          await saveTasksToSharedPreferences(fetchedTasks);

          // Update the defaultTasks with the fetched data
          setState(() {
            defaultTasks = fetchedTasks;
          });
        } else {
          print("No tasks found in Firebase.");
        }
      }
    } catch (e) {
      print("Error fetching tasks from Firebase: $e");
    }
  }

  void markTaskAsCompleted(String taskName) {
    Map<String, dynamic>? task = defaultTasks.firstWhere(
      (task) => task['task'] == taskName,
      orElse: () => {},
    );

    if (task.isNotEmpty) {
      setState(() {
        task['completed'] = true;

        saveTasksToSharedPreferences(defaultTasks);
      });
    }
  }

  Future<void> deleteTask(String taskName) async {
    print("Attempting to delete task: $taskName");

    print("Current defaultTasks: $defaultTasks");

    Map<String, dynamic>? task = defaultTasks.firstWhere(
      (task) => task['task'] == taskName,
      orElse: () => {},
    );

    if (task.isNotEmpty) {
      setState(() async {
        // Remove the task from the defaultTasks
        defaultTasks.removeWhere((element) => element['task'] == taskName);

        print("Updated defaultTasks: $defaultTasks");

        saveTasksToSharedPreferences(defaultTasks);

        await printSharedPreferencesData();
      });

      // Remove the task from the dailyTasks list in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? dailyTasks = prefs.getStringList('dailyTasks');
      if (dailyTasks != null) {
        print("Current dailyTasks: $dailyTasks");
        dailyTasks.remove(taskName);
        await prefs.setStringList('dailyTasks', dailyTasks);
        print("Updated dailyTasks: $dailyTasks");
        print("daily task removed from sharedPreferences");
      }
    } else {
      print("Task not found in defaultTasks");
    }
  }

  Future<void> printSharedPreferencesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedDefaultTasks = prefs.getStringList('defaultTasks');
    List<String>? savedDailyTasks = prefs.getStringList('dailyTasks');

    print("Saved defaultTasks in SharedPreferences: $savedDefaultTasks");
    print("Saved dailyTasks in SharedPreferences: $savedDailyTasks");
  }

  Future<void> saveTasksToSharedPreferences(
      List<Map<String, dynamic>> defaultTasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      List<String> updatedDefaultTasksJson =
          defaultTasks.map((task) => jsonEncode(task)).toList();

      await prefs.setStringList('defaultTasks', updatedDefaultTasksJson);
    } catch (e) {
      print('Error saving tasks to SharedPreferences: $e');
    }
  }

  Future<void> printDefaultTasksWithStatus() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedTasksJson = prefs.getStringList('defaultTasks') ?? [];

    if (savedTasksJson.isNotEmpty) {
      try {
        // Print each task with its status
        for (String taskJson in savedTasksJson) {
          Map<String, dynamic> task = jsonDecode(taskJson);
          print('Task: ${task['task']}, Completed: ${task['completed']}');
        }
      } catch (e) {
        print('Error decoding JSON: $e');
      }
    } else {
      print('No tasks found in SharedPreferences.');
    }
  }

  bool isLoading = true;

  Future<void> _handleRefresh() async {
    print("refreshing");
    setState(() {
      isLoading = true;
    });
    loadUserEmail();
    loadDailyTasks();
    printSt();
    resetTaskAnyway();
    checkAndUpdateTasks();
    fetchAdditionalTasks();
    loadDailyTasks();
    saveNormalProgress();
    _initAnimationController();
    _animate();
    _fetchAdData();
    _checkPremium();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveAdditionalTasksToSharedPreferences(
      List<Map<String, dynamic>> additionalTasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskList =
        additionalTasks.map((task) => jsonEncode(task)).toList();
    await prefs.setStringList('additionalTasks', taskList);
    print('task saved in sharedPref\n ${taskList}');
  }

  Future<void> saveAdditionalTasksToFirebase(
      List<Map<String, dynamic>> additionalTasks) async {
    String? userEmail = auth.currentUser?.email;
    if (userEmail != null) {
      DocumentReference taskRecordDoc = firestore
          .collection('taskRecord')
          .doc(userEmail)
          .collection('addTasks')
          .doc('tasks');

      await taskRecordDoc.set({
        'tasks': additionalTasks,
      });
    }
    print("task saved in firebase");
  }

  Future<void> createNewAdditionalTask(String taskName) async {
    Map<String, dynamic> newTask = {
      'task': taskName,
      'status': 'incomplete',
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('additionalTasks');
    List<Map<String, dynamic>> tasks = taskJsonList != null
        ? taskJsonList
            .map((taskJson) => jsonDecode(taskJson))
            .toList()
            .cast<Map<String, dynamic>>()
        : [];

    tasks.add(newTask);
    print('New additional task created !!');

    await saveAdditionalTasksToSharedPreferences(tasks);

    await saveAdditionalTasksToFirebase(tasks);
  }

  Future<void> deleteAdditionalTask(String taskName) async {
    // Fetch existing tasks
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('additionalTasks');
    if (taskJsonList != null) {
      List<Map<String, dynamic>> tasks = taskJsonList
          .map((taskJson) => jsonDecode(taskJson))
          .toList()
          .cast<Map<String, dynamic>>();

      // Remove task
      tasks.removeWhere((task) => task['task'] == taskName);
      print('Additional tasks removed');

      await saveAdditionalTasksToSharedPreferences(tasks);
      await saveAdditionalTasksToFirebase(tasks);
    }
  }

  Future<void> updateAdditionalTask(String taskName, bool completed) async {
    // Fetch existing tasks
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('additionalTasks');
    if (taskJsonList != null) {
      List<Map<String, dynamic>> tasks = taskJsonList
          .map((taskJson) => jsonDecode(taskJson))
          .toList()
          .cast<Map<String, dynamic>>();

      // Update task status
      for (var task in tasks) {
        if (task['task'] == taskName) {
          task['status'] = completed ? 'complete' : 'incomplete';
          print('Additional tasks updated \n ${tasks}');
        }
      }

      // Save updated tasks
      await saveAdditionalTasksToSharedPreferences(tasks);
      await saveAdditionalTasksToFirebase(tasks);
    }
  }

  Future<void> fetchAdditionalTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskJsonList = prefs.getStringList('additionalTasks');

    if (taskJsonList == null || taskJsonList.isEmpty) {
      String? userEmail = auth.currentUser?.email;
      if (userEmail != null) {
        DocumentReference taskRecordDoc = firestore
            .collection('taskRecord')
            .doc(userEmail)
            .collection('addTasks')
            .doc('tasks');

        DocumentSnapshot<Object?> querySnapshot = await taskRecordDoc.get();
        print('Additional tasks fetched from firebase');
        if (querySnapshot.exists) {
          List<Map<String, dynamic>> tasks =
              List<Map<String, dynamic>>.from(querySnapshot.get('tasks'));
          List<String> taskJsonList =
              tasks.map((task) => jsonEncode(task)).toList();
          await prefs.setStringList('additionalTasks', taskJsonList);
          setState(() {
            additionalTasks = tasks; // Update the additionalTasks list here
          });
        }
      }
    } else {
      setState(() {
        additionalTasks = taskJsonList
            .map((taskJson) => jsonDecode(taskJson))
            .toList()
            .cast<Map<String, dynamic>>();
      });
    }
    print('Additional tasks fetched from shredPrefrnces');
  }

  @override
  Widget build(BuildContext context) {
    int totalTasks = defaultTasks.length;
    int completedTasks =
        defaultTasks.where((task) => task['completed'] == true).length;
    double taskCompletion = totalTasks > 0 ? completedTasks / totalTasks : 0;
    int daysLeft = DateTime(2025, 1, 1).difference(DateTime.now()).inDays;

    return WillPopScope(
      onWillPop: () async {
        // Show a dialog to confirm if the user wants to exit the app
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Exit'),
            content: Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                child: Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                NavigationRail(
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: AnimatedBuilder(
                        animation: _logoAnimationController,
                        builder: (context, child) {
                          return Roulette(
                            // delay: Duration(milliseconds: 3000),
                            duration: Duration(milliseconds: 3000),
                            infinite: true,
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              scale: 3.w,
                            ),
                          );
                        }),
                  ),
                  labelType: labelType,
                  useIndicator: false,
                  indicatorShape: Border.all(width: 20),
                  indicatorColor: Colors.transparent,
                  minWidth: 15.w,
                  groupAlignment: 0,
                  backgroundColor:
                      const Color.fromARGB(255, 127, 127, 127).withOpacity(0.1),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) {
                    saveNormalProgress();
                    setState(() {
                      _selectedIndex = value;
                    });
                  },
                  destinations: [
                    NavigationRailDestination(
                      icon: _selectedIndex == 0
                          ? Icon(IconlyLight.home,
                              color: Colors.blue, size: 12.w)
                          : Icon(IconlyBroken.home, size: 9.w),
                      label: Text(
                        'Home',
                        style: GoogleFonts.sourceCodePro(),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: _selectedIndex == 1
                          ? Icon(IconlyLight.graph,
                              color: Colors.blue, size: 12.w)
                          : Icon(IconlyBroken.graph, size: 9.w),
                      label: Text(
                        'Record',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: _selectedIndex == 2
                          ? Icon(IconlyLight.setting,
                              color: Colors.blue, size: 12.w)
                          : Icon(IconlyBroken.setting, size: 9.w),
                      label: Text(
                        'Settings',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: _selectedIndex == 3
                          ? Icon(IconlyLight.paper,
                              color: Colors.blue, size: 12.w)
                          : Icon(IconlyBroken.paper, size: 9.w),
                      label: Text(
                        'Notes',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
            if (_isPremium == false)
              if (_showBannerAd)
                Positioned(
                  bottom: 5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: showBannerAd(
                      context,
                      _bannerAdName,
                      _bannerAdLine,
                      _bannerAdURL,
                      _bannerImgURL,
                    ),
                  ),
                ),
          ],
        ),
        // floatingActionButton: _selectedIndex != 0
        //     ? null
        //     : SafeArea(
        //         child: FloatingActionButton(
        //           onPressed: () {
        //             final _controller = TextEditingController();
        //             showDialog(
        //               context: context,
        //               builder: (context) {
        //                 return DialogBox(
        //                   Controller: _controller,
        //                   onSave: () {
        //                     if (_controller.text.isNotEmpty) {
        //                       setState(() {
        //                         additionalTasks.add({
        //                           'task': _controller.text,
        //                           'completed': false
        //                         });
        //                       });
        //                       saveAdditionalTasksToSharedPreferences(
        //                           additionalTasks);
        //                       saveAdditionalTasksToFirebase(additionalTasks);
        //                       Navigator.of(context).pop();
        //                     }
        //                   },
        //                   onCancel: () {
        //                     Navigator.of(context).pop();
        //                   },
        //                 );
        //               },
        //             );
        //           },
        //           child: Icon(Icons.add),
        //         ),
        //       ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return ProgressTracker();
      case 2:
        return UserSettingsPage();
      case 3:
        return NotesListPage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    // fetchAdditionalTasks();
    int totalTasks = defaultTasks.length;
    int completedTasks =
        defaultTasks.where((task) => task['completed'] == true).length;
    double taskCompletion = totalTasks > 0 ? completedTasks / totalTasks : 0;
    int daysLeft = DateTime(DateTime.now().year + 1, 1, 1)
        .difference(DateTime.now())
        .inDays;

    return RefreshIndicator(
      color: Colors.blue,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: FadeInDown(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 800),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProgressTracker()),
                    );
                  },
                  child: Center(
                    child: Container(
                      height: 15.h,
                      width: 75.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            spreadRadius: 1,
                            color: Colors.grey,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(3.w), // Reduced padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flash(
                                  delay: Duration(milliseconds: 800),
                                  duration: Duration(milliseconds: 800),
                                  child: Text(
                                    '$daysLeft',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 8.w,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Text(
                                  'days left for new year',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 3.w,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            // Use Flexible here to prevent overflow in larger screens
                            Flexible(
                              child: CircularPercentIndicator(
                                radius: 10.w,
                                lineWidth: 8.0,
                                percent: taskCompletion,
                                center: Text(
                                  "${(taskCompletion * 100).toStringAsFixed(0)}%",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 5.w,
                                    color: Colors.blue,
                                  ),
                                ),
                                progressColor: Colors.green,
                                backgroundColor: Colors.grey[300]!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Daily Tasks:",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 5.w,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            Container(
              height: 40.h,
              child: defaultTasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks for today.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 4.w,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : SafeArea(
                      bottom: true,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: defaultTasks.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> task = defaultTasks[index];
                          return TaskCard(
                            task: task,
                            // onDelete: () {
                            //   // setState(() {
                            //   //   defaultTasks.removeAt(index);
                            //   // });
                            //   // deleteTask(task['task']);
                            //   // saveNormalProgress();
                            // },
                            isDailyTask: true,
                            onChanged: (value) {
                              setState(() {
                                defaultTasks[index]['completed'] = value!;
                                saveTasksToSharedPreferences(defaultTasks);
                                saveProgress();
                                saveNormalProgress();
                              });
                            },
                          );
                        },
                      ),
                    ),
            ),
            // Center(
            //   child: ElevatedButton(
            //     style: ButtonStyle(
            //       backgroundColor: MaterialStateProperty.all(Colors.white),
            //       shape: MaterialStateProperty.all(
            //         RoundedRectangleBorder(
            //           borderRadius:
            //               BorderRadius.circular(16), // more rounded corners
            //           side: BorderSide(
            //               color: Colors.grey.shade200,
            //               width: 1), // subtle border
            //         ),
            //       ),
            //       elevation: MaterialStateProperty.all(5), // subtle shadow
            //     ),
            //     child: Icon(
            //       Icons.add,
            //       size: 20.sp, // Increased icon size for better visibility
            //       color: Colors.blue,
            //     ),
            //     onPressed: () {
            //       // Show the dialog informing user to add tasks
            //       showDialog(
            //         context: context,
            //         builder: (context) {
            //           return AlertDialog(
            //             backgroundColor: Colors.white,
            //             shape: RoundedRectangleBorder(
            //               borderRadius: BorderRadius.circular(12),
            //             ),
            //             title: Row(
            //               children: [
            //                 Icon(Icons.add_task, color: Colors.blue, size: 30),
            //                 SizedBox(width: 10),
            //                 Text(
            //                   'Daily Tasks',
            //                   style: GoogleFonts.plusJakartaSans(
            //                     fontWeight: FontWeight.w600,
            //                     fontSize: 16.sp,
            //                     color: Colors.black87,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //             content: Padding(
            //               padding: EdgeInsets.symmetric(vertical: 8),
            //               child: Text(
            //                 'You need to add a daily task from the "Edit Tasks" page in settings. These tasks should be completed every day.',
            //                 style: GoogleFonts.plusJakartaSans(
            //                   fontSize: 12.sp,
            //                   color: Colors.black54,
            //                 ),
            //                 textAlign: TextAlign.start,
            //               ),
            //             ),
            //             actions: <Widget>[
            //               TextButton(
            //                 style: TextButton.styleFrom(
            //                   foregroundColor: Colors.blue,
            //                   backgroundColor: Colors.white,
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(8),
            //                   ),
            //                   padding: EdgeInsets.symmetric(
            //                       vertical: 10, horizontal: 20),
            //                 ),
            //                 child: Text(
            //                   'Go to Edit Tasks',
            //                   style: GoogleFonts.plusJakartaSans(
            //                     fontSize: 14.sp,
            //                     fontWeight: FontWeight.w500,
            //                   ),
            //                 ),
            //                 onPressed: () {
            //                   Navigator.of(context).pop(); // Close the dialog
            //                   Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                       builder: (context) => AddTasks(
            //                           input:
            //                               1), // Assuming AddTasks is the page where the user can edit tasks
            //                     ),
            //                   );
            //                 },
            //               ),
            //             ],
            //           );
            //         },
            //       );
            //     },
            //   ),
            // ),

            SizedBox(height: 2.h),
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddNotePage(),
                    ),
                  );
                },
                child: Text('button')),
            Text(
              "Additional Tasks:",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 5.w,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            // TextButton(
            //     onPressed: () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) => NotificationSettings()),
            //       );
            //     },
            //     child: Text("Notification Settings")),
            if (additionalTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text(
                    'No additional tasks available.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 4.w,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: additionalTasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(
                    task: additionalTasks[index],
                    onDelete: () {
                      String taskName = additionalTasks[index]['task'];
                      setState(() {
                        additionalTasks
                            .removeWhere((task) => task['task'] == taskName);
                      });
                      deleteAdditionalTask(taskName);
                    },
                    isDailyTask: false,
                    onChanged: (value) {
                      setState(() {
                        additionalTasks[index]['completed'] = value!;
                      });
                      updateAdditionalTask(
                          additionalTasks[index]['task'], value!);
                    },
                  );
                },
              ),
            SizedBox(
              height: 1.h,
            ),
            Center(
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1), // subtle border
                    ),
                  ),
                  // uniform padding
                  elevation: MaterialStateProperty.all(5), // subtle shadow
                ),
                child: Icon(
                  Icons.add,
                  size: 20.sp, // Increased icon size for better visibility
                  color: Colors.blue,
                ),
                onPressed: () {
                  final _controller = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return DialogBox(
                        Controller: _controller,
                        onSave: () {
                          if (_controller.text.isNotEmpty) {
                            setState(() {
                              additionalTasks.add({
                                'task': _controller.text,
                                'completed': false
                              });
                            });
                            saveAdditionalTasksToSharedPreferences(
                                additionalTasks);
                            saveAdditionalTasksToFirebase(additionalTasks);
                            Navigator.of(context).pop();
                          }
                        },
                        onCancel: () {
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(
              height: 10.h,
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onDelete; // Make onDelete optional
  final bool isDismissible; // New parameter to control dismissibility
  final bool isDailyTask; // New parameter to indicate if it's a daily task

  const TaskCard({
    required this.task,
    required this.onChanged,
    this.onDelete, // Optional onDelete callback
    this.isDismissible = true, // Default to true
    this.isDailyTask = false, // Default to false
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isDismissible
        ? Dismissible(
            key: Key(task['task'] +
                task['completed'].toString()), // Use a unique key
            direction: DismissDirection.startToEnd,
            confirmDismiss: (direction) async {
              // Show alert dialog if it's a daily task
              if (isDailyTask) {
                return await _showDeleteAlertDialog(context);
              } else {
                // Allow deletion for additional tasks
                onDelete?.call();
                return true;
              }
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(IconlyLight.delete, color: Colors.white),
            ),
            child: _buildTaskCard(),
          )
        : _buildTaskCard(); // Just return the card without dismissible
  }

  Widget _buildTaskCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: CheckboxListTile(
        title: Text(
          task['task'],
          style: GoogleFonts.plusJakartaSans(
            decoration: task['completed'] == true
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: task['completed'] == true ? Colors.grey : Colors.black,
          ),
        ),
        value: task['completed'] ?? false,
        onChanged: onChanged,
      ),
    );
  }

  Future<bool> _showDeleteAlertDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 30), // Warning icon
              SizedBox(width: 10),
              Text(
                'Cannot Delete Task',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Daily tasks cannot be deleted. You can edit tasks from the settings.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp, // Responsive font size
                color: Colors.black54, // Lighter color for the content
              ),
              textAlign: TextAlign.start, // Center align for a balanced look
            ),
          ),
          actions: <Widget>[
            // Add some spacing between the buttons
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
              child: Text(
                'Edit Tasks',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTasks(input: 1),
                  ),
                );
              },
            ),
            //SizedBox(width: 10),
            // TextButton(
            //   style: TextButton.styleFrom(
            //     foregroundColor: Colors.blue,
            //     backgroundColor: Colors.white, // Primary action button color
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     padding: EdgeInsets.symmetric(
            //         vertical: 10, horizontal: 20), // Subtle padding
            //   ),
            //   child: Text(
            //     'OK',
            //     style: GoogleFonts.plusJakartaSans(
            //       fontSize: 14.sp, // Keep the text responsive
            //       fontWeight:
            //           FontWeight.w500, // Slightly lighter text for the button
            //     ),
            //   ),
            //   onPressed: () {
            //     Navigator.of(context).pop(); // Close the dialog
            //   },
            // ),
          ],
        );
      },
    );
    return false;
  }
}
