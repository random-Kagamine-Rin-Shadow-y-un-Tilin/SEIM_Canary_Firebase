import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ToggleDeviceScreen extends StatefulWidget {
  const ToggleDeviceScreen({super.key});

  @override
  State<ToggleDeviceScreen> createState() => _ToggleDeviceScreenState();
}

class _ToggleDeviceScreenState extends State<ToggleDeviceScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('enchufe/estado');

  // Function to toggle the value in the Realtime Database
  Future<void> _toggleValue(bool currentValue) async {
    try {
      await _databaseRef.set(!currentValue); // Toggle the value
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controlar Enchufe'),
      ),
      body: Center(
        child: StreamBuilder<DatabaseEvent>(
          stream: _databaseRef.onValue, // Listen to changes in the database
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return const Text('Error al cargar los datos');
            }

            // Get the current value from the database
            final bool currentValue = snapshot.data?.snapshot.value as bool? ?? false;

            return ElevatedButton(
              onPressed: () => _toggleValue(currentValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentValue ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: Text(
                currentValue ? 'ENCENDIDO' : 'APAGADO',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}