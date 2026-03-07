import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityFeedTab extends StatelessWidget {
  const ActivityFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.rss_feed, color: Color(0xFF002244)),
              const SizedBox(width: 8),
              const Text(
                'Live Activity Feed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002244),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // We'll overlay multiple collections here conceptually, but for now
            // let's just listen to leave_requests as the primary "activity" source.
            // In a real app, you might have a dedicated 'activities' collection.
            stream: FirebaseFirestore.instance
                .collection('leave_requests')
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No recent activity'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildActivityCard(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data) {
    final email = data['email'] ?? 'Unknown User';
    final nameStr = email.split('@')[0];
    
    // Safety check for createdAt
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }
    
    final timeAgo = _timeAgo(createdAt);
    final status = data['status'];

    String action = "created a request";
    IconData icon = Icons.edit_note;
    Color iconColor = Colors.blue;

    if (status == 'approved') {
      action = "request was approved";
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (status == 'rejected') {
      action = "request was rejected";
      icon = Icons.cancel;
      iconColor = Colors.red;
    } else if (data['actualOutTime'] != null && data['actualInTime'] == null) {
      action = "checked out";
      icon = Icons.logout;
      iconColor = Colors.orange;
    } else if (data['actualInTime'] != null) {
      action = "checked in";
      icon = Icons.login;
      iconColor = Colors.teal;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, // Pure white for better contrast
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Very soft shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02), // subtle spread
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12), // slightly stronger tint background
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A), // Darker text for readability
                      fontSize: 15,
                    ),
                    children: [
                      TextSpan(
                        text: nameStr,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' $action',
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM').format(date);
  }
}
