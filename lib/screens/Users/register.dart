import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seim_canary/models/user_model.dart';
import 'package:seim_canary/services/firestore_service.dart';
import 'package:uuid/uuid.dart'; // Add this import for generating unique IDs

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Variable para mostrar el indicador de carga

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para validar email
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  // Función para verificar si el correo ya está registrado
  Future<bool> _checkEmailExists(String email) async {
    try {
      final user = await FirebaseService().loginUser(email, '');
      return user != null;
    } catch (e) {
      print('Error al verificar el correo: $e');
      return false;
    }
  }

  // Función para registrar usuario
  Future<void> _insertUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true); // Mostrar el indicador de carga

    try {
      String username = _usernameController.text.trim();
      String email = _emailController.text.trim();
      String phone = _phoneController.text.trim();
      String password = UserModel.hashPassword(
          _passwordController.text.trim()); // Encriptar la contraseña

      // Verificar si el correo ya está registrado
      bool emailExists = await _checkEmailExists(email);
      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("El correo ya está registrado")),
        );
        return;
      }

      // Crear el objeto UserModel
      var user = UserModel(
        id: Uuid().v4(), // Generate a unique ID
        username: username,
        email: email,
        phone: phone,
        password: password, // Contraseña encriptada
      );

      // Insertar el usuario en la base de datos
      await FirebaseService().addUser(user);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario registrado con éxito")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar el usuario: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Ocultar el indicador de carga
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                controller: _usernameController,
                decoration:
                    const InputDecoration(labelText: 'Nombre de Usuario'),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                controller: _emailController,
                decoration:
                    const InputDecoration(labelText: 'Correo Electrónico'),
                validator: (value) => value!.isEmpty
                    ? "Campo requerido"
                    : (_isValidEmail(value) ? null : "Email inválido"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingrese un número de teléfono";
                  } else if (value.length < 10) {
                    return "El número debe tener 10 dígitos";
                  }
                  return null;
                },
              ),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? "Mínimo 6 caracteres" : null,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _insertUser,
                      child: const Text('Registrar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
