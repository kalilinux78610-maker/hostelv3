import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'role_checker.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while auth state is being determined
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Guard 1: Is the user even logged in?
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen(); // Show login if no user found
        }

        // Guard 2: User is logged in, now check their specific role
        return RoleChecker(uid: snapshot.data!.uid);
      },
    );
  }
}
