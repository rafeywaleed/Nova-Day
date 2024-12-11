import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationSettingsPage extends StatefulWidget {
  final int intro;
  const NotificationSettingsPage({super.key, required this.intro});

  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool notificationsEnabled = true;
  TimeOfDay firstDisplayTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay secondDisplayTime = const TimeOfDay(hour: 18, minute: 0);

  TimeOfDay firstNotificationTime = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay secondNotificationTime = const TimeOfDay(hour: 12, minute: 30);

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    loadNotificationState();
    _initializeNotifications();
  }

  Future<void> loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      firstNotificationTime = _getStoredTime(prefs, 'firstNotificationTime') ??
          const TimeOfDay(hour: 6, minute: 30);
      secondNotificationTime =
          _getStoredTime(prefs, 'secondNotificationTime') ??
              const TimeOfDay(hour: 12, minute: 30);

      firstDisplayTime = _convertToDisplayTime(firstNotificationTime);
      secondDisplayTime = _convertToDisplayTime(secondNotificationTime);
    });

    if (notificationsEnabled) {
      await _scheduleNotification(0, 'First Task Reminder',
          'Have you started your tasks for today?', firstNotificationTime);
      await _scheduleNotification(1, 'Second Task Reminder',
          'Remember to keep working on your tasks!', secondNotificationTime);
    }
  }

  TimeOfDay? _getStoredTime(SharedPreferences prefs, String key) {
    if (!prefs.containsKey(key)) return null;
    final storedTime = DateTime.parse(prefs.getString(key)!);
    return TimeOfDay(hour: storedTime.hour, minute: storedTime.minute);
  }

  Future<void> _scheduleNotification(
      int id, String title, String body, TimeOfDay time) async {
    final tz.TZDateTime scheduledTime = _nextInstanceOfTime(time);

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

  Future<void> toggleNotifications(bool value) async {
    setState(() {
      notificationsEnabled = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);

    if (value) {
      await _scheduleNotification(0, 'First Task Reminder',
          'Have you started your tasks for today?', firstNotificationTime);
      await _scheduleNotification(1, 'Second Task Reminder',
          'Remember to keep working on your tasks!', secondNotificationTime);
    } else {
      await _notificationsPlugin.cancelAll();
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.UTC);
    tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.UTC, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  Future<void> selectTime(BuildContext context, bool isFirstTime) async {
    TimeOfDay selectedTime = isFirstTime ? firstDisplayTime : secondDisplayTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      final TimeOfDay convertedNotificationTime = _convertToNotificationTime(
          picked); // Convert to GMT+0:0 before saving

      setState(() {
        if (isFirstTime) {
          firstDisplayTime = picked;
          firstNotificationTime = convertedNotificationTime;
        } else {
          secondDisplayTime = picked;
          secondNotificationTime = convertedNotificationTime;
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        isFirstTime ? 'firstNotificationTime' : 'secondNotificationTime',
        DateTime(0, 0, 0, convertedNotificationTime.hour,
                convertedNotificationTime.minute)
            .toIso8601String(),
      );
    }
  }

  TimeOfDay _convertToNotificationTime(TimeOfDay displayTime) {
    int hour = (displayTime.hour - 5) % 24;
    int minute = (displayTime.minute - 30);
    if (minute < 0) {
      minute += 60;
      hour = (hour - 1) % 24;
    }
    if (hour < 0) hour += 24;
    return TimeOfDay(hour: hour, minute: minute);
  }

  TimeOfDay _convertToDisplayTime(TimeOfDay notificationTime) {
    int hour = (notificationTime.hour + 5) % 24;
    int minute = (notificationTime.minute + 30);
    if (minute >= 60) {
      minute -= 60;
      hour = (hour + 1) % 24;
    }
    return TimeOfDay(hour: hour, minute: minute);
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
                        '${firstDisplayTime.format(context)}',
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
                        '${secondDisplayTime.format(context)}',
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
                  child: Column(
                    children: [
                      ElevatedButton(
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
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Flexible(
                child: Text(
                  'TimeZone is with respect to GMT+5:30',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
