import '../entities/complaint.dart';

abstract class ComplaintRepository {
  Future<void> addComplaint(ComplaintEntity complaint);
  Stream<List<ComplaintEntity>> getComplaintsByStudent(String uid);
  Stream<List<ComplaintEntity>> getAllComplaints();
  Future<void> updateComplaintStatus(
    String complaintId,
    String status,
    String? adminComment,
  );
}
