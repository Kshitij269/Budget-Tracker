import 'package:budget_tracker/Screens/dashboard.dart';
import 'package:budget_tracker/Screens/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return LoginForm();
            } else {
              return ExpenseTracker(user: user!);
            }
          } else {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        });
  }
}
