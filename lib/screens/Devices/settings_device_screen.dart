import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class SettingsDeviceScreen extends StatefulWidget {
  final String deviceId;
  final Map<dynamic, dynamic> deviceData;

  const SettingsDeviceScreen({
    super.key,
    required this.deviceId,
    required this.deviceData,
  });

  @override
  State<SettingsDeviceScreen> createState() => _SettingsDeviceScreenState();
}

class _SettingsDeviceScreenState extends State<SettingsDeviceScreen> {
  late final DatabaseReference _deviceRef;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _deviceRef = FirebaseDatabase.instance.ref('enchufe/${widget.deviceId}');
    _nameController.text = widget.deviceData['nombre'] ?? 'Dispositivo sin nombre';
    _typeController.text = widget.deviceData['categoria']?['tipo'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _updateDeviceName() async {
    if (_nameController.text.trim().isNotEmpty) {
      await _deviceRef.update({'nombre': _nameController.text.trim()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado')),
      );
    }
  }

  Future<void> _updateDeviceType() async {
    if (_typeController.text.trim().isNotEmpty) {
      await _deviceRef.child('categoria/tipo').set(_typeController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo actualizado')),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool esEncender) async {
    final horario = widget.deviceData['horario'] ?? {};
    final horaActual = esEncender ? horario['encender'] : horario['apagar'];

    TimeOfDay initialTime = horaActual != null
        ? TimeOfDay(
            hour: int.parse(horaActual.split(':')[0]),
            minute: int.parse(horaActual.split(':')[1]),
          )
        : TimeOfDay.now();

    TimeOfDay? nuevaHora = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (nuevaHora != null) {
      String horaFinal =
          "${nuevaHora.hour.toString().padLeft(2, '0')}:${nuevaHora.minute.toString().padLeft(2, '0')}";

      await _deviceRef.child('horario').update(
            esEncender ? {"encender": horaFinal} : {"apagar": horaFinal},
          );
    }
  }

  Future<void> _deleteDevice() async {
    await _deviceRef.remove();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final horario = widget.deviceData['horario'] ?? {};
    final encenderHora = horario['encender'] ?? '--:--';
    final apagarHora = horario['apagar'] ?? '--:--';
    final deviceState = widget.deviceData['estado'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Dispositivo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar Dispositivo'),
                  content: const Text('¿Estás seguro de que quieres eliminar este dispositivo?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: _deleteDevice,
                      child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del dispositivo',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _updateDeviceName,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: 'Tipo de dispositivo',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _updateDeviceType,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text('Hora de encendido: $encenderHora'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _selectTime(context, true),
              ),
            ),
            ListTile(
              title: Text('Hora de apagado: $apagarHora'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _selectTime(context, false),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Estado del dispositivo'),
              value: deviceState,
              onChanged: (value) => _deviceRef.update({'estado': value}),
            ),
          ],
        ),
      ),
    );
  }
}