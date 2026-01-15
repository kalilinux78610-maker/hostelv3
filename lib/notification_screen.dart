import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'repositories/notification_repository.dart';

class NotificationScreen extends StatefulWidget {
  final String userRole; // 'student', 'warden', 'rector'

  const NotificationScreen({super.key, required this.userRole});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _repository = NotificationRepository();
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view notifications")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF002244),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _repository.getNotifications(
          uid: _currentUser.uid,
          role: widget.userRole,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final isRead = notification['isRead'] ?? false;
              final timestamp = notification['createdAt'] as Timestamp?;
              final dateStr = timestamp != null
                  ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
                  : 'Just now';

              return Dismissible(
                key: Key(notificationId),
                background: Container(color: Colors.red),
                onDismissed: (direction) {
                  // Optional: Delete notification logic
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  tileColor: isRead ? Colors.white : Colors.blue[50],
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey[200]
                        : const Color(0xFF002244).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.notifications,
                      color: isRead ? Colors.grey : const Color(0xFF002244),
                    ),
                  ),
                  title: Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] ?? '',
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      _repository.markAsRead(notificationId);
                    }
                    // Handle navigation if relatedRequestId exists?
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
