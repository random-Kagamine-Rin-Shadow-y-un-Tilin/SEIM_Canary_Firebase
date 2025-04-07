import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:seim_canary/screens/Users/login.dart';
import 'package:seim_canary/widgets/theme.dart';
import 'package:seim_canary/widgets/theme_white.dart';
import 'widgets/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChangeNotifierProvider(
      create: (_) => ThemeProvider(), child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      theme: themeMain() ,
      darkTheme: themeMainWhite(),
      title: 'SEIM',
      home: const LoginScreen(),
    );
  }
}
