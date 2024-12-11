import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationSettingsPage extends StatefulWidget {
  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool notificationsEnabled = false;
  TimeOfDay firstNotificationTime = TimeOfDay(hour: 12, minute: 0);
  TimeOfDay secondNotificationTime = TimeOfDay(hour: 18, minute: 0);

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
      firstNotificationTime = prefs.containsKey('firstNotificationTime')
          ? TimeOfDay.fromDateTime(
              DateTime.parse(prefs.getString('firstNotificationTime')!))
          : const TimeOfDay(hour: 12, minute: 0);
      secondNotificationTime = prefs.containsKey('secondNotificationTime')
          ? TimeOfDay.fromDateTime(
              DateTime.parse(prefs.getString('secondNotificationTime')!))
          : const TimeOfDay(hour: 18, minute: 0);
    });

    if (notificationsEnabled) {
      await _scheduleNotification(0, 'First Task Reminder',
          'Have you started your tasks for today?', firstNotificationTime);
      await _scheduleNotification(1, 'Second Task Reminder',
          'Remember to keep working on your tasks!', secondNotificationTime);
    }
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

  void toggleNotifications(bool value) async {
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
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  Future<void> _sendImmediateNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'immediate _task_channel',
      'Immediate Task',
      channelDescription: 'Send immediate task notification',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      color: Color(0xFF42A5F5),
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      999,
      'Immediate Notification',
      'This is an immediate notification sent right now.',
      notificationDetails,
    );
  }

  Future<void> selectTime(BuildContext context, bool isFirstTime) async {
    TimeOfDay selectedTime =
        isFirstTime ? firstNotificationTime : secondNotificationTime;

    selectedTime = TimeOfDay(
        hour: selectedTime.hour + 5, minute: selectedTime.minute + 30);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        if (isFirstTime) {
          firstNotificationTime = picked;
        } else {
          secondNotificationTime = picked;
        }
      });

      final prefs = await SharedPreferences.getInstance();
      if (isFirstTime) {
        await prefs.setString(
            'firstNotificationTime',
            DateTime(0, 0, 0, picked.hour - 5, picked.minute - 30)
                .toIso8601String());
      } else {
        await prefs.setString(
            'secondNotificationTime',
            DateTime(0, 0, 0, picked.hour - 5, picked.minute - 30)
                .toIso8601String());
      }
    }
  }

  TimeOfDay displayJugaad(TimeOfDay time) {
    TimeOfDay ret =
        TimeOfDay(hour: (time.hour + 5) % 12, minute: (time.minute + 30) % 60);
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                        '${displayJugaad(firstNotificationTime).format(context)}',
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
                        '${displayJugaad(secondNotificationTime).format(context)}',
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
                          Navigator.pop(context);
                        },
                        child: const Text('Save Settings'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(100, 40),
                        ),
                        onPressed: _sendImmediateNotification,
                        child: const Text('Send'),
                      ),
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
