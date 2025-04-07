import 'package:flutter/material.dart';
import 'package:seim_canary/models/enchufe_model.dart';

class SettingsDeviceScreen extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic> deviceData;
  final Function(Map<String, dynamic>) onSave;

  const SettingsDeviceScreen({
    super.key,
    required this.deviceId,
    required this.deviceData,
    required this.onSave,
  });

  @override
  State<SettingsDeviceScreen> createState() => _SettingsDeviceScreenState();
}

class _SettingsDeviceScreenState extends State<SettingsDeviceScreen> {
  late String? _selectedCategory;
  late String? _selectedType;
  bool _isUpdating = false;

  late Horario _horario;
  TimeOfDay? _turnOnTime;
  TimeOfDay? _turnOffTime;

  final Map<String, List<String>> _deviceCategories = {
    'Tostadoras': ['800w', '1200w', '1500w', '1800w'],
    'Bombillas': ['Fluorescente', 'Halogena', 'LED', 'Incandescente'],
    'Cafeteras': ['Italiana', 'ExpresoManual', 'Goteo'],
    'Ventiladores': ['Mesa', 'Pared', 'Torre', 'Pie'],
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.deviceData['tipo'];
    _selectedCategory = _getCategoryFromType(_selectedType);

    final horarioData = Map<String, String>.from(widget.deviceData['horario'] ?? {});
    _horario = Horario(
      encender: horarioData['encender'] ?? '--:--',
      apagar: horarioData['apagar'] ?? '--:--',
    );

    if (_horario.encender != '--:--') {
      final parts = _horario.encender.split(':');
      _turnOnTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (_horario.apagar != '--:--') {
      final parts = _horario.apagar.split(':');
      _turnOffTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  String? _getCategoryFromType(String? type) {
    if (type == null) return null;
    for (final category in _deviceCategories.keys) {
      if (_deviceCategories[category]!.contains(type)) {
        return category;
      }
    }
    return null;
  }

  Future<void> _selectTime(BuildContext context, bool isTurnOn) async {
    final initialTime = isTurnOn ? _turnOnTime ?? TimeOfDay.now() : _turnOffTime ?? TimeOfDay.now();
    final TimeOfDay? newTime = await showTimePicker(context: context, initialTime: initialTime);

    if (newTime != null) {
      setState(() {
        if (isTurnOn) {
          _turnOnTime = newTime;
          _horario = Horario(
            encender: _formatTime(newTime),
            apagar: _horario.apagar,
          );
        } else {
          _turnOffTime = newTime;
          _horario = Horario(
            encender: _horario.encender,
            apagar: _formatTime(newTime),
          );
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _saveChanges() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un tipo válido')),
      );
      return;
    }

        setState(() => _isUpdating = true);

    try {
      final updateData = {
        'tipo': _selectedType,
        'horario': _horario.toJson(),
      };

      await widget.onSave(updateData);
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Dispositivo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Selector de categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: _deviceCategories.keys.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _selectedType = null;
                });
              },
            ),

            const SizedBox(height: 16),

            // Selector de tipo
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Dispositivo',
                border: OutlineInputBorder(),
              ),
              items: _selectedCategory != null
                  ? _deviceCategories[_selectedCategory]!.map((type) {
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

            const SizedBox(height: 24),

            // Configuración de horario
            ListTile(
              title: Text('Hora de encendido: ${_turnOnTime != null ? _formatTime(_turnOnTime!) : '--:--'}'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _selectTime(context, true),
              ),
            ),
            ListTile(
              title: Text('Hora de apagado: ${_turnOffTime != null ? _formatTime(_turnOffTime!) : '--:--'}'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _selectTime(context, false),
              ),
            ),

            const SizedBox(height: 32),

            // Botón de guardar
            ElevatedButton(
              onPressed: _isUpdating ? null : _saveChanges,
              child: _isUpdating
                  ? const CircularProgressIndicator()
                  : const Text('GUARDAR CAMBIOS'),
            ),
          ],
        ),
      ),
    );
  }
}
