import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new complaint
  Future<void> addComplaint(Complaint complaint) async {
    try {
      final complaintMap = complaint.toMap();
      complaintMap['createdAt'] =
          FieldValue.serverTimestamp(); // Enforce server timestamp for security rules

      await _firestore
          .collection('complaints')
          .doc(complaint.id)
          .set(complaintMap);
    } catch (e) {
      throw Exception('Failed to add complaint: $e');
    }
  }

  // Get complaints for a specific student
  Stream<List<Complaint>> getComplaintsByStudent(String uid) {
    return _firestore
        .collection('complaints')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Complaint.fromMap(doc.data()))
              .toList();
        });
  }

  // Get all complaints (for Admin)
  Stream<List<Complaint>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Complaint.fromMap(doc.data()))
              .toList();
        });
  }

  // Update complaint status (Resolved/Pending) and add admin comment
  Future<void> updateComplaintStatus(
    String complaintId,
    String status,
    String? adminComment,
  ) async {
    try {
      final updateData = {
        'status': status,
        'resolvedAt': status == 'Resolved' ? Timestamp.now() : null,
      };

      if (adminComment != null) {
        updateData['adminComment'] = adminComment;
      }

      await _firestore
          .collection('complaints')
          .doc(complaintId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update complaint: $e');
    }
  }
}
