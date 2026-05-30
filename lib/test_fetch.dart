import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('--- FETCHING ALL PENDING LEAVE REQUESTS ---');
  var snapshot = await FirebaseFirestore.instance
      .collection('leave_requests')
      .where('status', isEqualTo: 'pending')
      .get();
  
  debugPrint('Total pending requests in Firestore: ${snapshot.docs.length}');
  for (var doc in snapshot.docs) {
    final data = doc.data();
    debugPrint('REQ ID: ${doc.id}');
    debugPrint('  Name: ${data['name']}');
    debugPrint('  Category: ${data['category']}');
    debugPrint('  Branch: ${data['branch']}');
    debugPrint('  Hostel ID: ${data['hostelId']}');
    debugPrint('  Status: ${data['status']}');
    debugPrint('  HOD Status: ${data['hodStatus']}');
    debugPrint('  Warden Status: ${data['wardenStatus']}');
    debugPrint('  Rector Status: ${data['rectorStatus']}');
    debugPrint('  Created At: ${data['createdAt']}');
    debugPrint('-----------------------------------------');
  }
}
