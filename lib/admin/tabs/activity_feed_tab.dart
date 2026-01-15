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
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final timeAgo = _timeAgo(createdAt);
    final status = data['status'];

    String action = "created a request";
    IconData icon = Icons.edit_note;
    Color color = Colors.blue;

    if (status == 'approved') {
      action = "request was approved";
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (status == 'rejected') {
      action = "request was rejected";
      icon = Icons.cancel;
      color = Colors.red;
    } else if (data['actualOutTime'] != null) {
      action = "checked out";
      icon = Icons.logout;
      color = Colors.orange;
    } else if (data['actualInTime'] != null) {
      action = "checked in";
      icon = Icons.login;
      color = Colors.teal;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: email.split('@')[0],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' $action'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
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
