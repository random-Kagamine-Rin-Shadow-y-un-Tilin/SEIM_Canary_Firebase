import 'package:flutter/material.dart';

ThemeData themeMainWhite() {
  return ThemeData(
    // Color principal claro
    brightness: Brightness.light,
    primaryColor: const Color.fromARGB(255, 0, 0, 0),

    // AppBar con texto oscuro
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(
        color: Colors.black,
      ),
      elevation: 0,
    ),

    // Texto en general oscuro
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: Colors.black,
        fontSize: 20,
      ),
      bodyMedium: TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
    ),

    // Estilo para TextField
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      hintStyle: const TextStyle(color: Color(0xFF7A7A7A)),
      labelStyle: const TextStyle(color: Colors.black),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),

    // Botones claros
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: Colors.black,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 16),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
  );
}
