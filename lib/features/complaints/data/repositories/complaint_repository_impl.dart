import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaint_repository.dart';
import '../datasources/complaint_remote_datasource.dart';
import '../models/complaint_model.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  final ComplaintRemoteDataSource _remoteDataSource;

  ComplaintRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> addComplaint(ComplaintEntity complaint) async {
    await _remoteDataSource.addComplaint(ComplaintModel.fromEntity(complaint));
  }

  @override
  Stream<List<ComplaintEntity>> getComplaintsByStudent(String uid) {
    return _remoteDataSource.getComplaintsByStudent(uid);
  }

  @override
  Stream<List<ComplaintEntity>> getAllComplaints() {
    return _remoteDataSource.getAllComplaints();
  }

  @override
  Future<void> updateComplaintStatus(
    String complaintId,
    String status,
    String? adminComment,
  ) async {
    await _remoteDataSource.updateComplaintStatus(
      complaintId,
      status,
      adminComment,
    );
  }
}
