import 'package:flutter/material.dart';
import 'package:seim_canary/models/enchufe_model.dart';
import 'package:uuid/uuid.dart';

class RegisterDeviceScreen extends StatefulWidget {
  final Function(EnchufeModel) onDeviceAdded;

  const RegisterDeviceScreen({super.key, required this.onDeviceAdded});

  @override
  State<RegisterDeviceScreen> createState() => _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends State<RegisterDeviceScreen> {
  final TextEditingController _nombreController = TextEditingController();

  // Categorías y tipos basados en los datos de la imagen
  final Map<String, List<String>> _categories = {
    'Tostadoras': ['800w', '1200w', '1500w', '1800w'],
    'Bombillas': ['LED', 'Halógena', 'Fluorescente', 'Incandescente'],
    'Cafeteras': ['Italiana', 'Expreso Manual', 'Goteo'],
    'Ventiladores': ['Mesa', 'Pared', 'Torre', 'Pie'],
  };

  String? _selectedCategory;
  String? _selectedType;

  void _saveDevice() {
    if (_nombreController.text.isEmpty || _selectedCategory == null || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    final nuevoDispositivo = EnchufeModel(
      id: const Uuid().v4(),
      nombre: _nombreController.text,
      usuario: '',
      estado: false,
      dispositivo: _selectedCategory!,
      tipo: _selectedType!,
      tiempo: {},
      horario: Horario(encender: '--:--', apagar: '--:--'),
    );

    widget.onDeviceAdded(nuevoDispositivo);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Dispositivo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Campo de nombre del dispositivo
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Dispositivo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown para categorías
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: _categories.keys.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _selectedType = null; // Reset tipo cuando cambia la categoría
                });
              },
            ),
            const SizedBox(height: 16),

            // Dropdown para tipos
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: _selectedCategory != null
                  ? _categories[_selectedCategory!]!.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList()
                  : null,
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 32),

            // Botón de guardar
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveDevice,
                icon: const Icon(Icons.save),
                label: const Text('Registrar Dispositivo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
