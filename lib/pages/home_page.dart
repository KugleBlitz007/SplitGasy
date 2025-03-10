import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitgasy/components/custom_button.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final user = FirebaseAuth.instance.currentUser!;

  // sign out function
  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Welcome! Signed in as ${user.email}",
                style: TextStyle(
                  fontSize: 20,
                ),
                ),
              SizedBox(height: 20),
              CustomButton(
                onTap: signOut,
                text: 'Sign Out',
                ),
            ],
          ),
        ),
      ),
    );
  }
}