import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // FCM V1 API CONFIGURATION — loaded from .env (never hardcode here!)
  // .env file is gitignored and never pushed to GitHub
  // ---------------------------------------------------------------------------
  static String get _projectId    => dotenv.env['FCM_PROJECT_ID']    ?? '';
  static String get _clientEmail  => dotenv.env['FCM_CLIENT_EMAIL']  ?? '';
  static String get _clientId     => dotenv.env['FCM_CLIENT_ID']     ?? '';
  static String get _privateKeyId => dotenv.env['FCM_PRIVATE_KEY_ID'] ?? '';
  // .env stores newlines as \n literal — convert back to real newlines
  static String get _privateKey   => (dotenv.env['FCM_PRIVATE_KEY']  ?? '')
      .replaceAll(r'\n', '\n');

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
      debugPrint('✅ FCM: User granted permission');
    } else {
      debugPrint('❌ FCM: User declined or has not accepted permission');
      // Don't return — still set up channel so foreground notifications work
      // when permission is eventually granted
    }

    // 2. Setup Local Notifications (for foreground display)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);

    // 3. Create Notification Channel for Android 8.0+
    await _createNotificationChannel();

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 FCM: Got a message in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 5. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    debugPrint('✅ FCM: Service initialized (channel + handlers ready)');
    // NOTE: Token sync happens in syncTokenAfterLogin() — called from RoleChecker
    // after user is authenticated. Do NOT sync here — user may not be logged in yet.
  }

  /// Call this AFTER the user is confirmed logged in (e.g., from RoleChecker).
  /// Saves the FCM token to the current user's Firestore document.
  Future<void> syncTokenAfterLogin() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('⚠️ FCM: syncTokenAfterLogin() called but user is null. Skipping.');
        return;
      }
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        debugPrint('⚠️ FCM: Could not get FCM token from Firebase Messaging.');
        return;
      }
      await _saveTokenToCurrentUser(token);

      // Listen for token refresh and keep it in sync
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM: Token refreshed, updating Firestore...');
        await _saveTokenToCurrentUser(newToken);
      });

      debugPrint('✅ FCM: Token synced for uid=$uid');
    } catch (e) {
      debugPrint('❌ FCM token sync failed: $e');
    }
  }



  Future<void> _saveTokenToCurrentUser(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      debugPrint('FCM token synced for user $uid');
    } catch (e) {
      debugPrint('Error saving refreshed FCM token: $e');
    }
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
          channelDescription: 'Notifications for SVPES eGate Pass',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
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
    if (_clientEmail.isEmpty || _privateKey.isEmpty) {
      debugPrint("⚠️ FCM WARNING: Credentials not set in .env file.");
      return null;
    }

    AutoRefreshingAuthClient? authClient;
    try {
      final accountCredentials = ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": _projectId,
        "private_key_id": _privateKeyId,
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

      authClient = await clientViaServiceAccount(accountCredentials, _scopes);
      final token = authClient.credentials.accessToken.data;
      debugPrint("✅ FCM Access token acquired successfully.");
      return token;
    } catch (e) {
      debugPrint("❌ FCM Error generating access token: $e");
      return null;
    } finally {
      authClient?.close(); // Always close to prevent connection leak
    }
  }

  // Send Notification using FCM V1 API
  Future<void> sendNotification({
    required String title,
    required String body,
    required String toToken,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      debugPrint("❌ FCM: Skipping push — no access token.");
      return;
    }

    debugPrint("📤 FCM: Sending to token ${toToken.substring(0, 20)}...");
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
                'channel_id': 'hostel_channel_id',
                'icon': 'ic_notification',
                'color': '#1565C0',
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ FCM: Push notification sent! Title: \"$title\"");
      } else {
        debugPrint(
          "❌ FCM Error ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("❌ FCM Exception: $e");
    }
  }
}
