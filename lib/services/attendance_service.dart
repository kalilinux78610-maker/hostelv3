import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique ID for the daily attendance document
  String generateDocId(String hostelId, DateTime date) {
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return "${dateStr}_$hostelId";
  }

  // Fetch all students for a specific hostel and determine their auto-status
  Future<List<AttendanceRecord>> prepareAttendanceList(
    String hostelId,
    DateTime date,
  ) async {
    // 1. Fetch students assigned to this hostel
    final studentsSnapshot = await _firestore
        .collection('student_imports')
        .where('assignedHostel', isEqualTo: hostelId)
        .get();

    // 2. Fetch active approved leave requests for today
    final startOfToday = DateTime(date.year, date.month, date.day);
    final endOfToday = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Fetch all approved leaves for this hostel, then filter dates locally to avoid complex index requirements
    final leavesSnapshot = await _firestore
        .collection('leave_requests')
        .where('hostelId', isEqualTo: hostelId)
        .where('status', isEqualTo: 'approved')
        .get();
    
    // Filter leaves locally: Must be approved AND today must be between (or on) startDate and endDate
    final activeLeaves = leavesSnapshot.docs.where((doc) {
      final data = doc.data();
      final startDate = (data['startDate'] as Timestamp).toDate();
      final endDate = (data['endDate'] as Timestamp).toDate();
      
      // Student is "on leave" if today is after the start and before the end
      return startDate.isBefore(endOfToday) && endDate.isAfter(startOfToday);
    }).toList();

    // 3. Map students to AttendanceRecords
    List<AttendanceRecord> records = [];
    for (var doc in studentsSnapshot.docs) {
      final data = doc.data();
      final email = data['email'] ?? '';
      final name = data['name'] ?? '';
      final room = data['room'] ?? '';

      // Check if student is on approved leave
      DocumentSnapshot? leaveDoc;
      try {
        leaveDoc = activeLeaves.firstWhere(
          (l) => (l.data() as Map<String, dynamic>?)?['email'] == email,
        );
      } catch (_) {
        leaveDoc = null;
      }

      AttendanceStatus initialStatus = AttendanceStatus.present;
      String? leaveId;
      String? gatePassId;

      if (leaveDoc != null) {
        final leaveData = leaveDoc.data() as Map<String, dynamic>;

        // Check if student is actively "OUT" (Out on Pass)
        if (leaveData['actualOutTime'] != null &&
            leaveData['actualInTime'] == null) {
          initialStatus = AttendanceStatus.outOnPass;
          gatePassId = leaveDoc.id; // Using leave ID as gatePassId for now
        } else {
          initialStatus = AttendanceStatus.onLeave;
          leaveId = leaveDoc.id;
        }
      }

      records.add(
        AttendanceRecord(
          studentEmail: email,
          studentName: name,
          room: room,
          status: initialStatus,
          leaveId: leaveId,
          gatePassId: gatePassId,
        ),
      );
    }

    // Sort by room number
    records.sort((a, b) => a.room.compareTo(b.room));
    return records;
  }

  // Save the attendance record
  Future<void> submitAttendance(DailyAttendance attendance) async {
    await _firestore
        .collection('daily_attendance')
        .doc(attendance.id)
        .set(attendance.toMap());
  }

  // Get attendance history for a specific hostel
  Stream<QuerySnapshot> getAttendanceHistory(String hostelId) {
    return _firestore
        .collection('daily_attendance')
        .where('hostelId', isEqualTo: hostelId)
        .orderBy('date', descending: true)
        .snapshots();
  }
}
