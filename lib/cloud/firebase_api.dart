import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hundred_days/main.dart';
import 'package:url_launcher/url_launcher.dart';

// GlobalKey for Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notification settings
  Future<void> initNotification() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create a notification channel
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'firebase_messaging', // ID
      'notification_channel', // Name
      description:
          'This channel is used for important notifications.', // Description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions for notifications
    await _firebaseMessaging.requestPermission();

    // Store the FCM token
    await storeFCMToken();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Subscribe to topic
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final docSnapshot =
        await _firestore.collection('adminPanel').doc('currentTopic').get();
    final n =
        await _firestore.collection('adminPanel').doc('currentTopic').get();

    await subscribeToTopic('allUsers');

    //By default, subscribe to the topic 'all' if no topic is found in the admin panel
    if (n == -1)
      await subscribeToTopic('allUsers');

    // If users got more than 1000 than currentTopic will be updated to 0,1....
    // as Firebase messaging has a limit of 1000 topics per user
    // so upcoming users will be subscribed to another topic
    // when sending notifications, we will send to all topics
    else
      await subscribeToTopic('allUsers$n');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        showNotification(message.notification!, message.data);
      }
    });

    // Handle notification taps when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Handle the notification tap
      handleNotificationTap(message.data['link']);
    });
  }

  // Show local notification
  Future<void> showNotification(
      RemoteNotification notification, Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: data['link'], // Pass the URL as payload
    );
  }

  // Handle notification tap
  void handleNotificationTap(String? payload) async {
    if (payload != null && payload.isNotEmpty) {
      // Launch URL when the notification is tapped
      if (await canLaunch(payload)) {
        await launch(payload);
      } else {
        print("Could not launch $payload");
      }
    } else {
      // If no link is found or data is empty, navigate to home screen
      navigateToHomeScreen();
    }
  }

  void navigateToHomeScreen() {
    // Navigate to your home screen or desired screen using GlobalKey
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (context) => HundredDays(),
      ),
    );
  }

  // Store FCM token in Firestore
  Future<void> storeFCMToken() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(user.uid)
            .set({'fcmToken': fcmToken}, SetOptions(merge: true));
      }
      print('Stored FCM Token: $fcmToken');
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }
}
