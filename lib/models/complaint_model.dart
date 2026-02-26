import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String uid;
  final String userEmail;
  final String title;
  final String description;
  final String category;
  final String status; // 'Pending', 'Resolved'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminComment;
  final String? hostelId;

  Complaint({
    required this.id,
    required this.uid,
    required this.userEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminComment,
    this.hostelId,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'uid': uid,
      'userEmail': userEmail,
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

    return map;
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      userEmail: map['userEmail'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      adminComment: map['adminComment'],
      hostelId: map['hostelId'],
    );
  }
}
