import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationSenderPage extends StatefulWidget {
  @override
  _NotificationSenderPageState createState() => _NotificationSenderPageState();
}

class _NotificationSenderPageState extends State<NotificationSenderPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  bool isSendingToAll = true;

  Future<void> sendNotification() async {
    String title = _titleController.text;
    String body = _bodyController.text;
    String fcmToken = _tokenController.text;
    String imageUrl = _imageUrlController.text;
    String link = _linkController.text;

    if (isSendingToAll) {
      // Send to all users
      await sendNotificationToTopic(title, body, imageUrl, link);
    } else {
      // Send to individual user
      await sendNotificationToUser (fcmToken, title, body, imageUrl, link);
    }
  }

  Future<void> sendNotificationToTopic(String title, String body, String imageUrl, String link) async {
    final response = await http.post(
      Uri.parse('https://<YOUR_REGION>-<YOUR_PROJECT_ID>.cloudfunctions.net/sendNotificationToTopic'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': 'allUsers',
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'link': link,
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent to all users');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }

  Future<void> sendNotificationToUser (String fcmToken, String title, String body, String imageUrl, String link) async {
    final response = await http.post(
      Uri.parse('https://<YOUR_REGION>-<hundred-days-beee0>.cloudfunctions.net/sendNotificationToUser '),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'link': link,
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent to user: $fcmToken');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Notification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: 'Body'),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: InputDecoration(labelText: 'Image URL'),
            ),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(labelText: 'Link'),
            ),
            Row(
              children: [
                Radio(
                  value: true,
                  groupValue: isSendingToAll,
                  onChanged: (value) {
                    setState(() {
                      isSendingToAll = true;
                    });
                  },
                ),
                Text('Send to All Users'),
                Radio(
                  value: false,
                  groupValue: isSendingToAll,
                  onChanged: (value) {
                    setState(() {
                      isSendingToAll = false;
                    });
                  },
                ),
                Text('Send to Individual User'),
              ],
            ),
            if (!isSendingToAll)
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(labelText: 'FCM Token'),
              ),
            SizedBox(height:  20),
            ElevatedButton(
              onPressed: sendNotification,
              child: Text('Send Notification'),
            ),
          ],
        ),
      ),
    );
  }
}