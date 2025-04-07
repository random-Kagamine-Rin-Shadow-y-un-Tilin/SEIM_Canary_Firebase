import 'package:flutter/material.dart';
import 'package:seim_canary/models/user_model.dart';
import 'package:seim_canary/screens/Users/login.dart';
import 'package:seim_canary/screens/Users/password.dart';
import 'package:seim_canary/services/firestore_service.dart';
import 'package:seim_canary/widgets/theme_provider.dart';
import 'package:provider/provider.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;

  const EditUserScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToChangePassword() {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isWhite = themeProvider.isWhiteTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuario'),
        actions: [
          IconButton(
            icon: Icon(isWhite ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Cambiar tema',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUser,
              child: const Text('Guardar Cambios'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _navigateToChangePassword,
              child: const Text('Cambiar Contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
