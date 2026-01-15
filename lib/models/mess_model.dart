import 'package:cloud_firestore/cloud_firestore.dart';

class MessMenu {
  final String id;
  final DateTime date;
  final List<String> breakfast;
  final List<String> lunch;
  final List<String> dinner;
  final List<String> snacks;

  MessMenu({
    required this.id,
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.snacks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'snacks': snacks,
    };
  }

  factory MessMenu.fromMap(Map<String, dynamic> map, String id) {
    return MessMenu(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      breakfast: List<String>.from(map['breakfast'] ?? []),
      lunch: List<String>.from(map['lunch'] ?? []),
      dinner: List<String>.from(map['dinner'] ?? []),
      snacks: List<String>.from(map['snacks'] ?? []),
    );
  }
}

class MessFeedback {
  final String id;
  final String studentId;
  final String studentName; // Denormalized for easier display
  final DateTime date;
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner'
  final int rating; // 1-5
  final String? comment;

  MessFeedback({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.mealType,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'date': Timestamp.fromDate(date),
      'mealType': mealType,
      'rating': rating,
      'comment': comment,
    };
  }

  factory MessFeedback.fromMap(Map<String, dynamic> map, String id) {
    return MessFeedback(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? 'Anonymous',
      date: (map['date'] as Timestamp).toDate(),
      mealType: map['mealType'] ?? 'Lunch',
      rating: map['rating'] ?? 0,
      comment: map['comment'],
    );
  }
}
