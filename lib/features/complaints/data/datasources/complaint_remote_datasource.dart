import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

abstract class ComplaintRemoteDataSource {
  Future<void> addComplaint(ComplaintModel complaint);
  Stream<List<ComplaintModel>> getComplaintsByStudent(String uid);
  Stream<List<ComplaintModel>> getAllComplaints();
  Future<void> updateComplaintStatus(
    String complaintId,
    String status,
    String? adminComment,
  );
}

class ComplaintRemoteDataSourceImpl implements ComplaintRemoteDataSource {
  final FirebaseFirestore _firestore;

  ComplaintRemoteDataSourceImpl(this._firestore);

  @override
  Future<void> addComplaint(ComplaintModel complaint) async {
    final complaintMap = complaint.toMap();
    complaintMap['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('complaints').doc(complaint.id).set(complaintMap);
  }

  @override
  Stream<List<ComplaintModel>> getComplaintsByStudent(String uid) {
    return _firestore
        .collection('complaints')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(doc.data()))
            .toList());
  }

  @override
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> updateComplaintStatus(
    String complaintId,
    String status,
    String? adminComment,
  ) async {
    final updateData = {
      'status': status,
      'resolvedAt': status == 'Resolved' ? Timestamp.now() : null,
    };
    if (adminComment != null) {
      updateData['adminComment'] = adminComment;
    }
    await _firestore.collection('complaints').doc(complaintId).update(updateData);
  }
}
