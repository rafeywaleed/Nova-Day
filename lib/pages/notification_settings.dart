import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../homescreen.dart';

class NotificationSettings extends StatefulWidget {
  final int intro;
  const NotificationSettings({super.key, required this.intro});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool notificationsEnabled = true;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<TimeOfDay> notificationTimes = [
    const TimeOfDay(hour: 6, minute: 30),
    const TimeOfDay(hour: 12, minute: 30)
  ];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    loadNotificationState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _notificationsPlugin.initialize(initializationSettings);

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders_channel', // id
      'Task Reminders', // title
      description: 'Daily task reminder notifications', // description
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      notificationTimes = _getStoredTimes(prefs, 'notificationTimes') ??
          [
            const TimeOfDay(hour: 6, minute: 30),
            const TimeOfDay(hour: 12, minute: 30)
          ];
    });

    if (notificationsEnabled) {
      for (int i = 0; i < notificationTimes.length; i++) {
        await _scheduleNotification(i, 'Task Reminder ',
            'Have you started your tasks for today?', notificationTimes[i]);
      }
    }
  }

  List<TimeOfDay>? _getStoredTimes(SharedPreferences prefs, String key) {
    if (!prefs.containsKey(key)) return null;
    final storedTimes = prefs.getStringList(key);
    if (storedTimes == null) return null;
    return storedTimes
        .map((time) => TimeOfDay(
            hour: int.parse(time.split(':')[0]),
            minute: int.parse(time.split(':')[1])))
        .toList();
  }

  Future<void> toggleNotifications(bool value) async {
    setState(() {
      notificationsEnabled = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);

    if (value) {
      try {
        for (int i = 0; i < notificationTimes.length; i++) {
          await _scheduleNotification(i, 'Task Reminder',
              'Have you started your tasks for today?', notificationTimes[i]);
        }
      } catch (e) {
        _showSnackBar(
            'Failed to schedule notifications: ${e.toString()}', Colors.red);
        print('Failed to schedule notifications: ${e.toString()}');
      }
    } else {
      await _notificationsPlugin.cancelAll();
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        showCloseIcon: true,
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _scheduleNotification(
      int id, String title, String body, TimeOfDay displayTime) async {
    final tz.TZDateTime scheduledTime =
        _convertDisplayToScheduleTime(displayTime);
    print('Scheduling notification for: $scheduledTime');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
      channelDescription: 'Daily task reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      color: Color(0xFF42A5F5),
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _convertDisplayToScheduleTime(TimeOfDay displayTime) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime displayDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      displayTime.hour,
      displayTime.minute,
    );

    // Adjust to GMT+0
    displayDateTime =
        displayDateTime.subtract(const Duration(hours: 5, minutes: 30));

    // Ensure correct scheduling if the adjusted time is in the past
    if (displayDateTime.isBefore(now)) {
      displayDateTime = displayDateTime.add(const Duration(days: 1));
    }

    return displayDateTime;
  }

  Future<void> selectTime(BuildContext context, int index) async {
    final TimeOfDay initialTime = notificationTimes[index];

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        notificationTimes[index] = picked;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'notificationTimes',
        notificationTimes.map((time) => '${time.hour}:${time.minute}').toList(),
      );
    }
  }

  Future<void> _showWelcomeDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 350),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Heyya!!',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp, // Responsive font size
                            ),
                            overflow:
                                TextOverflow.ellipsis, // Ensure no overflow
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Thank you for downloading the app! If you have any suggestions, bug reports, or feature requests, feel free to contact me through the Settings page.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp, // Responsive font size
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Proceed',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp, // Responsive font size
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          // Proceed to the HomeScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.intro == 1,
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main content wrapped in Expanded to push the bottom elements to the bottom
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Reminder notifications will be sent every day at your selected times.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp, color: Colors.black),
                          ),
                        ),
                        Switch(
                          value: notificationsEnabled,
                          onChanged: toggleNotifications,
                          activeColor: Colors.blue,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey[300],
                        ),
                      ],
                    ),
                    Divider(
                      color: const Color.fromARGB(255, 217, 217, 217),
                    ),
                    SizedBox(height: 10.sp),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set your daily task reminders:',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ...notificationTimes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final time = entry.value;
                          return Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Reminder Time ${index + 1}:',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp)),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          selectTime(context, index),
                                      child: Text(
                                        time.format(context),
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.sp,
                                            color: Colors.blue),
                                      ),
                                    ),
                                    Text(
                                      "|",
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.sp, color: Colors.grey),
                                    ),
                                    IconButton(
                                      icon: Icon(IconlyLight.delete,
                                          size: 15.sp, color: Colors.red),
                                      onPressed: () => _deleteReminder(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        Center(
                          child: ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.white),
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side:
                                            BorderSide(color: Colors.white)))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Add Reminder   ",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.sp,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                                Icon(Icons.add,
                                    size: 12.sp, color: Colors.blue),
                              ],
                            ),
                            onPressed: () {
                              setState(() {
                                notificationTimes
                                    .add(const TimeOfDay(hour: 6, minute: 30));
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          height: 10.sp,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bottom section containing TimeZone text and the save button
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Divider(
                  //   color: const Color.fromARGB(255, 217, 217, 217),
                  // ),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(100, 40),
                      ),
                      onPressed: () async {
                        toggleNotifications(notificationsEnabled);
                        if (widget.intro == 1) {
                          Navigator.pop(context);
                        } else if (widget.intro == 0) {
                          _showWelcomeDialog(context);
                        }
                      },
                      child: const Text('Save Settings'),
                    ),
                  ),
                  // Divider(
                  //   color: const Color.fromARGB(255, 217, 217, 217),
                  // ),
                  const SizedBox(height: 16),
                  Text(
                    'TimeZone is with respect to GMT+5:30',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// This method will handle deleting the reminder
  void _deleteReminder(int index) async {
    setState(() {
      notificationTimes.removeAt(index); // Remove the time from the list
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notificationTimes',
      notificationTimes.map((time) => '${time.hour}:${time.minute}').toList(),
    );

    // Cancel the notification for the deleted reminder
    await _notificationsPlugin.cancel(index);

    // Show feedback to the user
    _showSnackBar('Reminder deleted successfully!', Colors.green);
  }
}

Widget _buildDismissedItem(
    TimeOfDay time, Animation<double> animation, context) {
  return SizeTransition(
    sizeFactor: animation,
    child: ListTile(
      title: Text(time.format(context)),
      trailing: Icon(Icons.delete, size: 10.sp, color: Colors.blue),
    ),
  );
}
