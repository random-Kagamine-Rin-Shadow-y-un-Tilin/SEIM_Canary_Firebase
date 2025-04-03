import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seim_canary/screens/Users/login.dart';
import 'package:seim_canary/widgets/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeMain(),
      title: 'SEIM',
      home: const LoginScreen(),
    );
  }
} //92242593