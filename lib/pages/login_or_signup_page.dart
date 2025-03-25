import 'package:flutter/material.dart';
import 'package:splizzy/pages/login_page.dart';

import 'signup_page.dart';

class LoginOrSignupPage extends StatefulWidget {
  const LoginOrSignupPage({super.key});

  @override
  State<LoginOrSignupPage> createState() => _LoginOrSignupPageState();
}

class _LoginOrSignupPageState extends State<LoginOrSignupPage> {
  // show login page initially
  bool showLoginPage = true;

  // toggle between login and signup pages
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: showLoginPage
          ? LoginPage(key: const ValueKey('login'), onTap: togglePages)
          : SignupPage(key: const ValueKey('signup'), onTap: togglePages),
    );
  }
}