import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mess_model.dart';

class MessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Menu Operations ---

  // Add or Update Menu for a specific date
  Future<void> setMenu(MessMenu menu) async {
    // We use the date string YYYY-MM-DD as ID to ensure one menu per day
    String dateId = _dateToId(menu.date);
    await _firestore.collection('mess_menu').doc(dateId).set(menu.toMap());
  }

  // Get Menu for a specific date
  Stream<MessMenu?> getMenuForDate(DateTime date) {
    String dateId = _dateToId(date);
    return _firestore.collection('mess_menu').doc(dateId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return MessMenu.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // --- Feedback Operations ---

  // Submit Feedback
  Future<void> submitFeedback(MessFeedback feedback) async {
    await _firestore.collection('mess_feedback').add(feedback.toMap());
  }

  // Get Analytics (Last 7 days avg rating)
  Stream<List<MessFeedback>> getRecentFeedback() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _firestore
        .collection('mess_feedback')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MessFeedback.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Helper
  String _dateToId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
