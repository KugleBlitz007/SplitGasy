import 'package:flutter/material.dart';
import 'package:splitgasy/components/custom_button.dart';
import 'package:splitgasy/components/custom_text_field.dart';
import 'package:splitgasy/services/auth_service.dart';

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

  // Auth service instance
  final AuthService _authService = AuthService();

  // Sign up function
  void signUp() async {
    try {
      // check if password and confirm matches
      if (passwordController.text == confirmPasswordController.text) {
        await _authService.registerWithEmailPassword(
        emailController.text,
        passwordController.text);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords don\'t match'))
        );
      }
      
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in: wrong email and/or password'))
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
                CustomButton(
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