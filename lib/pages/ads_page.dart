import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hundred_days/utils/loader.dart';
import 'package:url_launcher/url_launcher.dart';

class AdsHomePage extends StatefulWidget {
  @override
  _AdsHomePageState createState() => _AdsHomePageState();
}

class _AdsHomePageState extends State<AdsHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchAdData();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

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

    if (notificationAds.exists) {
      final showNotificationAds = notificationAds.get('showNotificationAds');
      final notificationAdName = notificationAds.get('notificationAdName');
      final notificationAdLine = notificationAds.get('notificationAdLine');
      final notificationAdURL = notificationAds.get('notificationAdURL');
      final notificationImgURL = notificationAds.get('notificationImgURL');

      if (showNotificationAds) {
        _showNotificationAd(notificationAdName, notificationAdLine,
            notificationAdURL, notificationImgURL);
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
                    _isBannerAdshown = !_isBannerAdshown;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationAd(String notificationAdName, String notificationAdLine,
      String notificationAdURL, String notificationImgURL) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your channel id', 'your channel name',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    _flutterLocalNotificationsPlugin.show(
      0,
      notificationAdName,
      notificationAdLine,
      platformChannelSpecifics,
      payload: notificationAdURL,
    );
  }

  void _launchURL(String url) async {
    await launch(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Ad Showcase', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome to Ad Showcase',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                      onPressed: () {
                        _fetchAdData();
                      },
                      child: Text("button")),
                  SizedBox(height: 16),
                  SizedBox(height: 24),
                  Text(
                    'Enjoy exploring our ads!',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (_isBannerAdshown)
            Positioned(
              bottom: 10,
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
    );
  }
}
