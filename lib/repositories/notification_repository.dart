import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/push_notification_service.dart';

class NotificationRepository {
  final _firestore = FirebaseFirestore.instance;
  final _pushService = PushNotificationService();

  // Send a notification to a specific user or role
  Future<void> sendNotification({
    required String title,
    required String message,
    required String receiverUid, // 'warden', 'rector', or specific user UID
    required String type, // 'leave_request', 'system', etc.
    String? relatedRequestId,
  }) async {
    try {
      // 1. Save to Firestore (In-App Notification)
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'receiverUid': receiverUid,
        'type': type,
        'relatedRequestId': relatedRequestId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Send Push Notification (FCM)
      List<String> tokens = [];

      if (['warden', 'rector', 'student', 'hod'].contains(receiverUid)) {
        // Broadcast to role
        // Note: For 'student', we usually don't broadcast to ALL students in this app context,
        // but 'warden' or 'rector' might be valid broadcast targets.
        final roleQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: receiverUid)
            .get();

        for (var doc in roleQuery.docs) {
          final data = doc.data();
          if (data.containsKey('fcmToken') && data['fcmToken'] != null) {
            tokens.add(data['fcmToken']);
          }
        }
      } else {
        // Specific User
        final userDoc = await _firestore
            .collection('users')
            .doc(receiverUid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data.containsKey('fcmToken')) {
            tokens.add(data['fcmToken']);
          }
        }
      }

      debugPrint(
        "Sending push to ${tokens.length} devices for receiver: $receiverUid",
      );

      for (var token in tokens) {
        await _pushService.sendNotification(
          title: title,
          body: message,
          toToken: token,
        );
      }
    } catch (e) {
      debugPrint("Error sending notification: $e");
      // Fail silently to not disrupt the main flow
    }
  }

  // Stream notifications for a user based on their UID and Role
  Stream<QuerySnapshot> getNotifications({
    required String uid,
    required String role,
  }) {
    // Build the list of receiverUids this user can receive notifications for
    List<String> targetIds = [uid];
    if (role == 'warden') targetIds.add('warden');
    if (role == 'rector') targetIds.add('rector');
    if (role == 'guard') targetIds.add('guard');
    if (role == 'hod') targetIds.add('hod');
    if (role == 'student') targetIds.add('student');

    // NOTE: We do NOT use orderBy here because combining orderBy with whereIn
    // requires a Firestore composite index. We sort client-side in the UI instead.
    return _firestore
        .collection('notifications')
        .where('receiverUid', whereIn: targetIds)
        .snapshots();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  // Mark all unread notifications as read for this view
  // (Optional utility)
  Future<void> markAllAsRead(List<String> notificationIds) async {
    final batch = _firestore.batch();
    for (var id in notificationIds) {
      batch.update(_firestore.collection('notifications').doc(id), {
        'isRead': true,
      });
    }
    await batch.commit();
  }
}
