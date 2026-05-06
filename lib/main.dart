import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'package:upgrader/upgrader.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Load .env for Push Notifications
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or could not be loaded. Push notifications will fail.");
  }

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


  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SVPES eGate Pass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF800000)),
        useMaterial3: true,
      ),
      home: UpgradeAlert(
        upgrader: Upgrader(
          durationUntilAlertAgain: const Duration(minutes: 5),
        ),
        showIgnore: false,
        showLater: false,
        barrierDismissible: false,
        child: const AuthGate(),
      ),
    );
  }
}


