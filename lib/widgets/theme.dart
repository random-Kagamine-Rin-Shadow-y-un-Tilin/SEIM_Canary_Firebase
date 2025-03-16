import 'package:flutter/material.dart';

ThemeData themeMain() {
  return ThemeData(
    //Color principales de la app
    scaffoldBackgroundColor: const Color.fromARGB(255, 47, 68, 80),
    primaryColor: const Color.fromARGB(255, 255, 255, 255),

    //Barra de la app / menu
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 47, 68, 80),
      titleTextStyle: TextStyle(
        color: Color.fromARGB(255, 255, 255, 255),
        fontSize: 20,
      ),
      iconTheme: IconThemeData(
        color: Color.fromARGB(255, 255, 255, 255),
      ),
      elevation: 0,
    ),

    // Texto de la app
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: Color.fromARGB(255, 255, 255, 255),
        fontSize: 20,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    ),

    // Estilo para TextField
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromARGB(255, 49, 49, 49),
      hintStyle: TextStyle(color: const Color.fromARGB(255, 158, 151, 151)),
      labelStyle: const TextStyle(color: Colors.white),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
            color: Color.fromARGB(255, 126, 126, 126), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide:
            const BorderSide(color: Color.fromARGB(255, 68, 26, 255), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),

    // Estilo para botones
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 75, 75, 75),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
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
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        textStyle: const TextStyle(fontSize: 16),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2F4450), // Color de fondo del menú
      selectedItemColor: Color.fromARGB(255, 71, 0, 119), // Color del ícono seleccionado
      unselectedItemColor: Colors.grey, // Color de los íconos no seleccionados
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
  );
}
