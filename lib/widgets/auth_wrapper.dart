import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// AuthWrapper widget that checks Firebase Auth state and navigates accordingly
/// This ensures users stay logged in across app restarts
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // If user is not logged in, show LoginScreen
        return const LoginScreen();
      },
    );
  }
}

