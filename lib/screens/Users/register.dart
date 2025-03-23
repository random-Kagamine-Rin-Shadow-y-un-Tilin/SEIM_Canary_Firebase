import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seim_canary/models/user_model.dart';
import 'package:seim_canary/services/auth_service.dart';
import 'package:seim_canary/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to validate email
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  // Function to check if email already exists
  Future<bool> _checkEmailExists(String email) async {
    try {
      final user = await FirebaseService().loginUser(email, '');
      return user != null;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Function to register user with email and password
  Future<void> _insertUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String username = _usernameController.text.trim();
      String email = _emailController.text.trim();
      String phone = _phoneController.text.trim();
      String password = UserModel.hashPassword(
          _passwordController.text.trim()); // Encrypt the password

      // Check if email already exists
      bool emailExists = await _checkEmailExists(email);
      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("El correo ya está registrado")),
        );
        return;
      }

      // Create the UserModel
      var user = UserModel(
        id: Uuid().v4(),
        username: username,
        email: email,
        phone: phone,
        password: password,
      );

      // Insert the user into the database
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
        setState(() => _isLoading = false);
      }
    }
  }

  // Function to register user with Google
Future<void> _registerWithGoogle() async {
  setState(() => _isLoading = true);

  try {
    print('Attempting Google Sign-In...');
    final userModel = await AuthService().signInWithGoogle();
    if (userModel != null) {
      print('Google Sign-In successful: ${userModel.email}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado con Google')),
      );
      Navigator.of(context).pop(); // Go back to the previous screen
    } else {
      print('Google Sign-In failed: UserModel is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar con Google')),
      );
    }
  } catch (e) {
    print('Error during Google Sign-In: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
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
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _insertUser,
                          child: const Text('Registrar'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _registerWithGoogle,
                          icon: const Icon(Icons.login),
                          label: const Text('Registrar con Google'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}