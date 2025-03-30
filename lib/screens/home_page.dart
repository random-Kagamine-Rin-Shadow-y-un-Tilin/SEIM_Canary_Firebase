import 'package:flutter/material.dart';
import 'package:seim_canary/models/user_model.dart';
import 'package:seim_canary/screens/Devices/register_device.dart';
import 'package:seim_canary/screens/Devices/toggle_device.dart';
import 'package:seim_canary/screens/Users/edit_user.dart';
// import 'package:seim_canary/screens/home.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;
  late UserModel _user; // Variable de estado para el usuario

  @override
  void initState() {
    super.initState();
    _user = widget.user; // Inicializa la variable de estado con el usuario proporcionado
    _setupScreens();
  }

  void _setupScreens() {
    setState(() {
      _widgetOptions = [
        ToggleDeviceScreen(),
        RegisterDeviceScreen(),
        EditUserScreen(
          user: _user, // Usa la variable de estado
          onUserUpdated: _onUserUpdated,
        ),
      ];
    });
  }

  void _onUserUpdated(UserModel updatedUser) {
    setState(() {
      _user = updatedUser; // Actualiza la variable de estado
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEIM'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuraciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}