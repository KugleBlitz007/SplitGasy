import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitgasy/components/custom_button.dart';
import 'package:splitgasy/components/custom_text_field.dart';
import 'package:splitgasy/services/auth_service.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Fields controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Loading state variable
  bool isLoading = false;

  // Auth service instance
  final AuthService _authService = AuthService();

  // Sign in function
  void signIn() async {
    // Set to loading
    setState(() {
      isLoading = true;
    });
    
    // Try signing the user in
    try {
      await _authService.signInWithEmailPassword(
        emailController.text,
        passwordController.text);
    
      // Ensure all data is loaded
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in: wrong email and/or password'))
        );
      }
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
                const SizedBox(height: 100),

                // App Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'lib/assets/icon/play_store_512.png',
                    height: 100,
                    width: 100,
                  ),
                ),

                const SizedBox(height: 25),
          
                // Welcome message
                Text(
                  'Welcome to Splizzy!',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 25,
                    fontWeight: FontWeight.w800
                  ),
                ),
          
                const SizedBox(height: 50),
          
                // email field
                CustomTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
          
                const SizedBox(height: 20),
          
                // password value
                CustomTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
          
                const SizedBox(height: 20),
            
                // forgot password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.grey[800],
                          decoration: TextDecoration.underline),  
                      ),
                    ],
                  ),
                ),
          
                const SizedBox(height: 20),
          
                // Sign in button
                isLoading
                    ? const CircularProgressIndicator() // Show loading circle
                    : CustomButton(
                        onTap: signIn,
                        text: 'Sign In',
                      ),
          
                const SizedBox(height: 50),
          
                // or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                  
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                  
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // google button
          
                const SizedBox(height: 50),
          
                // Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account yet? "),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        "Register here",
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