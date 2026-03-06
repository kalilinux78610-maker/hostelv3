import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, onLeave, outOnPass }

class AttendanceRecord {
  final String studentEmail;
  final String studentName;
  final String room;
  AttendanceStatus status;
  final String? leaveId; // Reference to leave request if applicable
  final String? gatePassId; // Reference to gate pass if applicable

  AttendanceRecord({
    required this.studentEmail,
    required this.studentName,
    required this.room,
    required this.status,
    this.leaveId,
    this.gatePassId,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentEmail': studentEmail,
      'studentName': studentName,
      'room': room,
      'status': status.name,
      'leaveId': leaveId,
      'gatePassId': gatePassId,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      studentEmail: map['studentEmail'] ?? '',
      studentName: map['studentName'] ?? '',
      room: map['room'] ?? '',
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.present,
      ),
      leaveId: map['leaveId'],
      gatePassId: map['gatePassId'],
    );
  }
}

class DailyAttendance {
  final String id; // format: 2024-03-06_BH1
  final String hostelId;
  final DateTime date;
  final List<AttendanceRecord> records;
  final String takenBy;
  final DateTime timestamp;

  DailyAttendance({
    required this.id,
    required this.hostelId,
    required this.date,
    required this.records,
    required this.takenBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'hostelId': hostelId,
      'date': Timestamp.fromDate(date),
      'records': records.map((r) => r.toMap()).toList(),
      'takenBy': takenBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory DailyAttendance.fromMap(String id, Map<String, dynamic> map) {
    return DailyAttendance(
      id: id,
      hostelId: map['hostelId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      records:
          (map['records'] as List<dynamic>?)
              ?.map((r) => AttendanceRecord.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      takenBy: map['takenBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
