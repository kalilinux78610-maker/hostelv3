import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/canonical_names.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    debugPrint("GoogleSignIn init failed: $e");
  }


  // Set auth persistence to NONE so users must log in every time
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.NONE);
  } else {
    // Optionally set for mobile as well if needed
    // await FirebaseAuth.instance.setPersistence(Persistence.NONE);
  }

  // Push notifications (may fail on web, so wrap in try-catch)
  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint("Push notification init failed: $e");
  }

  // TODO: TEMPORARY DATA MIGRATION - REMOVE AFTER ONE RUN
  _migrateData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hostel V3',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF800000)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

Future<void> _migrateData() async {
  try {
    debugPrint("Starting data migration...");
    final snapshot = await FirebaseFirestore.instance
        .collection('leave_requests')
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final branch = data['branch'];
      final category = data['category'];
      
      final cBranch = CanonicalNames.canonicalizeBranch(branch, category);
      final cCategory = CanonicalNames.canonicalizeCategory(category);
      
      if (branch != cBranch || category != cCategory) {
        await doc.reference.update({
          'branch': cBranch,
          'category': cCategory,
        });
        debugPrint("Migrated request ${doc.id}: $branch -> $cBranch");
      }
    }
    debugPrint("Data migration finished.");
  } catch (e) {
    debugPrint("Migration error: $e");
  }
}
