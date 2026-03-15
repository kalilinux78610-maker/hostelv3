import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'fix_role.dart'; // TODO: Remove after one-time fix

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ONE-TIME FIX: Change sem@gmail.com role from admin to student
  // TODO: Remove this block after running once
  await FixRoleUtil.fixRole(email: 'sem@gmail.com', newRole: 'student');

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
