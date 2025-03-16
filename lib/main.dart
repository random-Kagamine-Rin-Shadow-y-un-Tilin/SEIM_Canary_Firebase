import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seim_canary/screens/Users/login.dart';
import 'package:seim_canary/screens/home.dart';
import 'package:seim_canary/screens/home_page.dart';
import 'package:seim_canary/screens/Users/register.dart';
import 'package:seim_canary/widgets/theme.dart';
import 'package:seim_canary/models/user_model.dart';

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
      home: const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/home_page':
            final user = settings.arguments as UserModel; // Obtén el user de los argumentos
            return MaterialPageRoute(builder: (context) => HomePage(user: user));
          case '/register':
            return MaterialPageRoute(builder: (context) => const RegisterUserScreen());
          default:
            return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
      },
    );
  }
}