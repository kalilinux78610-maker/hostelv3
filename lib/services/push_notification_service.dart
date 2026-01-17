import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ---------------------------------------------------------------------------
  // FCM V1 API CONFIGURATION
  // ---------------------------------------------------------------------------
  // Go to Firebase Console -> Project Settings -> Service Accounts
  // click "Generate new private key". Open the JSON file.
  // Copy the values below from that JSON file.
  // ---------------------------------------------------------------------------
  static const String _projectId = 'hostel-v3';
  static const String _clientEmail =
      'firebase-adminsdk-fbsvc@hostel-v3.iam.gserviceaccount.com';
  static const String _privateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDmWIQQq0uWigKn
TtSNeef0+ClOJguK4jCGzQrfeAdVT54SIWnRKExpuBeRJDepYSLssYXTPb6UhyAl
y79debcMPc8RYHYy6V0I7m6jKwmY54GWZoO/Y3j9lKxZTaSGQFpnQcRnN6Ur1ws8
wFUCO2bAVbbT7u/SiaW99Rrc5osvojDAjLyrUgQ44LXK18YBpUczhN4jRl6q7jO4
8VO8eZxE39s7fAlVGp03MWCJuUwJSep/Mjkp3PUuCqmyM1rYnZJ5fcwvQ7ICQNAh
Ebgpo/fnhgTbbauqxLdg355PBfp2sk0Zd+SjZVaUtp9H+4aTlFsWpY6JCg+l6ESQ
wm9/NuBVAgMBAAECggEABmKXFpczpd1MLDMaipQXLUqLv+d8vmwoCDSQLphMgRLk
liq9nNdPIZxsGtE0Mcpy22N4YDNVSxdhJBW9HOw4z2q53gjHKKt2Br9alcSlpCAW
uYKR+FuGM7v2oxXB5Rl3krvXTpJ+Tkl3EvIJ6TaYUeXjsYWYDu/924F7LdBo303E
MWZ2VBa2tgaICZPdz/YE0TAXfo3TjrDSx3dfTeeL90NhduEfgzH+iR6tMyMOX65Y
6fBNHjeVaoAXdzgtbE/63UCs+puSLSRO69CVRDVlsecBePKPoAk10NsepyR/NfmI
x9PkbHB73/JHKgza3HjhVlLOdqu1kNPaELeBjsshgQKBgQD2KRnO/N49tIxbRBly
/xsSkJOKBTaXIsyO8hsg+3F62uowQ/QaNt/hNm+wUCrGgv4ZvsDBOuubmXTGm5cE
Anc9wjCVyqOUPhs9QhCr+PngR2wmj9W0DWn+Fm75iOdfnG75M8stDS3c9Sf/U7mK
WRvknu7dKdTlQyVZby+Zt6NExQKBgQDvjZYaIjvD+F1E/2Hf25OVmwRlsCXXPdx7
HkczCzjn/kv+op2sj2ieEL6LDIViSQlQAcBr1drCyXOyJWkMdQA2GqqPpdb2rbg2
gYE5XClOrpBTu6pMvRWB2puNQC4OVqKTTlQXdTVFJC+VeuDPyxaZVugXSCq0ULZM
SLcPI0OGUQKBgHJCWaxuS2ow6AVk8rsiFprjaNhj2xcEHBct4dHJZL815gZJRID2
f6y169nXHEPQgcnJdQc8JiivbjjR96Lw0hBkltCwooUo3tPsWni4tKOaA2VS1ksg
/tXl69T/6wXCQvCBTgm3WFZ7pPkrD7Bb9EqGSzF1PVC9fhSpO1sKlkpRAoGASRrM
U+1ej8+bpxLIq6g2wdEs5lt7MNSQFIKI9+rU0ven+W1m8OJS6unxPD319qiTTvc5
4a7Bs/AGfrcr98E870X0ByJ1F5KsRPYAmaCmenyLTwJWVlTd22L7VX/gjj+iHZIp
137NYuxIGTYGpWM04lbDPVeosJ5xA5atRtFcKgECgYEAsI5v66YNTyhPpVgYLvtn
H+U3Qy9tYJzwDDo0Mm1grTmXSiRqvrOK5IwKjixn9Idgj+fQocWKSqFzKJ42Lp7q
g2CHuagku8i0P2ONu7QU+xHk/TF8H1ejAia32REXjMQW8pw5EZy/7v00lxI+ocuU
RbYJigAdLPMh5UgzOLHMynE=
-----END PRIVATE KEY-----''';

  // Scopes required for FCM V1
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 2. Setup Local Notifications (for foreground display)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Initialize local notifications
    await _localNotifications.initialize(initializationSettings);

    // Create Notification Channel for Android 8.0+
    await _createNotificationChannel();

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 4. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'hostel_channel_id', // id
      'Hostel Notifications', // title
      description: 'Notifications for Hostel actions',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<String?> getFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");
      return token;
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'hostel_channel_id',
          'Hostel Notifications',
          channelDescription: 'Notifications for Hostel v3',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'app_icon',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  // Generate Access Token for V1 API
  Future<String?> _getAccessToken() async {
    if (_clientEmail == 'YOUR_CLIENT_EMAIL') {
      debugPrint("WARNING: Service Account credentials not set.");
      return null;
    }

    try {
      final accountCredentials = ServiceAccountCredentials.fromJson({
        "client_email": _clientEmail,
        "private_key": _privateKey,
        "project_id": _projectId,
        // Other fields are optional for this usage
      });

      final authClient = await clientViaServiceAccount(
        accountCredentials,
        _scopes,
      );

      return authClient.credentials.accessToken.data;
    } catch (e) {
      debugPrint("Error generating access token: $e");
      return null;
    }
  }

  // Send Notification using FCM V1 API
  Future<void> sendNotification({
    required String title,
    required String body,
    required String toToken,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
        ),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': toToken,
            'notification': {'title': title, 'body': body},
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'hostel_channel_id', // Must match local channel
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("V1 Notification sent successfully");
      } else {
        debugPrint(
          "Failed to send V1 notification: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error sending V1 push notification: $e");
    }
  }
}
