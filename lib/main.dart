import 'package:flutter/material.dart'; // Importa el paquete de Material Design de Flutter.
import 'package:firebase_core/firebase_core.dart'; // Importa el paquete para inicializar Firebase.
import 'package:provider/provider.dart'; // Importa el paquete Provider para gestión de estado.
import 'package:seim_canary/screens/Users/login.dart'; // Importa la pantalla de Login.
import 'package:seim_canary/widgets/theme.dart'; // Importa el tema principal de la app.
import 'package:seim_canary/widgets/theme_white.dart'; // Importa el tema para el modo oscuro (tema blanco).
import 'widgets/theme_provider.dart'; // Importa el proveedor de tema.

void main() async {
  // Asegura que el widget de Flutter esté completamente inicializado antes de ejecutar la app.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase antes de que la app comience.
  await Firebase.initializeApp();

  // Ejecuta la aplicación envuelta en el ChangeNotifierProvider para gestionar el tema de la app.
  runApp(ChangeNotifierProvider(
      create: (_) => ThemeProvider(), // Crea el proveedor de tema.
      child: const MainApp())); // Pasa el widget principal a la app.
}

// Clase principal de la aplicación, que es un widget sin estado (StatelessWidget).
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Desactiva el banner de modo debug en la app.
      themeMode: Provider.of<ThemeProvider>(context).themeMode, // Determina el modo de tema (oscuro o claro) usando el ThemeProvider.
      theme: themeMain(), // Define el tema claro de la app.
      darkTheme: themeMainWhite(), // Define el tema oscuro de la app.
      title: 'SEIM', // Título de la app que aparece en la barra de tareas.
      home: const LoginScreen(), // Pantalla de inicio de la aplicación (pantalla de login).
    );
  }
}
