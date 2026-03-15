import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/attendance_model.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  State<AttendanceReportsScreen> createState() =>
      _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  String? _selectedHostel;
  final List<String> _hostels = ['BH1', 'BH2', 'BH3', 'BH4', 'GH1', 'GH2'];

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('daily_attendance');
    if (_selectedHostel != null) {
      query = query.where('hostelId', isEqualTo: _selectedHostel);
    }
    query = query.orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Reports"),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No attendance records found."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final attendance = DailyAttendance.fromMap(doc.id, data);

                    return _buildAttendanceCard(attendance);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedHostel,
              decoration: InputDecoration(
                labelText: "Filter by Hostel",
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("All Hostels")),
                ..._hostels.map(
                  (h) => DropdownMenuItem(value: h, child: Text(h)),
                ),
              ],
              onChanged: (val) => setState(() => _selectedHostel = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(DailyAttendance attendance) {
    int present = attendance.records
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    int absent = attendance.records
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
    int onLeave = attendance.records
        .where((r) => r.status == AttendanceStatus.onLeave)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          "${attendance.date.day}/${attendance.date.month}/${attendance.date.year} - ${attendance.hostelId}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "P: $present | A: $absent | L: $onLeave • Taken by: ${attendance.takenBy.split('@')[0]}",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          const Divider(),
          ...attendance.records
              .where((r) => r.status != AttendanceStatus.present)
              .map((r) {
                return ListTile(
                  dense: true,
                  title: Text("${r.studentName} (Room ${r.room})"),
                  subtitle: Text(r.studentEmail),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(r.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      r.status.name.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(r.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
          if (attendance.records.every(
            (r) => r.status == AttendanceStatus.present,
          ))
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "All students were present.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.onLeave:
        return Colors.blue;
      case AttendanceStatus.outOnPass:
        return Colors.orange;
    }
  }
}
