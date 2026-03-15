import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// One-time utility to fix user role in Firestore.
/// Run this once, then delete this file.
class FixRoleUtil {
  /// Updates the role for a user with the given email to 'student'
  static Future<void> fixRole({
    required String email,
    required String newRole,
  }) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .update({'role': newRole});
        debugPrint('✅ Role updated to "$newRole" for $email (doc: $docId)');
      } else {
        debugPrint('❌ No user found with email: $email');
      }
    } catch (e) {
      debugPrint('❌ Error fixing role: $e');
    }
  }
}
