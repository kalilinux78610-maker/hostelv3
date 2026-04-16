import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Centralized auth helper.
///
/// Always call [signOut] from here instead of `FirebaseAuth.instance.signOut()`
/// directly so the FCM token is cleaned up. This prevents the device from
/// receiving push notifications meant for the previous user after they log out.
class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Signs the current user out and removes their FCM token from Firestore.
  static Future<void> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        // Delete the FCM token so this device no longer receives pushes
        // for the logged-out user's role.
        await _firestore
            .collection('users')
            .doc(uid)
            .update({'fcmToken': FieldValue.delete()});
      }
    } catch (e) {
      debugPrint('AuthService: failed to clear FCM token — $e');
    } finally {
      await _auth.signOut();
    }
  }
}
