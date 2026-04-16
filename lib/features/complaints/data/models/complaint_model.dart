import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/complaint.dart';

class ComplaintModel extends ComplaintEntity {
  const ComplaintModel({
    required super.id,
    required super.uid,
    required super.userEmail,
    super.studentName,
    required super.title,
    required super.description,
    required super.category,
    required super.status,
    required super.createdAt,
    super.resolvedAt,
    super.adminComment,
    super.hostelId,
    super.userCategory,
    super.userBranch,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    return ComplaintModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      userEmail: map['userEmail'] ?? '',
      studentName: map['studentName'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      adminComment: map['adminComment'],
      hostelId: map['hostelId'],
      userCategory: map['userCategory'],
      userBranch: map['userBranch'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'uid': uid,
      'userEmail': userEmail,
      if (studentName != null) 'studentName': studentName,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (resolvedAt != null) {
      map['resolvedAt'] = Timestamp.fromDate(resolvedAt!);
    }
    if (adminComment != null) {
      map['adminComment'] = adminComment;
    }
    if (hostelId != null) {
      map['hostelId'] = hostelId;
    }
    if (userCategory != null) {
      map['userCategory'] = userCategory;
    }
    if (userBranch != null) {
      map['userBranch'] = userBranch;
    }

    return map;
  }

  factory ComplaintModel.fromEntity(ComplaintEntity entity) {
    return ComplaintModel(
      id: entity.id,
      uid: entity.uid,
      userEmail: entity.userEmail,
      studentName: entity.studentName,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      status: entity.status,
      createdAt: entity.createdAt,
      resolvedAt: entity.resolvedAt,
      adminComment: entity.adminComment,
      hostelId: entity.hostelId,
      userCategory: entity.userCategory,
      userBranch: entity.userBranch,
    );
  }
}
