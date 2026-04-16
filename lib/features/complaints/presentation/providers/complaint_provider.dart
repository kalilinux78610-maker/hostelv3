import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/datasources/complaint_remote_datasource.dart';
import '../../data/repositories/complaint_repository_impl.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaint_repository.dart';

part 'complaint_provider.g.dart';

@riverpod
ComplaintRemoteDataSource complaintRemoteDataSource(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return ComplaintRemoteDataSourceImpl(firestore);
}

@riverpod
ComplaintRepository complaintRepository(Ref ref) {
  final remoteDataSource = ref.watch(complaintRemoteDataSourceProvider);
  return ComplaintRepositoryImpl(remoteDataSource);
}

@riverpod
Stream<List<ComplaintEntity>> studentComplaints(Ref ref, String uid) {
  return ref.watch(complaintRepositoryProvider).getComplaintsByStudent(uid);
}

@riverpod
Stream<List<ComplaintEntity>> allComplaints(Ref ref) {
  return ref.watch(complaintRepositoryProvider).getAllComplaints();
}

@riverpod
class ComplaintAction extends _$ComplaintAction {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> submitComplaint(ComplaintEntity complaint) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => 
      ref.read(complaintRepositoryProvider).addComplaint(complaint)
    );
  }

  Future<void> updateStatus(String id, String status, String? comment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => 
      ref.read(complaintRepositoryProvider).updateComplaintStatus(id, status, comment)
    );
  }
}
