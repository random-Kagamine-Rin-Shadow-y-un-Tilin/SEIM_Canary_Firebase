import 'package:flutter/material.dart';
import 'package:seim_canary/models/user_model.dart';
import 'package:seim_canary/screens/Users/login.dart'; // Importa LoginScreen
import 'package:seim_canary/screens/Users/password.dart';
import 'package:seim_canary/services/firestore_service.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated; // Callback para actualizar el estado

  const EditUserScreen({
    super.key,
    required this.user,
    required this.onUserUpdated, // Recibe el callback
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone.toString());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateUser() async {
    // Encripta la contraseña antes de actualizar el usuario

    var updatedUser = UserModel(
      id: widget.user.id,
      username: _usernameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: widget.user.password,
    );

    try {
      await FirebaseService().updateUser(updatedUser.id, {
        'username': updatedUser.username,
        'email': updatedUser.email,
        'phone': updatedUser.phone,
        'password': updatedUser.password,
      });
      if (!mounted) return;

      // Llama al callback para actualizar el estado en la pantalla anterior
      widget.onUserUpdated(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario actualizado con éxito")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar el usuario: $e")),
      );
    }
  }

  void _logout() {
    // Redirige a LoginScreen y reemplaza la pantalla actual
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToChangePassword() {
    // Navega a ChangePasswordScreen y pasa el ID del usuario actual
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          userId: widget.user.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Botón de logout
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(
              height: 16,
            ),
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico'),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUser,
              child: const Text('Guardar Cambios'),
            ),
            const SizedBox(
              height: 16,
            ),
            TextButton(
              onPressed: _navigateToChangePassword,
              child: const Text('Cambiar Contraseña'),
            )
          ],
        ),
      ),
    );
  }
}
