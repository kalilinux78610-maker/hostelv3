import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var snapshot = await FirebaseFirestore.instance
      .collection('leave_requests')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .get();
  for (var doc in snapshot.docs) {
    debugPrint('LATEST REQ: ${doc.data()}');
  }
}
