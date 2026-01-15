import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OutStudentsScreen extends StatelessWidget {
  const OutStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Currently Out'),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leave_requests')
            .where('actualOutTime', isNull: false)
            .where('actualInTime', isNull: true)
            .orderBy('actualOutTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_walk, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No students are currently out",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final outTime = (data['actualOutTime'] as Timestamp).toDate();
              final expectedReturn = (data['endDate'] as Timestamp).toDate();
              final isOverdue = DateTime.now().isAfter(expectedReturn);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isOverdue
                      ? const BorderSide(color: Colors.red, width: 1.5)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isOverdue
                                ? Colors.red[50]
                                : Colors.blue[50],
                            child: Text(
                              (data['email'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: isOverdue
                                    ? Colors.red
                                    : const Color(0xFF002244),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['email'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isOverdue)
                                  const Text(
                                    "OVERDUE RETURN",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "OUT",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeInfo("Out Time", outTime, Colors.black87),
                          _buildTimeInfo(
                            "Expected Return",
                            expectedReturn,
                            isOverdue ? Colors.red : Colors.grey[700]!,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Reason: ${data['reason'] ?? 'N/A'}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeInfo(String label, DateTime date, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
