import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../homescreen.dart';

class NotificationSettings extends StatefulWidget {
  final int intro;
  const NotificationSettings({super.key, required this.intro});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

TimeOfDay displayFirstNotificationTime = const TimeOfDay(hour: 6, minute: 30);
TimeOfDay displaySecondNotificationTime = const TimeOfDay(hour: 12, minute: 30);

class _NotificationSettingsState extends State<NotificationSettings> {
  bool notificationsEnabled = true;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
  }

  Future<void> loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      displayFirstNotificationTime =
          _getStoredTime(prefs, 'firstNotificationTime') ??
              const TimeOfDay(hour: 6, minute: 30);
      displaySecondNotificationTime =
          _getStoredTime(prefs, 'secondNotificationTime') ??
              const TimeOfDay(hour: 12, minute: 30);
    });

    if (notificationsEnabled) {
      await _scheduleNotification(
          0,
          'First Task Reminder',
          'Have you started your tasks for today?',
          displayFirstNotificationTime);
      await _scheduleNotification(
          1,
          'Second Task Reminder',
          'Remember to keep working on your tasks!',
          displaySecondNotificationTime);
    }
  }

  TimeOfDay? _getStoredTime(SharedPreferences prefs, String key) {
    if (!prefs.containsKey(key)) return null;
    final storedTime = DateTime.tryParse(prefs.getString(key)!);
    if (storedTime == null) return null;
    return TimeOfDay(hour: storedTime.hour, minute: storedTime.minute);
  }

  Future<void> toggleNotifications(bool value) async {
    setState(() {
      notificationsEnabled = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);

    if (value) {
      await _scheduleNotification(
          0,
          'First Task Reminder',
          'Have you started your tasks for today?',
          displayFirstNotificationTime);
      await _scheduleNotification(
          1,
          'Second Task Reminder',
          'Remember to keep working on your tasks!',
          displaySecondNotificationTime);
    } else {
      await _notificationsPlugin.cancelAll();
    }
  }

  Future<void> _scheduleNotification(
      int id, String title, String body, TimeOfDay displayTime) async {
    final TimeOfDay schedulingTime = _convertToGMT(displayTime);
    final tz.TZDateTime scheduledTime = _nextInstanceOfTime(schedulingTime);

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

  TimeOfDay _convertToGMT(TimeOfDay localTime) {
    final int totalMinutes = localTime.hour * 60 +
        localTime.minute -
        330; // Subtract 5 hours 30 minutes
    final int gmtHour = (totalMinutes ~/ 60) % 24;
    final int gmtMinute = totalMinutes % 60;
    return TimeOfDay(hour: gmtHour, minute: gmtMinute);
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  Future<void> selectTime(BuildContext context, bool isFirstTime) async {
    final TimeOfDay initialTime = isFirstTime
        ? displayFirstNotificationTime
        : displaySecondNotificationTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        if (isFirstTime) {
          displayFirstNotificationTime = picked;
        } else {
          displaySecondNotificationTime = picked;
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        isFirstTime ? 'firstNotificationTime' : 'secondNotificationTime',
        DateTime(0, 0, 0, picked.hour, picked.minute).toIso8601String(),
      );
    }
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your daily task reminders:',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('First Reminder Time:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                    TextButton(
                      onPressed: () => selectTime(context, true),
                      child: Text(
                        displayFirstNotificationTime.format(context),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Second Reminder Time:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                    TextButton(
                      onPressed: () => selectTime(context, false),
                      child: Text(
                        displaySecondNotificationTime.format(context),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Reminder notifications will be sent every day at your selected times.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.grey),
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
                const SizedBox(height: 30),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomeScreen()),
                            );
                          }
                    },
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'TimeZone is with respect to GMT+5:30',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
