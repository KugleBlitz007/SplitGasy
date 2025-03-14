import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:splitgasy/pages/auth_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load();  // Load .env
    print("Environment file loaded successfully");
    print("ANDROID_API_KEY: ${dotenv.env['ANDROID_API_KEY']}"); // Log to verify value
  } catch (e) {
    print("Error loading .env: $e");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}