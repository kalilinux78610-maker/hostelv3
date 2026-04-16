class ComplaintEntity {
  final String id;
  final String uid;
  final String userEmail;
  final String? studentName;
  final String title;
  final String description;
  final String category;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminComment;
  final String? hostelId;
  final String? userCategory;
  final String? userBranch;

  const ComplaintEntity({
    required this.id,
    required this.uid,
    required this.userEmail,
    this.studentName,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminComment,
    this.hostelId,
    this.userCategory,
    this.userBranch,
  });
}
