import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceTakingScreen extends StatefulWidget {
  final String hostelId;
  const AttendanceTakingScreen({super.key, required this.hostelId});

  @override
  State<AttendanceTakingScreen> createState() => _AttendanceTakingScreenState();
}

class _AttendanceTakingScreenState extends State<AttendanceTakingScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final records = await _attendanceService.prepareAttendanceList(
        widget.hostelId,
        _selectedDate,
      );
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading students: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Submit Attendance?"),
        content: Text(
          "Are you sure you want to submit attendance for ${widget.hostelId} on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002244),
              foregroundColor: Colors.white,
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final attendance = DailyAttendance(
        id: _attendanceService.generateDocId(widget.hostelId, _selectedDate),
        hostelId: widget.hostelId,
        date: _selectedDate,
        records: _records,
        takenBy: user?.email ?? 'Unknown',
        timestamp: DateTime.now(),
      );

      await _attendanceService.submitAttendance(attendance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance submitted successfully!")),
        );
        // Refresh the list instead of popping since it's a tab
        _loadStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting attendance: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group records by room
    Map<String, List<AttendanceRecord>> groupedRecords = {};
    for (var record in _records) {
      groupedRecords.putIfAbsent(record.room, () => []).add(record);
    }
    var sortedRooms = groupedRecords.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Take Attendance"),
            Text(
              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} • ${widget.hostelId}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedRooms.length,
                    itemBuilder: (context, index) {
                      String room = sortedRooms[index];
                      List<AttendanceRecord> roomStudents =
                          groupedRecords[room]!;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Room $room",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF002244),
                                ),
                              ),
                            ),
                            ...roomStudents.map(
                              (student) => _buildStudentTile(student),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002244),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Attendance",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentTile(AttendanceRecord student) {
    bool isLocked =
        student.status == AttendanceStatus.onLeave ||
        student.status == AttendanceStatus.outOnPass;

    return ListTile(
      title: Text(
        student.studentName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        student.studentEmail,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                student.status == AttendanceStatus.onLeave
                    ? "On Leave"
                    : "Out/Pass",
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Row(
              children: [
                _buildToggleButton(
                  icon: Icons.check_circle,
                  isSelected: student.status == AttendanceStatus.present,
                  activeColor: Colors.green,
                  onTap: () {
                    setState(() => student.status = AttendanceStatus.present);
                  },
                ),
                const SizedBox(width: 8),
                _buildToggleButton(
                  icon: Icons.cancel,
                  isSelected: student.status == AttendanceStatus.absent,
                  activeColor: Colors.red,
                  onTap: () {
                    setState(() => student.status = AttendanceStatus.absent);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? activeColor : Colors.grey[300],
          size: 32,
        ),
      ),
    );
  }
}
