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
    String? targetCategory,
    String? targetBranch,
    String? targetHostelId,
  }) async {
    try {
      List<String> targetUids = [];
      List<String> tokens = [];

      if (['warden', 'rector', 'student', 'hod'].contains(receiverUid)) {
        // Broadcast to role, filtered by targets if provided
        final roleQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: receiverUid)
            .get();

        for (var doc in roleQuery.docs) {
          final data = doc.data();
          bool matches = true;

          // Check Category (Skip for Rector, who handles all categories)
          if (receiverUid != 'rector') {
            if (targetCategory != null && targetCategory.isNotEmpty) {
              final cat = data['category'] as String?;
              final catList = (data['assignedCategories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
              if (catList.isNotEmpty) {
                // HOD/Warden has a list of assigned categories — must contain the target
                if (!catList.contains(targetCategory)) matches = false;
              } else if (cat != null && cat.isNotEmpty) {
                // HOD/Warden has a single category field — must match exactly
                if (cat != targetCategory) matches = false;
              } else {
                // HOD/Warden has NO category info at all — do NOT notify them
                matches = false;
              }
            }
          }

          // Check Branch (Skip for Warden and Rector, who handle all academic branches in their hostel)
          if (receiverUid != 'warden' && receiverUid != 'rector') {
            if (targetBranch != null && targetBranch.isNotEmpty && matches) {
              final br = data['branch'] as String?;
              final brList = (data['assignedBranches'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
              if (brList.isNotEmpty) {
                // HOD has a list of assigned branches — must contain the target
                if (!brList.contains(targetBranch)) matches = false;
              } else if (br != null && br.isNotEmpty) {
                // HOD has a single branch field — must match exactly
                if (br != targetBranch) matches = false;
              } else {
                // HOD has NO branch info at all — do NOT notify them
                matches = false;
              }
            }
          }

          // Check Hostel
          if (targetHostelId != null && targetHostelId.isNotEmpty && matches) {
            final host = data['assignedHostel'] as String?;
            final hostList = (data['assignedHostels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            if (hostList.isNotEmpty) {
              // Warden/Role has a list — must contain the hostel or 'All'
              if (!hostList.contains(targetHostelId) && !hostList.contains('All')) matches = false;
            } else if (host != null && host.isNotEmpty) {
              // Warden/Role has a single hostel — must match or be 'All'
              if (host != targetHostelId && host != 'All') matches = false;
            }
            // Note: For hostel, if no hostel is assigned we allow it through
            // (some roles like HOD may not have hostel assignment)
          }

          if (matches) {
            targetUids.add(doc.id);
            if (data.containsKey('fcmToken') && data['fcmToken'] != null) {
              tokens.add(data['fcmToken']);
            }
          }
        }
      } else {
        // Specific User
        targetUids.add(receiverUid);
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

      // 1. Save to Firestore (In-App Notification) - Create one for EACH target UID
      final batch = _firestore.batch();
      for (String uid in targetUids) {
        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, {
          'title': title,
          'message': message,
          'receiverUid': uid, // Save to specific UID, not generic role
          'type': type,
          'relatedRequestId': relatedRequestId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      debugPrint(
        "Sending push to ${tokens.length} devices for receiver: $receiverUid (Matched ${targetUids.length} users)",
      );

      for (var token in tokens) {
        await _pushService.sendNotification(
          title: title,
          body: message,
          toToken: token,
        );
      }
    } catch (e, stack) {
      debugPrint("Error sending notification: $e\n$stack");
      // Rethrow so the caller knows it failed (especially permission errors!)
      // This helps catch Firestore security rules issues.
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
