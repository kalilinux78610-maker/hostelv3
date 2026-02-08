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
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCvMf4jhp6wUjxw
bnF39gYbscLW3PCjorf5m8tljVczRnqNB9v6cMKI+yd84FFp9vAAGIrOJhleri2W
FayZ300e0JwNVKvHy6Y+zvawMxpZENnMjfR56ixFsYHajWtxIlZG/3QxRXt3reqr
budjY4iGw9/Vm9RLzUAYgw9B7hWTSgKjxKVSJw+bruFwGPswiY9CKkW6ygPpxolS
TBo1xyXSjgbL03hhQv1kH3EUFXPIZNs83woDgjNcWkf06Rqh+a8C/29Mg6lvkJnA
HGuY3rodpPf5PFfVnynIdN6CKWhHhat8s9r+XsvZ7+qjgjOEF2VejC7W/+Z0KP52
aZgtejrfAgMBAAECggEAL3BoEpKXUcNS3lbpnsQdr04ZJjk5Z/Xdv1cyYlM9c4L4
GEwygsQZySHI9YWARiM5paz/mQa0A/FCIsvHqvrOVTPDrdBpm3ZHk+ZS4i9USR3I
/BzMQF7qkgyYzudQWpgjqKHvgo//+M49JyKmwUDobSWI7Lx/Ze80Fe8XKJEhgnor
LPGXGWV+2VJMJjDG7cRYeey+yVcWsvrasXjZaND1WdtIIIWBaQFPbfLwero++ryq
AqZ28sI2I3hy05Sqk8OfXlhT70RtG9clyll6SB7GEtvw7b2GdWkdg0lkpGdFrFUc
Ga8dYlLVr7fV9Z+jzs5dnaJoCojXrNDpOl4oZVwXQQKBgQDbfzip8TdI9oHMbNPC
RCyE1/NYfd3malhZHSejU5HkS+4I0R9DMhRpyjLKwMqsyyYmDx30xu0XrIS5rKoz
mu2Xv0kWdKzY4CcJNDIrE3ypqWwd7fl/qsFwGcGznAl73P0ar2qVHcqUM2uSVBx8
UUQoq+2xrPtTtnCEJnK3J8lwDwKBgQDMVLBkWvStXAVVDmTMdl74YPblEl44/gmd
z1xWUKWD2Aj0UR6kZlXz48ARXpdpS0PGWvUx1vq1385PTH6ElGrD8Q6SNLUGKZ7N
FZr1dH1a5XbbWM6+KJ8wzgUFQCSRR5ycea+JT72tTJfwmLcHDaIKAWmUbwwDjkBW
1dgy4Y+4MQKBgH6xnD9bYBHZV2prln8XYqr7CxcU77RDxeMKFQsM/bTMrwSf0G+0
xFubvl2RkmrSh56IMz5KZCe6CJIzu7o1vtZMLx+rEOnN2DpTynFauiYkCKft6Ils
QmM2Orw1YLQCBoYUomyX2YpZc8nuitKnBbSEKJrZwee78o4UszpM2NS5AoGAeBNY
qVDuMqY+F/Lid2kkfE/3Jzy5FELtgcim2a6A5c7hzDmTiUb+QdnYOBzfW6g4RuuS
5dwQ7yp7ggxQ2Tai20zgpDjHHLz+rkSBELeJJw5r35D7xbH3guW++4vrMVjlButX
pZivvZSiQWhtPn7bd4fG9MyhQcGpu53ldFkrbTECgYEAqNlCwIJ0hGRT3fSYJHxz
xgfEQDbSucu/eVZv/w4tpTn+MUJblQBeyt57Wablzdnz89b1u3pcryT4wuI3tFJP
AyDcuwiFxC9ToJVjsB5L+2jaCII+YR+R5yc3vCsfraIbkVUGknUMdyRdhlwo7B62
s6UDRq7nykEUKEw83j0m3mg=
-----END PRIVATE KEY-----''';

  static const String _clientId = '114924344665199922669';

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
        "type": "service_account",
        "project_id": _projectId,
        "private_key_id": "393ed3c3e525680b33ace78a02fd7369bcae1c27",
        "private_key": _privateKey,
        "client_email": _clientEmail,
        "client_id": _clientId,
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40hostel-v3.iam.gserviceaccount.com",
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
