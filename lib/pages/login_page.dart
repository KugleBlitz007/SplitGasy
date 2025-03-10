import 'package:flutter/material.dart';
import 'package:splitgasy/components/custom_button.dart';
import 'package:splitgasy/components/custom_text_field.dart';
import 'package:splitgasy/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // Fields controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Auth service instance
  final AuthService _authService = AuthService();

  // Sign in function
  void signIn() async {
    try {
      await _authService.signInWithEmailPassword(
        emailController.text,
        passwordController.text);
      print('Success');
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 175),

              // Welcome message
              Text(
                'Welcome to SplitGasy!',
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
                hintText: 'email',
                obscureText: false,
              ),

              const SizedBox(height: 20),

              // password value
              CustomTextField(
                controller: passwordController,
                hintText: 'password',
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

              // sign in button
              CustomButton(
                onTap: signIn,
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

              const SizedBox(height: 250),

              // Register
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Don\'t have an account yet? '),
                    TextSpan(
                      text: 'Register here',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              )

          
          ],),
        ),
      ),
    );
  }
}