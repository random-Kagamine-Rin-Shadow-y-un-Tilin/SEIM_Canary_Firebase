import 'package:flutter/material.dart';
import 'package:seim_canary/screens/Users/register.dart';
import 'package:seim_canary/screens/home_page.dart';
import 'package:seim_canary/services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Variable para mostrar el indicador de carga
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor, ingrese email y contraseña');
      return;
    }

    setState(() => _isLoading = true); // Mostrar el indicador de carga

    try {
      // Intentar iniciar sesión usando el método loginUser de FirebaseService
      final userModel = await FirebaseService().loginUser(email, password);

      if (userModel != null) {
        // Si las credenciales son correctas, navegar a HomePage
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomePage(user: userModel),
            ),
          );
        }
      } else {
        // Si las credenciales son incorrectas, mostrar un mensaje
        _showSnackBar('Email o contraseña incorrectos');
      }
    } catch (e) {
      // Manejar errores durante el inicio de sesión
      _showSnackBar('Error al iniciar sesión: $e');
    } finally {
      // Ocultar el indicador de carga
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método para mostrar un SnackBar con mensajes
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 30),
              onPressed: () {
                // Navegar a la pantalla de registro
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RegisterUserScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Campo de texto para el email
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16.0),
            // Campo de texto para la contraseña
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: _passwordController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      })),
            ),
            const SizedBox(height: 16.0),
            // Botón de inicio de sesión o indicador de carga
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(204, 56, 1, 129),
                    ),
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
