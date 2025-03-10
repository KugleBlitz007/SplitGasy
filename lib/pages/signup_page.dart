import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitgasy/components/custom_button.dart';
import 'package:splitgasy/components/custom_text_field.dart';
import 'package:splitgasy/services/auth_service.dart';

import 'home_page.dart';

class SignupPage extends StatefulWidget {
  final Function()? onTap;
  const SignupPage({super.key, required this.onTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Fields controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  
  // Loading state variable
  bool isLoading = false;

  // Auth service instance
  final AuthService _authService = AuthService();

  // Sign up function
  void signUp() async {
    // Set to loading
    setState(() {
      isLoading = true;
    });

    try {
      // Check if password and confirm password match
      if (passwordController.text != confirmPasswordController.text) {
        // Stop loading
        if (context.mounted) {
          setState(() {
            isLoading = false;
          });
        }

        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Passwords don\'t match')),
          );
        }

        return;
      }

      // Register the user
      await _authService.registerWithEmailPassword(
        emailController.text,
        passwordController.text,
        nameController.text,
      );

      // Ensure the user's display name is updated
      await FirebaseAuth.instance.currentUser?.reload();

      // Stop loading
      if (context.mounted) {
        setState(() {
          isLoading = false;
        });
      }

      // Navigate to HomePage
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }

    } catch (e) {
      // Stop loading
      if (context.mounted) {
        setState(() {
          isLoading = false;
        });
      }

      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing up')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 175),
          
                // Welcome message
                Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 30,
                    fontWeight: FontWeight.w800
                  ),
                ),
          
                const SizedBox(height: 50),
          
                // name field
                CustomTextField(
                  controller: nameController,
                  hintText: 'Name',
                  obscureText: false,
                ),

                const SizedBox(height: 20),
                
                // email field
                CustomTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
          
                const SizedBox(height: 20),
          
                // password field
                CustomTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),

                const SizedBox(height: 20),

                // configm password field
                CustomTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm password',
                  obscureText: true,
                ),
          
                const SizedBox(height: 20),
          
                // sign up button
                isLoading
                    ? const CircularProgressIndicator() // Show loading circle
                    : CustomButton(
                        onTap: signUp,
                        text: 'Sign Up',
                      ),
          
                const SizedBox(height: 50),
          
                // Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? "),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        "Sign in here",
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
          
            
            ],),
          ),
        ),
      ),
    );
  }
}